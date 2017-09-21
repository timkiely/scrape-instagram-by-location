
source("search-for-location-ids.R")
source("scrape-posts-from-location.R")




location <- 242698464
end_cursor <- 0
iter <- 1

df_out <- data.frame()
has_next_page <- TRUE
while(has_next_page == TRUE){
  cat("iteration",iter,": ")
  batch <- get_posts_from_location(location_id = location, after = end_cursor)
  
  df_out <- tbl_df(bind_rows(df_out,batch$response_data))
  cat(nrow(df_out), "records of",batch$media_count)
  cat(" date range:",paste(range(df_out$date_time),collapse = " "),"\n")
  
  end_cursor <- batch$end_cursor
  has_next_page <- batch$has_next_page
  iter <- iter+1
}


range(df_out$date_time)
