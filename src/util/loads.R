# source paths
r_tidy_stackoverflow_tags <- here::here("src", "data", "stack-exchange", "tidy-stackoverflow-tags.R")

# data paths
p_stackoverflow_tags <- here::here("data", "raw", "stack-exchange", "stackoverflow.com-Tags.xml")

# loads sources function
source(r_tidy_stackoverflow_tags)

# loads data
stackoverflow_tags <- tidy_stackoverflow_tags(p_stackoverflow_tags)

