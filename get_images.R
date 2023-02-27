library(httr)
library(jsonlite)


res = GET("https://api.phylopic.org/images")
img_simp = fromJSON(rawToChar(res$content))

npag = img_simp$totalPages
linkp = "https://api.phylopic.org/images?build=175&page="
links = "https://api.phylopic.org/"
for(i in seq(0, npag-1)){
  imgpag = GET(paste0(linkp, i))

  # images
  imgs = fromJSON(rawToChar(imgpag$content))$`_links`$items$href

  for(img in imgs){
    imgpag2 = GET(paste0(links, img))

    img_spec = fromJSON(rawToChar(imgpag2$content))
    # df for thumbnails
    df = img_spec$`_links`$thumbnailFiles

    img_link = df$href[df$sizes=="128x128"]
  }
}








