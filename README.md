## Image Downloading software

Made mostly to scratch an itch. There are plenty of browser addons, python libraries and the like to download images from various sites, but I'm more comfortable in R. So her we have it!

### So far

Scripts to be added for different services as needed.

#### imgur-grab.R

- Does what it says on the tin. Imgure only loads a certain number of thumbnails for large galleries, but the links to the remainder are in the page source. Simple, requires the XML library.

#### commons-grab.R

- Less simple. Not done yet. Grabs categories from Wikimedia Commons. Uses rjson. Mediawiki API provides the full resolution URL if you ask nicely, so no fiddling about w/ XML.

### License and such

I make no promises that these scripts will work for you. However, if you do load up R and try them out, let me know if they work or not. Possibly through email or preferably through a pull request fixing the problem! :)

The code here is free for any use provided attribution is maintained. See [CC-BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).