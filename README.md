Instagram Metadata Scraper
================

### OPEN QUESTIONS:

-   what is the edge\_location\_to\_media "count" response? When scrapping an entire location page, the end count (where has\_next\_page = FALSE) is usually around half of the full count. Is the scrape failing? Or does the count reflect something else (private accounts?)
-   How to obtain an exhaustive list of location ID's?
-   What are the api call limits? How many calls can you make in a row? What's the reset time? Do IP's ever get blocked? (running network speed test to address this)
-   how to integrate proxy use with httr? 1) Obtain list of proxies 2) build fault tolerance
-   Parallelize network requests? Maybe launch multiple EC2's?

Instagram Scraper:
==================

Unlike other Instagram scraping projects around, the aim of this package is very narrow: \* search for Instagram/Facebook/Foursquare place ID's \* Retrieve the metadata about the posts from that location

This package is not interested in downloading the media (photos/videos) associated with IG posts.

The first function searches for locaiton ID's using whatever text string you're interested in. Let's search for posts around Williamsburg:

``` r
source("search-for-location-ids.R")

possible_locations <- search_for_location_ids(location = "Williamsburg, Brooklyn")

possible_locations
```

    ## # A tibble: 36 x 9
    ##                 pk                                     name
    ##  *           <chr>                                    <chr>
    ##  1       215631076                   Williamsburg, Brooklyn
    ##  2 322718158073985                       Apple Williamsburg
    ##  3       239812273 Retro Fitness of Brooklyn - Williamsburg
    ##  4               0              Willamsburg, Brooklyn 11206
    ##  5       215154722              East Williamsburg, Brooklyn
    ##  6       212950988                       Brooklyn, New York
    ##  7 272829696534567                   Williamsburg, Brooklyn
    ##  8       272829900            Williamsburg Park Brooklyn NY
    ##  9         2489983                   Williamsburg, Virginia
    ## 10        28382340                               16 Handles
    ## # ... with 26 more rows, and 7 more variables: address <chr>, city <chr>,
    ## #   short_name <chr>, lng <dbl>, lat <dbl>, external_source <chr>,
    ## #   facebook_places_id <dbl>

The `pk` collumn contains the relevant location ID's we need to hit instagram's Graphql api. The correct location appears to be `242698464`. We can feed that to the subsequent function `get_posts_from_location` in order to retrieve metadata about the first batch of posts.

``` r
source("scrape-posts-from-location.R")

posts <- get_posts_from_location(location_id = 242698464, after = 0)

posts
```

    ## $has_next_page
    ## [1] TRUE
    ## 
    ## $end_cursor
    ## [1] "1597132779521383087"
    ## 
    ## $media_count
    ## [1] 6298
    ## 
    ## $response_data
    ## # A tibble: 63 x 10
    ##    timestamps                 ids      owner  shortcodes `comment count`
    ##         <int>               <chr>      <chr>       <chr>           <int>
    ##  1 1505608895 1605486240253385215 2013360237 BZH1TqyFJn_               0
    ##  2 1505363874 1603430850500842687 1318717625 BZAh9z6AVS_               4
    ##  3 1505336552 1603201655686369882  178605356 BY_t2lmgRJa               2
    ##  4 1505155316 1601681338474085502  901601165 BY6ULD3Hrx-               0
    ##  5 1505153398 1601665254767884774   16855323 BY6QhAvhnnm               2
    ##  6 1505153235 1601663880663556500   16855323 BY6QNBAhmGU               1
    ##  7 1505153114 1601662868846500606   16855323 BY6P-Srh1r-               0
    ##  8 1505150974 1601644921746825195   25663333 BY6L5IJBx_r               1
    ##  9 1505149809 1601635141284020811 1605349367 BY6JqzYBEJL               1
    ## 10 1505148706 1601625892198483649 1007647573 BY6HkNfjwbB               0
    ## # ... with 53 more rows, and 5 more variables: display_url <chr>,
    ## #   is_video <lgl>, thumbnail_src <chr>, captions <chr>, date_time <dttm>

You can input the `end_cursor` value returned by `get_posts_from_location` to a subsequent call as the `after` parameter. That will ensure the next call will return the next batch of posts.
