library(tidyverse)
library(janitor)
library(here)
library(assertthat)

#' Tidy reading of xml file of stackoverflow tags
#' 
#' @param p_stackoverflow_tags path to stackoverflow tags xml file
#' @return tibble of tags
#' @examples
#' tags <- tidy_stackoverflow_tags(p_stackoverflow_tags)
tidy_stackoverflow_tags <- function(p_stackoverflow_tags) {
    t1 <- read_xml(p_stackoverflow_tags)
    t2 <- t1 %>% as_list()
    t3 <- tibble(tag = t2$tags)
    t4 <- t3 %>% pull(tag)
    t5 <- map_df(t4, attributes)
    t6 <- t5 %>% 
        clean_names() %>% 
        mutate(
            id = parse_integer(id)
            , count = parse_integer(count)
            , excerpt_post_id = parse_integer(excerpt_post_id)
            , wiki_post_id = parse_integer(wiki_post_id)
        )
    stackoverflow_tags <- t6
    return(stackoverflow_tags)
}