# Author: Luan Thanh Nguyen
# Email:  luan@tklarryonline.me
#
# The purpose of this file is to install/init all the required packages
# And source the correct util files

#
# Installs the important packages
# --------------------------------------------------------------------------
REQUIRE_PACKAGES <- c(
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

uninstalled_packages <- REQUIRE_PACKAGES[!(REQUIRE_PACKAGES %in% installed.packages())]
if (length(uninstalled_packages) > 0) {
  install.packages(uninstalled_packages)
}

# Loads the packages I need
library(doParallel)
library(igraph)

#
# Sets up the working environment
# --------------------------------------------------------------------------
readRenviron(".Renviron")

# Set number of cores
CORES <- 4
registerDoParallel(cores = CORES)

# Reads env variables
GEOSERVER_CREDENTIALS <- list(
  URL = Sys.getenv("GEOSERVER_URL"),
  USERNAME = Sys.getenv("GEOSERVER_USERNAME"),
  PASSWORD = Sys.getenv("GEOSERVER_PASSWORD"),
  WORKSPACE = Sys.getenv("GEOSERVER_WORKSPACE"),
  DATASTORE = Sys.getenv("GEOSERVER_DATASTORE")
)

TEMP_DIR <- file.path(getwd(), "tempdata")
EXPORTS_DIR <- file.path(getwd(), "exports")

#
# Loads necessary utilities
# --------------------------------------------------------------------------
# Loads the file from Dr. Ben
source(file.path(getwd(), "utils", "rgs_utils.R"))

# And my file
source(file.path(getwd(), "utils", "custom_utils.R"))
