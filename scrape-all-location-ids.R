rm(list=ls()[!ls()%in%c("osm_points","osm_places","open_addresses")])



library(tidyverse)
library(sf)
source("search-for-location-ids.R")


# create list of places and addresses -------------------------------------

# OSM place data from: https://mapzen.com/data/metro-extracts/metro/new-york_new-york/
if(!exists("osm_points")){
  osm_points <- read_sf("data/new-york_new-york.osm2pgsql-geojson/new-york_new-york_osm_point.geojson") %>% select(osm_id,name,geometry)
  osm_places <- osm_points %>% filter(!is.na(name))
}




# openaddress data from: http://results.openaddresses.io/?runs=all#runs
if(!exists("open_addresses")){
  open_addresses <- read_csv("data/city_of_new_york.csv")
}




# Loop through places/addresses -------------------------------------------

# wrap the search function in a purrr::safely adverb to handle errors without breaking
s_search_for_location_ids <- search_for_location_ids


# LEFT OFF: THE API RATE LIMITS AFTER 200-300 HITS, DON'T YET KNOW WHAT THE DOWNTIME PENALTY IS

logger <- data.frame()
for(i in 1:length(osm_places$name)){
  cat("\ntrial",i,"of",length(osm_places$name))
  out_frame <- data.frame()
  trial <- i
  time <- Sys.time()
  
  .x <- osm_places$name[i]

  cat("   searching:",.x,"...")
  # make the call
  run_time <- system.time({
    srch <- s_search_for_location_ids(location = .x)
    #if(!is.null(srch$error)) cat(as.character(srch$error),"\n")
    srch2 <- s_search_for_location_ids(location = paste0(.x, ", New York City"))
    #if(!is.null(srch2$error)) cat(as.character(srch2$error),"\n")
    srch_out <- bind_rows(srch,srch2)
  })
  cat("   rows:",nrow(srch_out))
  
}
  




# filter the results for only in Tri State area ---------------------------
osm_boundary <- osm_places %>% select(geometry) %>% count() %>% st_convex_hull()

# takes a data.frame with lat and lng coordinates and filters them by a convex hull boundary
filter_location_by_boundary <- function(locations, boundary){
  if(is.null(locations$lat) | is.null(locations$lng)) stop("locations data.frame must contain lng, lat columns")
  if(!"sf"%in%class(boundary)) stop("boundary argument must be a convex hull from sf::st_convex_hull")
  locations <- locations %>% st_as_sf(coords = c("lng","lat"), remove = FALSE, crs = st_crs(boundary))
  suppressWarnings( 
    st_intersection(boundary,locations) %>% tbl_df() %>% select(-geometry)
  )
}

filter_location_by_boundary(locations = bind_rows(raw_responses), boundary = osm_boundary)

