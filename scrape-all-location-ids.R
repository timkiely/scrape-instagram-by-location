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





# function filters the results for only in Tri State area ---------------------------
osm_boundary <- osm_places %>% select(geometry) %>% count() %>% st_convex_hull()

# takes a data.frame with lat and lng coordinates and filters them by a convex hull boundary
filter_location_by_boundary <- function(locations, boundary){
  if(is.null(locations$lat) | is.null(locations$lng)) stop("locations data.frame must contain lng, lat columns")
  if(!"sf"%in%class(boundary)) stop("boundary argument must be a convex hull from sf::st_convex_hull")
  locations <- locations %>% st_as_sf(coords = c("lng","lat"), remove = FALSE, crs = st_crs(boundary), na.fail = FALSE)
  suppressWarnings( 
    st_intersection(boundary,locations) %>% tbl_df() %>% select(-geometry)
  )
}
# filter_location_by_boundary(locations = bind_rows(stage_frame), boundary = osm_boundary)



# function refines the staging data.frame for output ----------------------
refine_stage_frame <- function(stage_frame, boundary = NULL){
  stage_frame <- distinct(stage_frame, pk, .keep_all = TRUE)
  stage_frame <- filter_location_by_boundary(stage_frame, boundary = boundary)
  stage_frame
}


# main search function ----------------------------------------------------
safely_search_for_location_ids <- safely(search_for_location_ids)


# sleep system with progress
sleep_with_progress <- function(sleep_time){
  n <- sleep_time/100
  pb <- progress_estimated(sleep_time)
  map(1:sleep_time, ~{
    pb$tick()$print()
    Sys.sleep(n)  
  })
}


# LOOP  -------------------------------------------

# how long to sleep once rate limit hit (in seconds):
time_to_sleep <- 60*3

# how large should stage_frame get before you post-process and write to disk?
stage_frame_cache_limit <- 1000
i<-1

stage_frame <- data.frame()
logger <- data.frame()
for(i in 1:length(osm_places$name)){
  #tryCatch({
  
  
  # set up and console output:
  cat("\ntrial",i,"of",length(osm_places$name))
  trial <- i
  time <- Sys.time()
  search_term <- osm_places$name[i]
  cat("   searching:",search_term,"...")
  logger <- tibble("time" = time
                   ,"trial" = trial
                   , "run_time_in_seconds" = NA_character_
                   , "search term" = search_term
                   , "status-1" = NA_character_
                   , "status-2" = NA_character_
                   , "search-1-rows" = NA_character_
                   , "search-1-error" = NA_character_
                   , "search-2-rows" = NA_character_
                   , "search-2-error" = NA_character_)
  search_list <- list()
  output <- data.frame()
  
  
  # make the call
  run_time <- 
    suppressMessages({
      system.time({
        srch <- safely_search_for_location_ids(location = search_term)
        srch2 <- safely_search_for_location_ids(location = paste0(search_term, ", New York City"))
      })
    })
  
  search_list <- list('search1'=srch,'search2'=srch2)
  search_out <- bind_rows(search_list$search1$result$data,search_list$search2$result$data)
  cat("   rows:",nrow(search_out))
  
  
  # LOGGER
  na_if_null <- function(value) ifelse(is.null(value), NA, value)
  logger$run_time_in_seconds <- na_if_null(run_time)
  logger$`status-1` <- na_if_null(search_list$search1$result$status)
  logger$`status-2` <- na_if_null(search_list$search2$result$status)
  logger$`search-1-rows` <- na_if_null(nrow(search_list$search1$result$data))
  logger$`search-2-rows` <- na_if_null(nrow(search_list$search2$result$data))
  logger$`search-1-error` <- as.character(na_if_null(search_list$search1$error))
  logger$`search-2-error` <- as.character(na_if_null(search_list$search2$error))
  if(trial==1){
    write_csv(logger, "logger.csv", append = F, col_names = T)
  } else write_csv(logger, "logger.csv", append = T, col_names = F)
  
  
  
  # if the call returns an error or status is not 200,
  # processing the staged data then sleep system
  if(!is.null(search_list$search1$error)) {
    cat("\nSearch-1 Error:",as.character(search_list$search1$error))
    cat("\nProcessing",nrow(stage_frame),"rows of staging data then sleeping for",time_to_sleep/60,"mins...\n")
    if(nrow(stage_frame)==0){
      sleep_with_progress(time_to_sleep)
      next
    } 
    
    output <- refine_stage_frame(stage_frame, osm_boundary)
    
    if(nrow(output)==0){
      sleep_with_progress(time_to_sleep)
      next
    } 
    
    write_csv(output, "location_output.csv" , append=T)
    stage_frame <- data.frame()
    sleep_with_progress(time_to_sleep)
    gc(verbose = FALSE)
    next
  }
  if(!is.null(search_list$search2$error)) {
    cat("\nSearch-2 Error:",as.character(search_list$search2$error))
    cat("\nProcessing",nrow(stage_frame),"rows of staging data then sleeping for",time_to_sleep/60,"mins...\n")
    if(nrow(stage_frame)==0) {
      sleep_with_progress(time_to_sleep)
      next
    }
    
    output <- refine_stage_frame(stage_frame, osm_boundary)
    if(nrow(output)==0) {
      sleep_with_progress(time_to_sleep)
      next
    }
    
    write_csv(output, "location_output.csv" , append=T)
    cat("...",nrow(output),"rows cached")
    stage_frame <- data.frame()
    sleep_with_progress(time_to_sleep)
    gc(verbose = FALSE)
    next
  }
  
  statuses <- sum(c(search_list$search1$result$status,search_list$search2$result$status))
  if(statuses!=400){
    cat("\n Error: call returned a status other than 200: Status",as.character(search_list$search1$result$status),"\n")
    cat("Processing",nrow(stage_frame),"rows of staging data then sleeping for",time_to_sleep/60,"mins...\n")
    if(nrow(stage_frame)==0) {
      sleep_with_progress(time_to_sleep)
      next
    }
    output <- refine_stage_frame(stage_frame, osm_boundary)
    write_csv(output, "location_output.csv" , append=T)
    cat("...",nrow(output),"rows cached")
    stage_frame <- data.frame()
    sleep_with_progress(time_to_sleep)
    gc(verbose = FALSE)
    next
  }
  
  # if the call was successful and there is data
  stage_frame <- bind_rows(stage_frame,search_out)
  cat("   staged rows:",nrow(stage_frame))
  
  # once stage_frame reaches a certain limit, process and write to disk
  if(nrow(stage_frame)>=stage_frame_cache_limit){
    cat("\n Caching staged data of",nrow(stage_frame),"rows")
    output <- refine_stage_frame(stage_frame, osm_boundary)
    write_csv(output, "location_output.csv" , append=T)
    cat("...",nrow(output),"rows cached")
    stage_frame <- data.frame()
  }
  
  
  
  gc(verbose = FALSE)
  
  
  # }, error=function(e) {
  #   cat("\nThere was a global error:", as.character(e))
  #   sleep_with_progress(time_to_sleep) 
  # }
  # ) #end of tryCatch
  
  
}






