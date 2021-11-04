import flask
import pickle
import pandas as pd
import gensim
import nltk
#nltk.download('punkt')
#import gcsfs
import sys
sys.path.append("..")
from src.models import tf_idf_model as tf_idf_model

from src.models import bert_model as bert_model
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

# defines seed for replication
SEED = 20191203

# cached data
p_base_dir = "/mnt/disks/w210-jcgy-bucket/w210-data-output-new-q-and-a-files-with-separate-cleaned-answer-bodies"
p_questions = os.path.join(p_base_dir, "new_qs_22k.csv")
p_answers = os.path.join(p_base_dir, "PostAnswersFiltered_V4_cleaned_answer_bodies.tsv")


# prepares BERT ----------------------------------

# defines cache folder for BERT model
PYTORCH_PRETRAINED_BERT_CACHE = "../models/bert/"

SAMPLE_SIZE = None
BATCH_SIZE = 128
MAX_SEQ_LENGTH = 200

# creates a logger
logging.basicConfig(format = '%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
                    datefmt = '%m/%d/%Y %H:%M:%S',
                    level = logging.INFO)
logger = logging.getLogger("bert")


# detects the device (CPU or GPU)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


# sets random states
random.seed(SEED)
np.random.seed(SEED)
torch.manual_seed(SEED)
if device == torch.device("cuda"):
    torch.cuda.manual_seed_all(SEED)

# instantiates model
n = bert_model.Suggester_BertTopicSimiliarty(
    p_questions
    , p_answers
    , sample_n = SAMPLE_SIZE
    , random_state = SEED
    , bert_cache = PYTORCH_PRETRAINED_BERT_CACHE
    , logger = logger
    , device = device
    , max_seq_length = MAX_SEQ_LENGTH
    , batch_size = BATCH_SIZE
)
n.prepare()


# prepares tfidf ----------------------------------

# instantiates model
m = tf_idf_model.tfModel(p_questions, p_answers)



# prepares app ----------------------------------

# Initialise the Flask app
app = flask.Flask(__name__, template_folder='templates')

# Set up the main route
@app.route('/', methods=['GET', 'POST'])
def main():
    if flask.request.method == 'GET':
        # Just render the initial form, to get input
        return(flask.render_template('main.html'))

    if flask.request.method == 'POST':
        # Extract the input
        userquery = flask.request.form['userquery']
        options = flask.request.form['options']

        # Make DataFrame for model
        input_variables = userquery

        # Get the model's prediction
        #prediction = model.predict(input_variables)[0]

        if options == 'option 1':
            similar_que, similar_ans, similar_img, similar_code = m.get_similar_documents(input_variables, num_results=3)
        elif options == 'option 2':
            similar_que, similar_ans, similar_img, similar_code = n.get_similar_documents(input_variables, num_results=3)

        # Render the form again, but add in the prediction and remind user
        # of the values they input before
        return flask.render_template('result.html',
                                     original_input=userquery,
                                     que=similar_que,
                                     ans=similar_ans,
                                     img=similar_img,
                                     code=similar_code,
                                     )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
