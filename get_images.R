library(httr)
library(jsonlite)

library(taxize)

library(Matrix)


ekey = "24245f677350f2e5b323a147e20bca253708"
Sys.setenv(ENTREZ_KEY=ekey)


res = GET("https://api.phylopic.org/images")
img_simp = fromJSON(rawToChar(res$content))

npag = img_simp$totalPages
linkp = "https://api.phylopic.org/images?build=175&page="
links = "https://api.phylopic.org"

# WARNING: this takes very long,
## will occasionally ask for used prompts, and may need to be restarted several times

ii = 0

for(i in seq(ii, npag-1)){
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
  ii = i
}

# make unique taxa table
tabs = list.files("data/csvs/", full.names = T)
tab = lapply(tabs, function(f) read.csv(f, header = T))
all_tab = reshape2::melt(tab)[,-c(10,11)]
all_tab$hasTaxa = apply(all_tab[,2:8], 1, function(x) any(!is.na(x)))
write.csv(all_tab, file = "data/all_taxa.csv", quote = F, row.names = F)

# save images as a raw data matrix
res_mat = matrix(0, length(all_tab$img_name), 128*128)
rownames(res_mat) = all_tab$img_name
for(img in all_tab$img_name){
  imgmat = readPNG(paste0("data/imgs/", img, ".png"))[,,2]
  res_mat[img,] = as.vector(imgmat)
}

#grid::grid.raster(matrix(res_mat[234,], 128, 128))

res_mat = as(res_mat, "sparseMatrix")
Matrix::writeMM(res_mat, "data/all_img_flat.mtx")

