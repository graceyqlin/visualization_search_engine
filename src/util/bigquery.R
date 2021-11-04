# https://db.rstudio.com/databases/big-query/
# https://bigrquery.r-dbi.org/
# https://www.rdocumentation.org/packages/bigrquery/versions/0.4.1


# install.packages("bigrquery")

library(bigrquery)
project <- "w210-jcgy-254100"
sql <- "SELECT COUNT(*) FROM `bigquery-public-data.stackoverflow.tags`"
query_exec(sql, project = project, use_legacy_sql = FALSE)

sql <- "SELECT * FROM `bigquery-public-data.stackoverflow.tags` LIMIT 10"
tb <- bq_project_query(project, sql)
bq_table_download(tb, max_results = 10)




library(DBI)

con <- dbConnect(
    bigrquery::bigquery(),
    project = "w210-jcgy-254100",
    dataset = "samples",
    billing = billing
)