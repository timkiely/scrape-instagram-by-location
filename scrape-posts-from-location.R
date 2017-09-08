


suppressPackageStartupMessages({
  library(httr) # making GET requests
  library(jsonlite) # parsing json
  library(tidyverse) # data manip
})


get_posts_from_location <- function(location_id = NULL, after = 0) {
  
  
  # The public facing IG api:
  base_url <- "https://www.instagram.com/graphql/query/?query_id=17881432870018455&id=%s&first=%s&after=%s"
  
  # format the url request
  query_url <- sprintf(base_url,location_id,sample(50:100,1),after) # 70 is the max per request. choose random # over 50 to mix up the urls
  
  # issue the request and check the response status
  req <- GET(query_url)
  if(status_code(req)!=200) stop("The server returned an error. Something went wrong or maybe you hit a call limit")
  
  
  # parse the result to json text
  txt <- content(req, "text", encoding = "UTF-8")
  # view the json:
  ## jsonlite::prettify(txt)
  response <- jsonlite::fromJSON(txt)
  
  # extract values from the json response:
  media_count <- response$data$location$edge_location_to_media$count
  has_next_page <- response$data$location$edge_location_to_media$page_info$has_next_page
  end_cursor <- response$data$location$edge_location_to_media$page_info$end_cursor
  
  # create an output dataframe:
  timestamps <- response$data$location$edge_location_to_media$edges$node$taken_at_timestamp
  ids <- response$data$location$edge_location_to_media$edges$node$id
  owner <- response$data$location$edge_location_to_media$edges$node$owner
  shortcodes <- response$data$location$edge_location_to_media$edges$node$shortcode
  comment_count <- response$data$location$edge_location_to_media$edges$node$edge_media_to_comment
  display_url <- response$data$location$edge_location_to_media$edges$node$display_url
  is_video <- response$data$location$edge_location_to_media$edges$node$is_video
  thumbnail_src <- response$data$location$edge_location_to_media$edges$node$thumbnail_src
  
  # captions are sometimes NULL
  captions <- response$data$location$edge_location_to_media$edges$node$edge_media_to_caption$edges %>%
    map(1) %>% map(.f = function(x) ifelse(is.null(x),NA,x)) %>% unlist() %>% as_tibble()
  if(nrow(captions)!=length(timestamps)) captions <- rep(NA,length(timestamps))
  
  # output data:
  response_df <- 
    bind_cols(
      list("timestamps"=timestamps, "ids"=ids
           ,"owner" = owner$id,"shortcodes" = shortcodes
           ,"comment count" = comment_count$count
           ,"display_url" = display_url,"is_video" = is_video
           ,"thumbnail_src" = thumbnail_src
           ,"captions" = captions$value)
    ) %>% 
    mutate(date_time = as.POSIXct(timestamps, origin="1970-01-01"))
  
  # return a list of values and data:
  list(
    "has_next_page" = has_next_page
    , "end_cursor" = end_cursor
    , "media_count" = media_count
    , "response_data" = response_df
  )
}

# with profiling, the GET requests take up 90%+ of the time, so the remaining funtion is farily optimized
posts <- get_posts_from_location(location_id = 242698464)

