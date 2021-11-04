library(tidyverse)
library(here)
library(janitor)

# loads data ------------------------

p_answers <- here::here("data", "interim", "v4", "PostAnswersFiltered_V4_cleaned_answer_bodies.tsv")
p_questions <- here::here("data", "interim", "v4", "PostQuestionsFiltered_V4_parsed.tsv")

answers <- read_delim(p_answers, delim = "\t")
questions <- read_delim(p_questions, delim = "\t")


# creates some more interim data =============================

# t1 <- questions %>% 
#     select(id, javascript:r) %>% 
#     pivot_longer(cols = javascript:r, names_to = "tag", values_to = "has_tag") %>% 
#     filter(has_tag == 1)
# 
# p_questions_tags_long <- here::here("data", "interim", "v4", "questions_tags_long.tsv")
# t1 %>% write_delim(p_questions_tags_long, delim = "\t")






# EDA ----------------------------------

questions %>% nrow() # 429665
answers %>% nrow() # 547858


questions %>% head(3)
answers %>% head(3)

questions %>% colnames()
answers %>% colnames()


# dates =========================

t1 <- questions %>% 
    select(creation_date) %>% 
    summary()
# 2008 to 2019

t2 <- answers %>% 
    select(creation_date) %>% 
    summary()
# also 2008 to 2019

t3 <- select(questions, q_id = id, q_creation_date = creation_date, accepted_answer_id) %>% 
    inner_join(select(answers, a_id= id, a_creation_date = creation_date), by = c("accepted_answer_id" = "a_id")) %>% 
    select(q_creation_date, a_creation_date)

t3 %>% nrow() # 220564 question, answer pairs

t4 <- t3 %>% 
    ggplot(aes(q_creation_date, a_creation_date)) + 
    geom_point(alpha = 0.1)


# question tags ==========================
# only applies to questions



t2 <- read_delim(p_questions_tags_long, delim = "\t")

t3 <- t2 %>% count(tag, sort = TRUE)
t4 <- t3 %>% top_n(10, wt = n) 
t5 <- t4 %>%
    ggplot(aes(reorder(tag, n), n)) +
    geom_col() + 
    coord_flip()


# answered questions tags and dates =======================

t1 <- questions %>% 
    select(q_id = id, q_creation_date = creation_date, accepted_answer_id)
t2 <- read_delim(p_questions_tags_long, delim = "\t") %>% 
    select(q_id = id, tag, has_tag)
t3 <- answers %>% 
    select(a_id = id, a_creation_date = creation_date)
t4 <- t1 %>% 
    inner_join(t3, by = c("accepted_answer_id" = "a_id")) %>% 
    inner_join(t2, by = "q_id") %>% 
    select(a_creation_date, tag)
t5 <- t4 %>% 
    # mutate(ym = format(a_creation_date, "%Y-%m"))
    mutate(yyyy = format(a_creation_date, "%Y"))
t6 <- t5 %>% count(yyyy, tag)
t7 <- t6 %>% 
    ggplot(aes(x = yyyy, y = n)) +
    geom_col() +
    facet_wrap(vars(tag))
# if we don't stratify sample, our answers will be dominated by the most popular tags


# tags associated with each other ==============================================

t1 <- questions %>% 
    select(q_id = id, accepted_answer_id)
t2 <- read_delim(p_questions_tags_long, delim = "\t") %>% 
    select(q_id = id, tag, has_tag)
t3 <- answers %>% 
    select(a_id = id)
t4 <- t1 %>% 
    inner_join(t3, by = c("accepted_answer_id" = "a_id")) %>% 
    inner_join(t2, by = "q_id") %>% 
    select(q_id, tag, has_tag)
t5 <- t4 %>% 
    pivot_wider(names_from = "tag", values_from = "has_tag", values_fill = list(has_tag = 0))
t6 <- t5 %>% select(-q_id)
t7 <- cor(t6)
t8 <- t7 %>% as_tibble(rownames= "tag1")
t9 <- t8 %>% pivot_longer(cols = graph:qlikview, names_to = "tag2", values_to = "cr")

# distribution of correlations
t10a <- t9 %>% ggplot(aes(cr)) + geom_histogram() + scale_y_log10()
t10b <- t9 %>% ggplot(aes(abs(cr))) + geom_histogram() + scale_y_log10()
t10c <- t9 %>% filter(tag1 != tag2) %>% ggplot(aes(abs(cr))) + geom_histogram() + scale_y_log10()


# top 10 positive and negative non-1
t10 <- t9 %>% 
    filter(tag1 != tag2) %>% 
    ggplot(aes(tag1, tag2)) + geom_tile(aes(alpha = cr))

t10 <- t9 %>% 
    filter(tag1 != tag2 & abs(cr) > 0) %>% 
    top_n(20, wt = abs(cr)) %>% 
    ggplot(aes(tag1, tag2)) + geom_tile(aes(alpha = cr))


# correlations still dominated by python, matplotlib, javascript, etc