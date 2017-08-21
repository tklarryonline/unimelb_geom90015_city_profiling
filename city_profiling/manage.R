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
CORES <- 1
registerDoParallel(cores = CORES)

# Reads env variables
GEOSERVER_CREDENTIALS <- list(
  URL = Sys.env("GEOSERVER_URL"),
  USERNAME = Sys.env("GEOSERVER_USERNAME"),
  PASSWORD = Sys.env("GEOSERVER_PASSWORD"),
  WORKSPACE = Sys.env("GEOSERVER_WORKSPACE"),
  DATASTORE = Sys.env("GEOSERVER_DATASTORE")
)

TEMP_DIR <- file.path(getwd(), "tempdata")
EXPORTS_DIR <- file.path(getwd(), "exports")
