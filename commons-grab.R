library(XML)
library(RCurl)

# Wrapper for XML package, see http://stackoverflow.com/questions/7269006/r-xml-package-how-to-set-the-user-agent
wikixmlParse <- function(url, ...) {
  temp <- tempfile()
  download.file(url, temp, quiet = TRUE)
  xml.out <- xmlParse(temp, ...)
  unlink(temp)
  return(xml.out)
}

# combine category URL creating and listing because we don't need to store
# the URL anywhere
genCategoryXML <- function(category, continue = NULL) {
  api.base <-"http://commons.wikimedia.org/w/api.php?format=xml&action=query&list=categorymembers&cmnamespace=6&cmlimit=500&cmtype=file&cmprop=title"
  url.gen <- paste(api.base, paste("cmtitle", "=", "Category:", category, sep = ""), sep= "&")
  if(is.null(continue)) return(wikixmlParse(url.gen))
  url.gen <- paste(url.gen, paste("cmcontinue", "=", continue, sep = ""), sep = "&")
  return(wikixmlParse(url.gen))
}


enumCat <- function(category) {
  cont <- NULL
  init.xml <- genCategoryXML(category)
  cat.char <- unlist(xpathApply(init.xml, "//cm", xmlGetAttr, "title"))
  # 500 items is the API limit, so we need to keep traversing segments of 
  # the category until there is no more continue parameter
  while (length(getNodeSet(genCategoryXML(category, continue = cont), "//categorymembers")) > 1) {
    cont <- xmlGetAttr(getNodeSet(genCategoryXML(category, continue = cont), "//categorymembers")[[2]], "cmcontinue")
    cat.char <- append(cat.char, unlist(xpathApply(genCategoryXML(category, continue = cont), "//cm", xmlGetAttr, "title")))
  }
  # image titles don't give us URLs, we need another API call for that
  # we set up the urls here (because we want to save them)
  image.api.url <- paste("http://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|size&format=xml",
                         paste("titles", "=", gsub(" ", "_", cat.char), sep = ""),
                         sep = "&")
  return(list(title = cat.char, api = image.api.url))
}

# hiRES indicates that we want all the images. Some commons images are
# enormous (100mb) and we might want to exclude them

fetchFullURL <- function(api.url, hiRES) {
  fin.image.url <- xmlGetAttr(getNodeSet(wikixmlParse(api.url), "//ii")[[1]], "url")
  if (!hiRES) image.size <- xmlGetAttr(getNodeSet(wikixmlParse(api.url), "//ii")[[1]], "size")
  else image.size <- NA
  return(cbind(image.size, fin.image.url))
}

# main function, calls the above functions as needed

getCommonsImg <- function(category, hiRES = FALSE, useragent) {
  # Wikimedia API will reject for blank user agent strings
  options(HTTPUserAgent=useragent)
  cat.out <- enumCat(category)
  # titles and download urls
  fetch.out <- unname(t(sapply(cat.out$api, fetchFullURL, hiRES)))
  # drop everything above 90% of max size
  loRES <- which(as.numeric(fetch.out[, 1]) <= quantile(as.numeric(fetch.out[, 1]), 0.9))
  if (!hiRES) {
    urls.fin <- fetch.out[loRES, 2]
    titles.fin <- cat.out$title[loRES]
  }
  else {
    urls.fin <- fetch.out[, 2]
    titles.fin <- cat.out$title
  }
  dirtitle <-  gsub("_", " ", category)
  filetitles <- file.path(dirtitle, sub("File:", "", titles.fin, fixed = TRUE))
  dir.create(dirtitle)
  file.create(filetitles)
  for (i in seq_along(urls.fin)) {
    writeBin(getBinaryURL(urls.fin[i]), filetitles[i])
  }
}