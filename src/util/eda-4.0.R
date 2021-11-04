library(tidyverse)
library(here)
library(janitor)

# loads data ------------------------

p_base_dir <- "/mnt/disks/w210-jcgy-bucket/w210-data-output-new-q-and-a-files-with-separate-cleaned-answer-bodies"
p_questions <- fs::path(p_base_dir, "SODSQuesWImg.csv")
p_answers <- fs::path(p_base_dir, "SODSAnsWImg.tsv")

questions <- read_delim(p_questions, delim = ",")
answers <- read_delim(p_answers, delim = "\t")

questions %>% head()
answers %>% head()

questions %>% nrow() # 39105
answers %>% nrow() # 46188


questions %>% colnames()
questions %>% select(accepted_answer_id) %>% mutate(accepted_answer_id = is.na(accepted_answer_id)) %>% count() # 39105

questions %>% select(view_count) %>% mutate(view_count = is.na(view_count)) %>% count(view_count) # 39105 non null
questions %>% select(favorite_count) %>% mutate(favorite_count = is.na(favorite_count)) %>% count(favorite_count) # 14711 non-null

questions %>% select(creation_date) %>% mutate(creation_date = is.na(creation_date)) %>% count() # 39105
questions %>% select(last_activity_date) %>% mutate(last_activity_date = is.na(last_activity_date)) %>% count() # 39105

questions %>% select(score) %>% summary() # -10 to 1865
questions %>% pull(score) %>% hist() # long tail on right


answers %>% colnames()
answers %>% select(score) %>% summary() # -6 to 1575
answers %>% pull(score) %>% hist() # long tail on right

# q-a pairs
t1 <- questions %>% 
    inner_join(answers, by = c("accepted_answer_id" = "id"))
t1 %>% nrow() # 35438



# relationship between score of questions and various counts
t1 <- questions %>% 
    select(score, favorite_count) %>% 
    filter(!is.na(favorite_count)) %>% 
    mutate(score = scale(score), favorite_count = scale(favorite_count))
t1 %>% plot()
cor(t1$score, t1$favorite_count) # 0.84
questions %>% filter(!is.na(favorite_count)) %>% nrow() # 14711 non null

t1 <- questions %>% 
    select(score, view_count) %>% 
    filter(!is.na(view_count)) %>% 
    mutate(score = scale(score), view_count = scale(view_count))
t1 %>% plot()
cor(t1$score, t1$view_count) # 0.77
questions %>% filter(!is.na(view_count)) %>% nrow() # 39105 non null

# so favorite count is better correlated with higher score, but there are fewer entries

t1 <- questions %>% 
    select(score, comment_count) %>% 
    filter(!is.na(comment_count)) %>% 
    mutate(score = scale(score), comment_count = scale(comment_count))
t1 %>% plot()
cor(t1$score, t1$comment_count) # 0.03

t1 <- questions %>% 
    select(score, answer_count) %>% 
    filter(!is.na(answer_count)) %>% 
    mutate(score = scale(score), answer_count = scale(answer_count))
t1 %>% plot()
cor(t1$score, t1$answer_count) # 0.45



# relationship between question score and various dates
t1 <- questions %>% 
    select(score, community_owned_date) %>% 
    filter(!is.na(community_owned_date))

t1 <- questions %>% 
    select(score, creation_date) %>% 
    mutate(creation_date = as.numeric(creation_date)) %>% 
    filter(!is.na(creation_date)) %>% 
    mutate(score = scale(score), creation_date = scale(creation_date))
t1 %>% plot()
cor(t1$score, t1$creation_date) # -0.21

t1 <- questions %>% 
    select(score, last_activity_date) %>% 
    mutate(last_activity_date = as.numeric(last_activity_date)) %>% 
    filter(!is.na(last_activity_date)) %>% 
    mutate(score = scale(score), last_activity_date = scale(last_activity_date))
t1 %>% plot()
cor(t1$score, t1$last_activity_date) # 0.05

t1 <- questions %>% 
    select(score, last_edit_date) %>% 
    mutate(last_edit_date = as.numeric(last_edit_date)) %>% 
    filter(!is.na(last_edit_date)) %>% 
    mutate(score = scale(score), last_edit_date = scale(last_edit_date))
t1 %>% plot()
cor(t1$score, t1$last_edit_date) # -0.05

# none of the date questions fields are very correlated with high scores


# so if we want to use questions as the primary comparison, then the accepted answer is automatically the best answer








# feature selection using feature importance

# see https://machinelearningmastery.com/feature-selection-with-the-caret-r-package/
# ensure results are repeatable
set.seed(20191211)
# load the library
library(mlbench)
library(caret)
# load the dataset
data(PimaIndiansDiabetes)
# prepare training scheme
control <- trainControl(method="repeatedcv", number=10, repeats=3)
# train the model
model <- train(diabetes~., data=PimaIndiansDiabetes, method="lvq", preProcess="scale", trControl=control)
# estimate variable importance
importance <- varImp(model, scale=FALSE)
# summarize importance
print(importance)
# plot importance
plot(importance)