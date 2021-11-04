# basic eda on data
#
library(tidyverse)
library(janitor)
library(here)
library(repurrrsive)
library(xml2)
library(viridisLite)


# eda of stackoverflow tags -------------------------
#
stackoverflow_tags %>% colnames() # id, tag_name, count, excerpt_post_id, wiki_post_id 
stackoverflow_tags %>% nrow() # 55665 rows
stackoverflow_tags %>% distinct(tag_name) %>% nrow() # 55665
stackoverflow_tags %>% select(id, count, excerpt_post_id, wiki_post_id) %>% summary()

# ... counts of is.na
stackoverflow_tags %>% 
    map_df(is.na) %>% 
    pivot_longer(everything()) %>% 
    count(name, value) %>% 
    rename(is_na = value) %>% 
    pivot_wider(names_from = is_na, values_from = n, values_fill = list(n = 0))
# ... looks like we have about 25% of tags without post ids ???

# ... checks for dups
assert_that(stackoverflow_tags %>% count(id, sort = TRUE) %>% filter(n > 1) %>% nrow() == 0) # no dups of id
assert_that(stackoverflow_tags %>% count(tag_name, sort = TRUE) %>% filter(n > 1) %>% nrow() == 0) # 0, no dups of tagnames
assert_that(stackoverflow_tags %>% count(excerpt_post_id, sort = TRUE) %>% filter(n > 1 & !is.na(excerpt_post_id)) %>% nrow() == 0) # not counting the NA posts, no dups
assert_that(stackoverflow_tags %>% count(wiki_post_id, sort = TRUE) %>% filter(n > 1 & !is.na(wiki_post_id)) %>%  nrow() == 0) # not counting the NA posts, no dups

# ... top tags
stackoverflow_tags %>% 
    select(tag_name, count) %>% 
    top_n(n = 20, wt = count) %>% 
    ggplot(aes(reorder(tag_name, count), count)) + 
    geom_col() +
    coord_flip()


stackoverflow_tags %>% filter(str_detect(tag_name, "tableau")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "d3.js")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "ggplot")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "plotly")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "matplotlib")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "altair")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "powerbi")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "qlik")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "sas")) %>% pull(tag_name)
stackoverflow_tags %>% filter(str_detect(tag_name, "spss")) %>% pull(tag_name)

stackoverflow_tags %>% filter(str_detect(tag_name, "excel")) %>% arrange(-count) %>% View()

stackoverflow_tags %>% filter(str_detect(tag_name, "visual")) %>% arrange(-count) %>% View()
stackoverflow_tags %>% filter(str_detect(tag_name, "chart")) %>% arrange(-count) %>% View()
stackoverflow_tags %>% filter(str_detect(tag_name, "graph")) %>% arrange(-count) %>% View()
stackoverflow_tags %>% filter(tag_name %in% c("charts", "plot", "graph", "linechart"))



tags_relevant <- c(
    "tableau"
    , "tableau-server"
    , "tableau-online"
    , "tableau-public"
    , "d3.js"
    , "nvd3.js"
    , "d3.js-v4"
    , "d3.js-lasso"
    , "ggplot2"
    , "python-ggplot"
    , "ggplotly"
    , "plotly"
    , "plotly-dash"
    , "ggplotly"
    , "r-plotly"
    , "plotly.js"
    , "plotly-python" 
    , "plotly-express"
    , "matplotlib"
    , "matplotlib-basemap"
    , "matplotlib-widget"
    , "matplotlib-venn"   
    , "matplotlib.mlab"
    , "matplotlib-table"  
    , "altair"
    , "excel-charts"
    , "google-visualization"

    , "powerbi"
    , "powerbi-embedded"
    , "powerbi-datasource"
    , "powerbi-mobile"
    , "powerbi-desktop"
    , "powerbi-js-api"
    , "powerbi-datagateway"
    , "powerbi-custom-visuals"
    , "powerbi-filters"          
    , "powerbi-paginated-reports"
    
    , "data-visualization"
    , "visualization"
    , "charts"
    , "plot"
    , "linechart"
    
)




t1 <- stackoverflow_tags %>% 
    filter(
        (
            str_detect(tag_name, "visual")
            | str_detect(tag_name, "chart")
            | str_detect(tag_name, "graph")
            | str_detect(tag_name, "plot")
            | str_detect(tag_name, "diagram")
            | str_detect(tag_name, "map")
        )
        & !(tag_name %in% c(
            "visual-studio"
            , "visual-studio-2005"
            , "visual-studio-2008"
            , "visual-studio-2010"
            , "visual-studio-2012"
            , "visual-studio-2013"
            , "visual-studio-2015"
            , "visual-studio-2017"
            , "visual-studio-2018"
            , "visual-studio-code"
            , "visual-c++"
            , "facebook-graph-api"
            , "cryptography"
            , "core-graphics"
            , "graphics"
        ))
    ) %>% 
    select(tag_name, count) %>% 
    top_n(n = 20, wt = count) %>% 
    ggplot(aes(reorder(tag_name, count), count)) + 
    geom_col() +
    coord_flip() +
    labs(title = "Common visualization phrases") +
    theme_minimal()


t1 %>% ggsave(
    filename = "common-tags.png"
    , device = "png"
    , path = here::here("notebooks", "figures")
    , width = 8, height = 4, units = "in"
)





t1 <-stackoverflow_tags %>% 
    filter(
        (
            str_detect(tag_name, "tableau")
            | str_detect(tag_name, "d3.js")
            | str_detect(tag_name, "ggplot")
            | str_detect(tag_name, "plotly")
            | str_detect(tag_name, "matplotlib")
            | str_detect(tag_name, "altair")
            | str_detect(tag_name, "powerbi")
            | str_detect(tag_name, "excel-charts")
            | str_detect(tag_name, "qlik")
            | tag_name == "sas"
            | str_detect(tag_name, "spss")
            | str_detect(tag_name, "stata")
            | str_detect(tag_name, "matlab")
            | str_detect(tag_name, "seaborn")
        )
    ) %>% 
    select(tag_name, count) %>% 
    top_frac(n = 0.25, wt = count) %>% 
    ggplot(aes(reorder(tag_name, count), count)) + 
    geom_col() +
    coord_flip() +
    labs(
        title = "Common visualization tags"
        , subtitle = "top 25% of tags, by number of posts"
        , caption = "data source: stackoverflow"
        , x = "number of posts"
        , y = "tag"
    ) +
    theme_minimal()

t1 %>% ggsave(
    filename = "common-tags.png"
    , device = "png"
    , path = here::here("notebooks", "figures")
    , width = 8, height = 4, units = "in"
)





# big query? -------------------------------


# viz for 

t1 <- read_csv(here::here("data", "external", "stackoverflow-bigquery-roughcounts.csv")) %>% 
    clean_names()

t2 <- t1 %>% 
    ggplot(aes(reorder(post_tags_contains, count), count, fill = post_body_contains)) +
    geom_col() + 
    coord_flip() +
    scale_fill_discrete(name = "post body contains") + 
    labs(
        title = "Common visualization phrases from posts"
        , subtitle = "keyword queries via bigquery"
        , caption = "data source: stackoverflow"
        , x = "post tag contains"
        , y = "number of posts"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
    

t2 %>% ggsave(
    filename = "common-phrases.png"
    , device = "png"
    , path = here::here("notebooks", "figures")
    , width = 8, height = 4, units = "in"
)



# Chart types? --------------------------------------------

# see Chi's spreadsheet

t1 <- read_csv(here::here("data", "external", "Chart Types of Viz Toolkits - Sheet1.csv")) %>% 
    clean_names() %>% 
    rename(
        product = x1
        , url = x2
    )

t2 <- t1 %>% 
    select(-url) %>% 
    pivot_longer(-product) %>% 
    rename(has_feature = value) %>% 
    mutate(
        has_feature = case_when(
            has_feature == "x" ~ 1L
            , TRUE ~ 0L
        )
    )

t2a <- t2 %>% 
    group_by(product) %>% 
    summarise(cnt = sum(has_feature)) %>% 
    ungroup() %>% 
    arrange(-cnt)

t2b <- t2a$product

t2c <- t2 %>% 
    group_by(name) %>% 
    summarise(cnt = sum(has_feature)) %>% 
    ungroup() %>% 
    arrange(-cnt)

t2d <- t2c$name

t2$product <- factor(t2$product, levels = t2b)
t2$name <- factor(t2$name, levels = t2d)

t3 <- t2 %>% 
    ggplot(aes(product, name, fill = factor(has_feature))) + 
    geom_tile() + 
    scale_fill_viridis_d(name = "has feature") +
    theme_minimal() + 
    labs(
        title = "Chart Types of Viz Toolkits"
        , caption = "data source: Chart Types of Viz Toolkits"
        , x = "product"
        , y = "feature"
    )

t3 %>% ggsave(
    filename = "chart-types-viz-toolkits.png"
    , device = "png"
    , path = here::here("notebooks", "figures")
    , width = 12, height = 12, units = "in"
)





# Votes? -------------------------------------------------

p_stackoverflow_votes <- here::here("data", "raw", "stack-exchange", "stackoverflow.com-Votes.xml")

tidy_stackoverflow_votes <- function(p_stackoverflow_votes) {
    t1 <- read_xml(p_stackoverflow_votes) 
        
}