
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
  tbl_df(response_df)
}
  
srch <- search_for_location_ids(location = "Williamsburg, New York")




# testing stuff -----------------------------------------------------------
meters_per_mile <- 100
lat <- 40.716757 
lon <- -73.959584


'https://api.instagram.com/v1/locations/search?lat=48.858844&lng=2.294351'

rm(response)
qry <- "https://www.instagram.com/web/search/topsearch/?context=place&lat=%s&lng=%s"
qry_full <- sprintf(qry, lat, lon)
req <- GET(qry_full)
(txt <- content(req, "text", encoding = "UTF-8") )
response <- jsonlite::fromJSON(txt)
response
