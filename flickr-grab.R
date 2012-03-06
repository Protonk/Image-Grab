library(XML)
library(RCurl)

# API key. Yours will be different

flickr_API <- "I AM AN API KEY, FEED ME DIGITS"

### Meant to be called progressively, gallery, then photos, then size
# gallery: accepts url, returns "secret" gallery id
# photos: accepts gallery id, returns character vector of member photo ids
# size: accepts photo ids, returns the largest size

APIresultGen <- function(input, method = c("gallery", "photos", "size")) {
	stripPath <- function(input) {
		# Shamelessly cargo-culted from http://stat.ethz.ch/R-manual/R-devel/library/base/html/grep.html
		url.comp.list <- regexec("^(([^:]+)://)?([^:/]+)(:([0-9]+))?(/.*)", input)
		# 7th component is the path
		unlist(regmatches(input, url.comp.list))[7]
	}
  # Generate the API call url (simple REST api)
  
	api.base <- "http://api.flickr.com/services/rest/?"
	method.value <- switch(match.arg(method),
						   gallery = paste("method=flickr.urls.lookupGallery&url", stripPath(input), sep = "="),
						   photos = paste("method=flickr.galleries.getPhotos&gallery_id", input, sep = "="),
						   size = paste("method=flickr.photos.getSizes&photo_id", input, sep = "=")
						   )
	init.api.url <- paste(api.base, method.value,
						      paste("api_key", flickr_API, sep = "="),
						      "format=xmlrpc",
			   			    sep = "&"
			   			    )
  
	# Almost all API calls return the results in "<string>" The two lines here are ugly but
	# XML is stored as links to larger documents so for now this is a more flexible 
	# subsetting method. 
	unform <- xpathApply(xmlParse(init.api.url), "//string", xmlValue)[[1]]
	block.out <- xmlRoot(htmlParse(gsub(pattern = "*(\n)|*(\t)|*(\")", replacement = "", x = unform)))
	# Thankfully we can just use xpathApply to pull out what we want.
	# everything except photo returns a length 1 character vector
	switch(match.arg(method),
		   gallery = unlist(xpathApply(block.out, "//gallery", xmlGetAttr, "id")),
		   photos = unlist(xpathApply(block.out, "//photo", xmlGetAttr, "id")),
		   size = tail(unlist(xpathApply(block.out, "//size", xmlGetAttr, "source")),1)
		   )
	}

# Yay! 4 lines of code to get one string.  
# Because I'm too lazy to put this in the function above
titleGen <- function(url.input) {
  title.api.url <-  paste("http://api.flickr.com/services/rest/?method=flickr.galleries.getInfo",
                          paste("api_key", flickr_API, sep = "="),
                          paste("gallery_id", APIresultGen(input = url.input, method = "gallery"), sep = "="),
                          "format=xmlrpc",
                          sep = "&"
                          )
  # Same code as above. This is a little frustrating as I can't just pick it out yet
  # but I'll come back to it.
  unform <- xpathApply(xmlParse(title.api.url), "//string", xmlValue)[[1]]
  block.out <- xmlRoot(htmlParse(gsub(pattern = "*(\n)|*(\t)|*(\")", replacement = "", x = unform)))
  gsub("*(\n)|*(\t)", replacement = "", xpathApply(block.out, "//title", xmlValue))
}

# Main function

getFlickr <- function(url.input) {
	photos.out <- APIresultGen(input = APIresultGen(input = url.input, method = "gallery"), method = "photos")
	full.urls <- unlist(lapply(photos.out, APIresultGen, method = "size"))
	dirtitle <- titleGen(url.input)
  # some larger file sizes have querystrings
  filetitles <- file.path(dirtitle, sub("[^jpg]*$", "", basename(full.urls)))
	dir.create(dirtitle)
	file.create(filetitles)
	for (i in seq_along(full.urls)) {
	  writeBin(getBinaryURL(full.urls[i]), filetitles[i])
	}
}
	



