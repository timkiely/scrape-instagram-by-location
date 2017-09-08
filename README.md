Instagram Metadata Scraper
================

Unlike other Instagram scraping projects around, the aim of this package is very narrow: \* search for Instagram/Facebook/Foursquare place ID's \* Retrieve the metadata about the posts from that location

This package is not interested in downloading the media associated with IG posts.

The first function searches for locaiton ID's using whatever text string you're interested in. Let's search for posts around Williamsburg:

``` r
source("search-for-location-ids.R")

possible_locations <- search_for_location_ids(location = "Williamsburg, New York")

possible_locations
```

    ## # A tibble: 34 x 9
    ##           pk                                           name
    ##  *     <chr>                                          <chr>
    ##  1 215154722                    East Williamsburg, Brooklyn
    ##  2 266259396                   Williamsboro, North Carolina
    ##  3 242698464                Williamsburg, Brookyn, New York
    ##  4   3001685                            Williamsburg Bridge
    ##  5  28382340                                     16 Handles
    ##  6 588528900 Mccarren Park, Brooklyn, New York/williamsburg
    ##  7 370276659 Herbert Street, Williamsburg Brooklyn New York
    ##  8  45885529                           Williamsburg Cinemas
    ##  9    761202                               New York Muffins
    ## 10 252122976         Williamsburg, Brooklyn, New York 11211
    ## # ... with 24 more rows, and 7 more variables: address <chr>, city <chr>,
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
    ## [1] "1593493450299627907"
    ## 
    ## $media_count
    ## [1] 6240
    ## 
    ## $response_data
    ## # A tibble: 69 x 10
    ##    timestamps                 ids      owner  shortcodes `comment count`
    ##         <int>               <chr>      <chr>       <chr>           <int>
    ##  1 1504890369 1599458801379318777   16220420 BYya045Fhv5               0
    ##  2 1504886495 1599426307685399538 4186034860 BYyTcCyALvy               1
    ##  3 1504883963 1599405070180740091   51931073 BYyOm_0FOv7              11
    ##  4 1504846407 1599090023936225656    8091750 BYxG-eIlvF4               0
    ##  5 1504818851 1598858867998333706 6005440803 BYwSatZBhsK               0
    ##  6 1504810104 1598785494295236270   13449622 BYwBu-zg86u               0
    ##  7 1504801575 1598713948830823487   26483531 BYvxd25hfQ_              24
    ##  8 1504796148 1598668421708897789 2095946343 BYvnHWdl939               2
    ##  9 1504789493 1598612596561769378 1462817340 BYvaa_Ph3Oi               1
    ## 10 1504752221 1598299934485003480   32775429 BYuTVJ_gjzY               1
    ## # ... with 59 more rows, and 5 more variables: display_url <chr>,
    ## #   is_video <lgl>, thumbnail_src <chr>, captions <chr>, date_time <dttm>

You can input the `end_cursor` value returned by `get_posts_from_location` to a subsequent call as the `after` parameter. That will ensure the next call will return the next batch of posts.
