library(rjson)

# Enumerate categories from the Mediawiki API

# Images on commons are in ns = 6

genCompCat <- function(category, namespace) {
  genCategoryURL <- function(category, namespace, continue = NULL) {
    url.start <-paste(
      "http://commons.wikimedia.org/w/api.php?", 
      "action=query",
      "list=categorymembers",
      paste("cmtitle", "=", "Category:", category, sep = ""),
      paste("cmnamespace", "=", namespace, sep = ""),
      "cmlimit=500",
      "cmtype=file",
      "cmprop=title",
      "format=json",
      sep = "&")
    if (is.null(continue)) url.gen <- url.start
    else url.gen <- paste(url.start, paste("cmcontinue", "=", continue, sep = ""), sep = "&")  
  }
  cat.list.init <- fromJSON(file = genCategoryURL(category, namespace))
  cat.unform <- unlist(cat.list.init$query$categorymembers)[names(unlist(cat.list.init$query$categorymembers)) == "title"]
  while (!is.null(cat.list.init$`query-continue`)) {
    cat.list.init <- fromJSON(file = genCategoryURL(category, namespace, continue = unlist(cat.list.init$`query-continue`)[[1]]))
    cat.unform <- append(cat.unform, unlist(cat.list.init$query$categorymembers)[names(unlist(cat.list.init$query$categorymembers)) == "title"])
  }
  gsub(" ", "_", cat.unform)
}


fetchfullURL <- function(baseurl, hiRES) {
  url.gen <- paste(
    "http://commons.wikimedia.org/w/api.php?", 
    "action=query",
    paste("titles", "=", baseurl, sep = ""),
    "prop=imageinfo",
    "iiprop=url|size",
    "format=json",
    sep = "&")
  if (hiRES) {
    pageJSON <- fromJSON(file = gsub("|size", "", url.gen))
    unname(unlist(pageJSON$query$pages)[grep("imageinfo.url", names(unlist(pageJSON$query$pages)))])
  } 
  else {
    pageJSON <- fromJSON(file = url.gen)
    list(url = unname(unlist(pageJSON$query$pages)[grep("imageinfo.url", names(unlist(pageJSON$query$pages)))]), 
         size = as.numeric(unname(unlist(pageJSON$query$pages)[grep("imageinfo.size", names(unlist(pageJSON$query$pages)))]))
         )
  }
}


fetchCommonsCat <- function(category, namespace = 6, useragent, hiRES = FALSE) {
  # Mediawiki requires an informative user agent. Yours should be distinct
  options(HTTPUserAgent= useragent )
  cat.final <- genCompCat(category, namespace)
  resolved.URL <- character()
  if (hiRES) {  
    for (i in 1:length(cat.final)) {
      resolved.URL[i] <- fetchfullURL(cat.final[i], hiRES = TRUE)
    }
  }  
  else {
    size.pic <- numeric()
    for (i in 1:length(cat.final)) {
      resolved.URL[i] <- fetchfullURL(cat.final[i], hiRES = FALSE)$url
      size.pic[i] <- fetchfullURL(cat.final[i], hiRES = FALSE)$size
    }
    resolved.URL <- resolved.URL[which(size.pic <= quantile(size.pic, 0.9))]
  }
  closeAllConnections()
  return(resolved.URL)
}


  

