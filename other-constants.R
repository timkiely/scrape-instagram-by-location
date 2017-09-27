
BASE_URL = 'https://www.instagram.com/'
LOGIN_URL = paste0(BASE_URL,'accounts/login/ajax/')
LOGOUT_URL = paste0(BASE_URL,'accounts/logout/')
MEDIA_URL = paste0(BASE_URL,'{0}/media')
CHROME_WIN_UA = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36'


TAGS_URL = paste0(BASE_URL,'explore/tags/{0}/?__a=1')
LOCATIONS_URL = paste0(BASE_URL,'explore/locations/{0}/?__a=1')
VIEW_MEDIA_URL = paste0(BASE_URL,'p/{0}/?__a=1')

# search for locations, users or hashtags:
SEARCH_URL = paste0(BASE_URL,'web/search/topsearch/?context=blended&query={0}')

QUERY_COMMENTS = paste0(BASE_URL,'graphql/query/?query_id=17852405266163336&shortcode={0}&first=100&after={1}')
QUERY_HASHTAG = paste0(BASE_URL,'graphql/query/?query_id=17882293912014529&tag_name={0}&first=100&after={1}')
QUERY_LOCATION = paste0(BASE_URL,'graphql/query/?query_id=17881432870018455&id={0}&first=100&after={1}')




library(httr)
# you can search for users, places and hashtags with web/search:
r <- GET("https://www.instagram.com/web/search/topsearch/?context=blended&query=Avenue+of+the+Americas")

# change context = blended to context=place to limit to only places. Note that users and hashtags are returned empty
r <- GET("https://www.instagram.com/web/search/topsearch/?context=place&query=Avenue+of+the+Americas")


url <- "https://www.instagram.com/graphql/query/?query_id=17881432870018455&id=215925971&first=80055&after=1598734273137100062"
r <- GET(url)
(cont <- content(r))

(r <- GET("https://www.instagram.com/web/search/p"))
content(r)

"https://api.instagram.com/v1/locations/search?lat=48.858844&lng=2.294351&access_token=ACCESS-TOKEN"


'https://www.instagram.com/query/'




