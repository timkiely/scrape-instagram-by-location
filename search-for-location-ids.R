
suppressPackageStartupMessages({
  library(httr)
  library(tidyverse)
})

search_for_location_ids <- function(location = NULL){
  base_url <- "https://www.instagram.com/web/search/topsearch/?context=place&query=%s"
  
  location_clean <- gsub(" ","+",gsub(",","",location))
  query_url <- sprintf(base_url,location_clean)
  req <- GET(query_url)
  
  response_status <- status_code(req)
  if(response_status!=200) stop("server returned an error")
  txt <- content(req, "text", encoding = "UTF-8")
  response <- jsonlite::fromJSON(txt)
  response_df <- response$places$place$location
  
  
  list('data' = tbl_df(response_df), 'status' = response_status)
}