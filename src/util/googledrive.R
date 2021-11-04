library(tidyverse)
library(janitor)
library(here)
library(googledrive)

# https://googledrive.tidyverse.org/
# https://rdrr.io/github/tidyverse/googledrive/man/drive_ls.html


t1 <- drive_find(n_max = 30)
my_files <- t1

my_files %>% View()


# Posts -------------------------
t1 <- drive_find("Posts", n_max = 30)
t2 <- t1 %>% 
    filter(name == "Posts") %>% 
    pull(id)

t3 <- drive_ls(as_id(t2), recursive = FALSE)
for (i in t3$id) {
    drive_download(as_id(i))
}


# Badges --------------------------------
t1 <- drive_find("Badges", n_max = 30)
t2 <- t1 %>% 
    filter(name == "Badges") %>% 
    pull(id)

t3 <- drive_ls(as_id(t2), recursive = FALSE)
for (i in t3$id) {
    drive_download(as_id(i))
}


# Tags ----------------------------------
t1 <- drive_find("Tags", n_max = 30)
t2 <- t1 %>% 
    filter(name == "Tags") %>% 
    pull(id)

t3 <- drive_ls(as_id(t2), recursive = FALSE)
for (i in t3$id) {
    drive_download(as_id(i))
}


# Users ----------------------------------
t1 <- drive_find("Users", n_max = 30)
t2 <- t1 %>% 
    filter(name == "Users") %>% 
    pull(id)

t3 <- drive_ls(as_id(t2), recursive = FALSE)
for (i in t3$id) {
    drive_download(as_id(i))
}



