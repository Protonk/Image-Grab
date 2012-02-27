library(XML)
library(RCurl)

getimgurURL<- function(url) {
  # Parse out images waiting to be shown in preview gallery 
  # These exist regardless of the size of the album
  thumbs <- getNodeSet(xmlRoot(htmlTreeParse(url)), "//body//img[@class='unloaded thumb-title']")
  # Grab image urls
  thumbs.uri <- mapply(function(x) thumbs[[x]]$attributes[['data-src']], 1:length(thumbs))
  # Thumbnails on imgur are denoted with a trailing "s" in the filename
  url.final <- sub("s.", ".", thumbs.uri, fixed = TRUE)
  # Album title becomes folder title
  dirtitle <- unlist(getNodeSet(xmlRoot(htmlTreeParse(url)), "//head//title"))[[3]]
  if (file.exists(dirtitle)) return(NULL)
  filetitles <- paste(dirtitle, basename(url.final), sep="/")
  dir.create(dirtitle)
  file.create(filetitles)
  #I could vectorize this but the local processor isn't the bottleneck here
  for (i in seq_along(thumbs)) {
  	writeBin(getBinaryURL(url.final[i]), filetitles[i])
  }
}
