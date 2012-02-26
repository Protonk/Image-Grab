library(rjson)

# Enumerate categories from the Mediawiki API

# Images on commons are in ns = 6 eventually I may just remove the arg

# 3 subordinate functions and one main routine 
# genCompCat, fetchfullURL both lead into
# fetchCommonsCat, which generates a list of flat URLs for 
# pictures on Commons. 


# Continue argument is added for categories w/ greater than 500 members

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
  # API requires underscores instead of spaces
  gsub(" ", "_", cat.unform)
}

# the iiprop parameters are doing the real work here. 
# hiRES flag is there because some Commons images are
# LARGE and you may not want to d/l them in a cat accidentally

# if hiRES is false then the top 10% of pics in size are dropped
# This doesn't actually occur in this function (which works 1 input at a time)

# This can fail for some image URLs which show up as redirects but don't have a redirect target.

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

# Default values set in this function only temporarily. 

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


  

