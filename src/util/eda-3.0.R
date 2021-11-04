library(tidyverse)
library(here)
library(janitor)

# loads data ------------------------

p_base_dir <- "/mnt/disks/w210-jcgy-bucket/w210-data-output-new-q-and-a-files-with-separate-cleaned-answer-bodies"
p_questions <- fs::path(p_base_dir, "PostQuestionsFiltered_V4_parsed.tsv")
p_answers <- fs::path(p_base_dir, "PostAnswersFiltered_V4_cleaned_answer_bodies.tsv")
p_new_questions <- fs::path(p_base_dir, "new_qs.csv")


answers <- read_delim(p_answers, delim = "\t")
questions <- read_delim(p_questions, delim = "\t")
q_a <- select(questions, id, title, accepted_answer_id) %>% 
    inner_join(select(answers, id, body, cleaned_body), by = c("accepted_answer_id" = "id"))

questions_new <- read_csv (p_new_questions)



# EDA ----------------------------------

questions %>% nrow() # 429665
answers %>% nrow() # 547858
questions_new %>% nrow() # 10000

questions %>% head(3)
answers %>% head(3)
questions_new %>% head(3)

questions %>% colnames()
answers %>% colnames()
questions_new %>% colnames()


# 

# original vs cleaned ===================
answers %>% 
    sample_n(3) %>% 
    select(body, cleaned_body) %>% View()

answers %>% 
    sample_n(3) %>% 
    select(images_list)

answers %>% 
    sample_n(3) %>% 
    select(code_snippets)


answers %>% 
    filter(str_detect(cleaned_body, "I'm not 100% sure on wordpress standards, but here's a way to do it.")) %>% 
    select(body, cleaned_body) %>% 
    View()


answers %>% 
    filter(str_detect(cleaned_body, "^nan$"))




# there are actually some answers whose entire code chunk is the entire answer ... probably a mistaken code tags
# ... this breaks the BERT tokenizer btw
# see example
# https://stackoverflow.com/questions/56589083/how-to-pass-a-powershell-variable-defined-in-one-stage-of-jenkinsfile-to-another
#
q_a %>% 
    filter(title == "How to pass a powershell variable defined in one stage of jenkinsfile to another stage of same jenkinsfile?") %>% 
    View()

q_a %>% 
    count(is.na(cleaned_body))

# `is.na(cleaned_body)`      n
# <lgl>                  <int>
#   1 FALSE                 218898
#   2 TRUE                    1666

