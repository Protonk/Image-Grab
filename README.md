## Image Downloading software

Made mostly to scratch an itch. There are plenty of browser addons, python libraries and the like to download images from various sites, but I'm more comfortable in R. So here we have it!

### So far

Scripts to be added for different services as needed.

#### imgur-grab.R

- Does what it says on the tin. Imgur only loads a certain number of thumbnails for large galleries, but the links to the remainder are in the page source. Simple, requires the XML library.

##### getimgur-script

- Sample shell script accepting urls as arguments on the command line. Some minimal checking for duplicate file names done. 
- Not intended to be plug and play and may be removed in the future. But the basic structure is there. 


#### commons-grab.R

- Less simple. Grabs categories from MediaWiki Commons and downloads files in those categories. Uses XML to manage API calls. 
 
#### flickr-grab.R

- Also a bit less simple. Requires an API key because I figured scraping flickr would be laborious and uncool. 


### Rough edges

These R scripts create files and directories in the working directory for R. If the category or album names are duplicated, this may result in files being written to the wrong place. More of a problem with imgur as categories on wikipedia by definition have distinct names. 

### License and such

I make no promises that these scripts will work for you. However, if you do load up R and try them out, let me know if they work or not. Possibly through email or preferably through a pull request fixing the problem! :)

The code here is free for any use provided attribution is maintained. See [CC-BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).