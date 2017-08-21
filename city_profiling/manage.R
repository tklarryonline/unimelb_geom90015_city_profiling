# Author: Luan Thanh Nguyen
# Email:  luan@tklarryonline.me
#
# The purpose of this file is to install/init all the required packages
# And source the correct util files

constants.REQUIRE_PACKAGES <- c(
  # Required ones for Dr. Ben's utils work
  "maptools",
  "rgdal",
  "rgeos",
  "geojsonio",
  "RCurl",
  "uuid",
  "jsonlite",
  "XML",

  # Local ones
  "doParallel",
  "igraph"
)

utils.install.package <- function(package) {
  if (!require(package)) {
    install.packages(package)
  }
}

for (package in constants.REQUIRE_PACKAGES) {
  utils.install.package(package)
}

# Loads the file from Dr. Ben
source(file.path(getwd(), "utils", "rgs_utils.R"))
source(file.path(getwd(), "utils", "custom_utils.R"))

# Loads left packages
library(doParallel)
library(igraph)

# Set number of cores
constants.CORES = 1
registerDoParallel(cores = constants.CORES)
