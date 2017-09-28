
# combining open address with OSM to create a thorough list of potential locations to scrape

library(stringr)
library(tidyverse)


# NYC boros from https://www1.nyc.gov/site/planning/data-maps/open-data/bytes-archive.page
nycboros <- read_sf("data/nybbwi_17b") %>% st_transform(crs = 4326) %>% dplyr::count() %>% st_convex_hull()

# OSM place data from: https://mapzen.com/data/metro-extracts/metro/new-york_new-york/
if(!exists("osm_points")){
  osm_points <- read_sf("data/new-york_new-york.osm2pgsql-geojson/new-york_new-york_osm_point.geojson") %>% select(osm_id,name,geometry)
  osm_places <- osm_points %>% filter(!is.na(name))
  # filter for just the boros
  osm_places <- suppressWarnings(st_intersection(nycboros,osm_places) %>% tbl_df() %>% select(-geometry, -n))
  st_geometry(osm_places) <- NULL
}

# OpenAddress data from: http://results.openaddresses.io/?runs=all#runs
if(!exists("open_addresses")){
  open_addresses <- read_csv("data/city_of_new_york.csv") %>% st_as_sf(coords = c("LON","LAT"), crs = 4326)
  # filter for just the boros
  
  # standardize the street names, e.g., 236 to 236th
  open_addresses <- 
    open_addresses %>% 
    mutate(STREET = str_replace(STREET,"  "," ")) %>% 
    mutate(STREET = str_replace(STREET,"(\\d{1,10})","\\1th") # \\d digit 1-10 times, replace with same \\1 plus "ith"
           , STREET = str_replace(STREET,"1th","1st")
           , STREET = str_replace(STREET,"2th","2nd")
           , STREET = str_replace(STREET,"3th","3rd")
           , STREET = str_replace(STREET,"11st","11th")
           , STREET = str_replace(STREET,"12nd","12th")
           , STREET = str_replace(STREET,"13rd","13th")
    )
  
  open_addresses <- 
    suppressWarnings(st_intersection(nycboros,open_addresses) %>% 
                                       tbl_df() %>% 
                                       select(-geometry, -HASH, -ID, -n) %>% 
                                       mutate(Address = gsub("  "," ",paste(NUMBER,STREET, sep = " ")))
                                     )
  
  
}


# combine and write out
all_search_terms <- 
  bind_rows(list("OA" = select(tbl_df(open_addresses),"Search_Term" = Address)
                 ,"OSM" = select(as_data_frame(osm_places), "Search_Term" = name)
                 ),.id = "Source")


write_rds(all_search_terms, 'data/all_search_terms.rds', compress = 'gz')

# file uploaded to S3 at: https://s3-us-west-2.amazonaws.com/project.data.dl/instagram/all_search_terms.rds


