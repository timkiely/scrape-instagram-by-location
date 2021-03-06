

# network test
# testing how fast we can hit IG's network before rate limiting

if(!"httr"%in%installed.packages()){
  install.packages("httr")
}
if(!"tidyverse"%in%installed.packages()){
  install.packages("tidyverse")
}

library(httr)
library(tidyverse)


logger <- data.frame()
for(i in 1:101){
  
  tryCatch({
    
    
    
    cat("\ntrial",i)
    out_frame <- data.frame()
    
    trial <- i
    time <- Sys.time()
    run_time <- NA
    status <- NA
    minutes <- NA
    text <- NA
    
    # make the call
    base_url <- "https://www.instagram.com/graphql/query/?query_id=17881432870018455&id=%s&first=%s&after=0"
    location_id <- 242698464
    query_url <- sprintf(base_url,location_id,sample(50:100,1)) # 70 is the max per request. choose random # over 50 to mix up the urls
    
    run_time <- system.time({
      req <- tryCatch(GET(query_url), error = function(e) e)
    })
    
    
    # if the call returns an error:
    if(class(req)!='response'){
      cat("\n network error occured, sleeping for 20 minutes...\n")
      cat("\n error message:",suppressMessages(as.character(req, encoding = "UTF-8")), "\n")
      Sys.sleep(60*20)
    }
    
    
    status <- status_code(req)
    cat("\n  status: ",status)
    cat("\n  elapsed time: ",run_time[3])
    
    
    # if a rate limit is hit:
    if(status_code(req)!=200){
      text <- content(req, "text", encoding = "UTF-8")
      minutes <- 60 * sample(4:6,1)
      out_frame <- tbl_df(data.frame(trial, time, run_time[3], status, minutes, text, stringsAsFactors = F))
      logger <- tbl_df(out_frame)
      write_csv(logger,"logger.csv", append = T)
      cat("\n sleeping for",minutes/60,"minutes...\n")
      Sys.sleep(minutes)
      next
    }
    
    
    out_frame <- tbl_df(data.frame(trial, time, run_time[3], status, minutes, text, stringsAsFactors = F))
    logger <- tbl_df(bind_rows(logger,out_frame))
    write_csv(out_frame,"logger.csv", append = T)
    
  }, error=function(e) cat("There was a global error:", as.character(e))
  ) # end tryCatch
  
}


