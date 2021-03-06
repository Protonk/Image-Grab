library(XML)
library(RCurl)

getimgurURL<- function(url, destdir) {
  preparse <- htmlParse(url)
  # Album title becomes folder title
  dirtitle <- gsub("\n|\t|(\\s{2}|\\s+$)+", 
                   "", 
                   xpathSApply(preparse, "//head//title", xmlValue))
  dirtitle <- paste(gsub("/", "-", dirtitle), basename(url))
  # set up directory, bail out if the file exists
  dirtitle <- file.path(destdir, dirtitle)
  if (file.exists(dirtitle)) {
    return(NULL)
  }
  # Some galleries use different containers
  container <- ifelse("outside album" %in% xpathSApply(preparse, "//body//div[@id='content']", xmlAttrs),
                      "//body//img[@class='unloaded thumb-title-embed']",
                      "//body//img[@class='unloaded thumb-title']")

  # Grab image urls. Walks through list of image divs
  thumbs.uri <- xpathSApply(preparse, container, xmlGetAttr, "data-src")
  # Thumbnails on imgur are denoted with a trailing "s" in the filename
  thumbs.uri <- sub("s.", ".", thumbs.uri, fixed = TRUE)
  
  filetitles <- file.path(dirtitle, basename(thumbs.uri))
  dir.create(dirtitle)
  file.create(filetitles)
  for (i in seq_along(thumbs.uri)) {
  	writeBin(getBinaryURL(thumbs.uri[i]), filetitles[i])
  }
}