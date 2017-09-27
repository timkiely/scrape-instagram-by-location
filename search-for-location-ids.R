
suppressPackageStartupMessages({
  library(httr)
  library(tidyverse)
})

search_for_location_ids <- function(location = NULL){
  base_url <- "https://www.instagram.com/web/search/topsearch/?context=place&query=%s"
  
  location_clean <- gsub(" ","+",gsub(",","",location))
  query_url <- sprintf(base_url,location_clean)
  req <- GET(query_url)
  
  if(status_code(req)!=200) stop("server returned an error")
  txt <- content(req, "text", encoding = "UTF-8")
  response <- jsonlite::fromJSON(txt)
  response_df <- response$places$place$location
  
  #include error handling here?
  #if(is.null(response_df)) stop("Address has no content")
  tbl_df(response_df)
}

# Test:  
# ( srch <- search_for_location_ids(location = "Charging Bull") )
