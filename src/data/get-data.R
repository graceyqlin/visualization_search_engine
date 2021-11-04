# script for getting data, maybe some of them
#
library(tidyverse)
library(janitor)
library(here)
library(assertthat)


# TODO, make this work?

# stackoverflow.com-Tags.7z
f1 <- here::here("data", "raw", "stack-exchange", "stackoverflow.com-Tags.7z")
u1 <- "https://archive.org/download/stackexchange/stackoverflow.com-Tags.7z"
    
utils::download.file(u1, f1, "curl")
