import gcsfs
import os
import logging
import random
import torch
import torch.nn as nn
import pandas as pd
import numpy as np
import json
import gc
import matplotlib.pyplot as plt

from torch.utils.data import TensorDataset, DataLoader, SequentialSampler
from pytorch_pretrained_bert.modeling import BertForNextSentencePrediction
from pytorch_pretrained_bert.tokenization import BertTokenizer
from fastprogress import master_bar, progress_bar
from sklearn.model_selection import StratifiedShuffleSplit

class Suggester_BertTopicSimiliarty():
    def __init__(
        self
        , question_file
        , answer_file
        , sample_n
        , random_state
        , bert_cache
        , logger
        , device
        , max_seq_length
        , batch_size
    ):
        # initializes some vars
        self.question_file = question_file
        self.answer_file = answer_file
        self.sample_n = sample_n
        self.random_state = random_state
        self.bert_cache = bert_cache
        self.logger = logger
        self.device = device
        self.max_seq_length = max_seq_length
        self.batch_size = batch_size
        
        # gets the pre-trained tokenizer
        self.tokenizer = BertTokenizer.from_pretrained(
            "bert-base-uncased"
            , do_lower_case = True
            , cache_dir = self.bert_cache
        )
        
        # gets the pre-trained model
        self.model = BertForNextSentencePrediction.from_pretrained(
            "bert-base-uncased"
            , cache_dir = self.bert_cache
        ).to(self.device)
        
        # instantiates the helper class
        self.ceshiner = Ceshiner()
    
    def _construct_corpus(self, questions, answers):
        '''
        helper function that constructs corpus
        with question id, title, accepted answer id, answer body
        note, implicitly only questions with accepted answers will end up in corpus
        '''
        t1 = questions
        t1 = t1[t1["accepted_answer_id"]  != ""]
        t1 = t1[t1.accepted_answer_id.notnull()]
        t1["accepted_answer_id"] = t1["accepted_answer_id"].astype(float).astype(int)
        t1 = t1[[
            "id"
            , "title"
            , "tags"
            , "accepted_answer_id"
        ]].rename(columns = {
            "id" : "q_id"
            , "title" : "q_title"
        })
        t2 = answers[[
            "id"
            , "body"
            , "images_list"
            , "code_snippets"
            , "cleaned_body"
        ]].rename(columns = {
            "id" : "a_id"
            , "body" : "a_body"
            , "images_list" : "a_images_list"
            , "code_snippets" : "a_code_snippets"
            , "cleaned_body" : "a_cleaned_body"
        })
        t3 = t1.merge(
            t2
            , left_on = "accepted_answer_id"
            , right_on = "a_id"
            , how = "inner"
        ).drop(columns = "a_id")
        # ... removes any cleaned answers that are null
        t4 = t3
        t4 = t4[t4.a_cleaned_body.notnull()]
        t4 = t4[t4["a_cleaned_body"] != ""]
        if self.sample_n is not None:
            t5 = t4.sample(self.sample_n, random_state = self.random_state)
        else:
            t5 = t4
        return(t5)
    
    def prepare(self):
        '''
        loads data & makes corpus
        '''
        self.questions = pd.read_csv(self.question_file, delimiter = ",", encoding = "utf-8")
        self.answers = pd.read_csv(self.answer_file, delimiter = "\t", keep_default_na=False, encoding = "utf-8")
        self.corpus = self._construct_corpus(self.questions, self.answers)
    
    def get_similar_documents(self, query, num_results = 5, threshold = 0.10):
        sentence_pairs = self.ceshiner.convert_sentence_pair(
            [query] * self.corpus.shape[0]
            , self.corpus.a_cleaned_body.tolist()
            , max_seq_length = self.max_seq_length
            , tokenizer = self.tokenizer
            , logger = self.logger
        )
        similarity_scores = self.ceshiner.eval_pairs(
            sentence_pairs = sentence_pairs
            , batch_size = self.batch_size
            , model = self.model
            , device = self.device
            , logger = self.logger
        )
        self.corpus_res = self.corpus.copy()
        self.corpus_res["similarity"] = similarity_scores
        self.best_matches = self.corpus_res.copy()
        self.best_matches = self.best_matches[self.best_matches['similarity'] >= threshold]
        self.best_matches = self.best_matches.sort_values('similarity', ascending = False)
        self.best_matches = self.best_matches[:num_results]
        similar_que = self.best_matches["q_title"]
        similar_ans = self.best_matches["a_cleaned_body"]
        similar_img = self.best_matches["a_images_list"]
        similar_code = self.best_matches["a_code_snippets"]
        return(similar_que, similar_ans, similar_img, similar_code)


class InputFeatures(object):
    """A single set of features of data."""

    def __init__(self, input_ids, input_mask, segment_ids, target):
        self.input_ids = input_ids
        self.input_mask = input_mask
        self.segment_ids = segment_ids
        self.target = target


class Ceshiner():
    def __init__(self):
        pass
    
    def _truncate_seq_pair(self, tokens_a, tokens_b, max_length):
        """Truncates a sequence pair in place to the maximum length."""
        # This is a simple heuristic which will always truncate the longer sequence
        # one token at a time. This makes more sense than truncating an equal percent
        # of tokens from each, since if one sequence is very short then each token
        # that's truncated likely contains more information than a longer sequence.
        while True:
            total_length = len(tokens_a) + len(tokens_b)
            if total_length <= max_length:
                break
            if len(tokens_a) > len(tokens_b):
                tokens_a.pop()
            else:
                tokens_b.pop()
                
    def convert_sentence_pair(self, titles, descs, max_seq_length, tokenizer, logger):
        features = []
        for (ex_index, (title, desc)) in enumerate(zip(titles, descs)):
            tokens_a = tokenizer.tokenize(title)
            
            tokens_b = None
            tokens_b = tokenizer.tokenize(desc)
            # Modifies `tokens_a` and `tokens_b` in place so that the total
            # length is less than the specified length.
            # Account for [CLS], [SEP], [SEP] with "- 3"
            self._truncate_seq_pair(tokens_a, tokens_b, max_seq_length - 3)

            # The convention in BERT is:
            # (a) For sequence pairs:
            #  tokens:   [CLS] is this jack ##son ##ville ? [SEP] no it is not . [SEP]
            #  type_ids: 0   0  0    0    0     0       0 0    1  1  1  1   1 1
            # (b) For single sequences:
            #  tokens:   [CLS] the dog is hairy . [SEP]
            #  type_ids: 0   0   0   0  0     0 0
            #
            # Where "type_ids" are used to indicate whether this is the first
            # sequence or the second sequence. The embedding vectors for `type=0` and
            # `type=1` were learned during pre-training and are added to the wordpiece
            # embedding vector (and position vector). This is not *strictly* necessary
            # since the [SEP] token unambigiously separates the sequences, but it makes
            # it easier for the model to learn the concept of sequences.
            #
            # For classification tasks, the first vector (corresponding to [CLS]) is
            # used as as the "sentence vector". Note that this only makes sense because
            # the entire model is fine-tuned.
            tokens = ["[CLS]"] + tokens_a + ["[SEP]"]
            segment_ids = [0] * len(tokens)

            if tokens_b:
                tokens += tokens_b + ["[SEP]"]
                segment_ids += [1] * (len(tokens_b) + 1)

            input_ids = tokenizer.convert_tokens_to_ids(tokens)

            # The mask has 1 for real tokens and 0 for padding tokens. Only real
            # tokens are attended to.
            input_mask = [1] * len(input_ids)

            # Zero-pad up to the sequence length.
            padding = [0] * (max_seq_length - len(input_ids))
            input_ids += padding
            input_mask += padding
            segment_ids += padding

            assert len(input_ids) == max_seq_length
            assert len(input_mask) == max_seq_length
            assert len(segment_ids) == max_seq_length
            if ex_index < 5:
                logger.info("*** Example ***")
                logger.info("tokens: %s" % " ".join(
                        [str(x) for x in tokens]))
                logger.info("input_ids: %s" % " ".join([str(x) for x in input_ids]))
                logger.info("input_mask: %s" % " ".join([str(x) for x in input_mask]))
                logger.info(
                        "segment_ids: %s" % " ".join([str(x) for x in segment_ids]))

            features.append(
                    InputFeatures(
                        input_ids=input_ids,
                        input_mask=input_mask,
                        segment_ids=segment_ids,
                        target=1
            ))
        return features

    def eval_pairs(self, sentence_pairs, batch_size, model, device, logger):
        logger.info("***** Running evaluation *****")
        all_input_ids = torch.tensor([f.input_ids for f in sentence_pairs], dtype=torch.long)
        all_input_mask = torch.tensor([f.input_mask for f in sentence_pairs], dtype=torch.long)
        all_segment_ids = torch.tensor([f.segment_ids for f in sentence_pairs], dtype=torch.long)
        eval_data = TensorDataset(all_input_ids, all_input_mask, all_segment_ids)
        # Run prediction for full data
        eval_sampler = SequentialSampler(eval_data)
        eval_dataloader = DataLoader(eval_data, sampler = eval_sampler, batch_size = batch_size)

        logger.info("  Num examples = %d", len(sentence_pairs))
        logger.info("  Batch size = %d", batch_size)

        model.eval()

        res = []

        mb = progress_bar(eval_dataloader)
        for input_ids, input_mask, segment_ids in mb:
            input_ids = input_ids.to(device)
            input_mask = input_mask.to(device)
            segment_ids = segment_ids.to(device)

            with torch.no_grad():
                res.append(nn.functional.softmax(
                    model(input_ids, segment_ids, input_mask), dim=1
                )[:, 0].detach().cpu().numpy())

        res = np.concatenate(res)
        return(res)
