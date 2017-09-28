
# download the necessary data
if(!dir.exists("data")){
  dir.create("data")
}

if(!file.exists('data/all_search_terms.rds')){
  download.file("https://s3-us-west-2.amazonaws.com/project.data.dl/instagram/all_search_terms.rds"
                ,destfile = 'data/all_search_terms.rds')
}

# nyc boundaries with water included:
if(!dir.exists("data/nybbwi_17b")){
  download.file("https://www1.nyc.gov/assets/planning/download/zip/data-maps/open-data/nybbwi_17b.zip"
                ,destfile = "data/nybbwi_17b")
}

# OSM extract from MapZen
if(!dir.exists('data/new-york_new-york.osm2pgsql-geojson')){
  dir.create("data/new-york_new-york.osm2pgsql-geojson")
  download.file("https://s3.amazonaws.com/metro-extracts.mapzen.com/new-york_new-york.osm2pgsql-geojson.zip"
                , destfile = "data/new-york_new-york.osm2pgsql-geojson.zip")
  unzip("data/new-york_new-york.osm2pgsql-geojson.zip"
        ,exdir = "data/new-york_new-york.osm2pgsql-geojson")
  file.remove("data/new-york_new-york.osm2pgsql-geojson.zip")
}
