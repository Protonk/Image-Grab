library(rjson)

# main function downloads images into a directory similar to imgur downloader

commonsDL <- function(category, useragent, hiRES = FALSE) {

  # 3 subordinate functions:
  #   genCompCat, fetchfullURL both lead into
  #   fetchCommonsCat, which generates a list of flat URLs for 
  #   pictures on Commons.
  genCompCat <- function(category) {
    # Continue argument is added for categories w/ greater than 500 members
    genCategoryURL <- function(category, continue = NULL) {
      url.start <-paste(
        "http://commons.wikimedia.org/w/api.php?", 
        "action=query",
        "list=categorymembers",
        paste("cmtitle", "=", "Category:", category, sep = ""),
        # Images on commons are in ns = 6
        "cmnamespace=6",
        "cmlimit=500",
        "cmtype=file",
        "cmprop=title",
        "format=json",
        sep = "&")
      if (is.null(continue)) url.gen <- url.start
      else url.gen <- paste(url.start, paste("cmcontinue", "=", continue, sep = ""), sep = "&")  
    }
    cat.list.init <- fromJSON(file = genCategoryURL(category))
    cat.unform <- unlist(cat.list.init$query$categorymembers)[names(unlist(cat.list.init$query$categorymembers)) == "title"]
    while (!is.null(cat.list.init$`query-continue`)) {
      cat.list.init <- fromJSON(file = genCategoryURL(category, continue = unlist(cat.list.init$`query-continue`)[[1]]))
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
      pageJSON <- fromJSON(file = sub("|size", "", url.gen))
      unname(unlist(pageJSON$query$pages)[grep("imageinfo.url", names(unlist(pageJSON$query$pages)))])
    } 
    else {
      pageJSON <- fromJSON(file = url.gen)
      cbind(unname(unlist(pageJSON$query$pages)[grep("imageinfo.url", names(unlist(pageJSON$query$pages)))]), 
            unname(unlist(pageJSON$query$pages)[grep("imageinfo.size", names(unlist(pageJSON$query$pages)))])
           )
    }
  }
  
  # Default values set in this function only temporarily. 
  
  fetchCommonsCat <- function(category, useragent, hiRES) {
    # Mediawiki requires an informative user agent. Yours should be distinct
    options(HTTPUserAgent= useragent )
    cat.final <- genCompCat(category)
    # we return a list to make generating filenames easier
    if (hiRES) {  
        resolved.URL <- sapply(cat.final, fetchfullURL, hiRES = hiRES)
        return( list( target = unname(resolved.URL),
                      name = cat.final)
                    )
    }  
    else {
      # pay attention to the dimensions when this is fed through sapply()
      comb.res <- sapply(cat.final, fetchfullURL, hiRES = hiRES)
      resolved.URL <- comb.res[1, ]
      size.pic <- as.numeric(comb.res[2, ])
      resolved.URL <- resolved.URL[which(size.pic <= quantile(size.pic, 0.9))]
      return( list( target = unname(resolved.URL),
                    name = cat.final[which(size.pic <= quantile(size.pic, 0.9))])
                  )
    }
  }
final.list <- fetchCommonsCat(category, useragent, hiRES)
# Remove those pesky underscores
dirtitle <-  gsub("_", " ", category)
filetitles <- paste(dirtitle, sub("File:", "", gsub("_", " ",final.list$name), fixed = TRUE), sep="/")
dir.create(dirtitle)
file.create(filetitles)
for (i in seq_along(final.list$name)) {writeBin(getBinaryURL(final.list$target[i]), filetitles[i])}
}  

  



  

