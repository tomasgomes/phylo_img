library(httr)
library(jsonlite)

library(taxize)


ekey = "24245f677350f2e5b323a147e20bca253708"
Sys.setenv(ENTREZ_KEY=ekey)


res = GET("https://api.phylopic.org/images")
img_simp = fromJSON(rawToChar(res$content))

npag = img_simp$totalPages
linkp = "https://api.phylopic.org/images?build=175&page="
links = "https://api.phylopic.org"
for(i in seq(0, npag-1)){
  cat(i, sep = " ")
  imgpag = GET(paste0(linkp, i))

  # images
  imgs = fromJSON(rawToChar(imgpag$content))$`_links`$items$href

  for(img in imgs){
    imgpag2 = GET(paste0(links, img))

    img_spec = fromJSON(rawToChar(imgpag2$content))
    # df for thumbnails
    df = img_spec$`_links`$thumbnailFiles

    img_link = df$href[df$sizes=="128x128"]
    name_img = strsplit(img_spec$`_links`$self$href, "/")[[1]][3]
    name_img = strsplit(name_img, "?", fixed = T)[[1]][1]

    # download image
    img_file = paste0("data/imgs/",name_img, ".png")
    if(!file.exists(img_file)){
      curl::curl_download(img_link, img_file)
    }


    # get parent taxa
    taxa_file = paste0("data/csvs/",name_img, ".csv")
    if(!file.exists(taxa_file)){
      n = img_spec$`_links`$specificNode$href
      nod = GET(paste0(links, n))
      nod_spec = fromJSON(rawToChar(nod$content))

      taxon = nod_spec$names[[1]][1,"text"]
      taxa = taxize::tax_name(taxon,
                              get = c("kingdom", "phylum", "class",
                                      "order", "family", "genus", "species"),
                              db = "ncbi", messages = F, key = ekey)[,-c(1)]
      taxa$img_name = name_img

      write.csv(taxa, file = taxa_file, quote = F, row.names = F)
    }
  }
}





