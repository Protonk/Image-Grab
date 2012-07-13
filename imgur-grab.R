library(XML)
library(RCurl)

getimgurURL<- function(url) {
  preparse <- htmlParse(url)
  # Some galleries use different containers
  if (xpathApply(preparse, "//body//div[@id='content']", xmlAttrs)[[1]][2] %in% "outside album") container <- "//body//img[@class='unloaded thumb-title-embed']"
  else container <- "//body//img[@class='unloaded thumb-title']"
  # Grab image urls. Walks through list of image divs
  thumbs.uri <- unlist(xpathApply(preparse, container, xmlGetAttr, "data-src"))
  # Thumbnails on imgur are denoted with a trailing "s" in the filename
  url.final <- sub("s.", ".", thumbs.uri, fixed = TRUE)
  # Album title becomes folder title
  dirtitle <- gsub("/", replacement = "-", (gsub("\n|\t", replacement = "", xpathApply(preparse, "//head//title", xmlValue)[[1]]))
  if (file.exists(dirtitle)) return(NULL)
  filetitles <- file.path(dirtitle, basename(url.final))
  dir.create(dirtitle)
  file.create(filetitles)
  for (i in seq_along(url.final)) {
  	writeBin(getBinaryURL(url.final[i]), filetitles[i])
  }
}