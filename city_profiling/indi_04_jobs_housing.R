# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

source("manage.R")

source(file.path("data_handlers", "boundary.R"))
source(file.path("data_handlers", "employments.R"))
source(file.path("data_handlers", "dwelling_housing.R"))

library(dplyr)

calculate_profiler <- function() {
  # Reads boundary data
  boundary <- MelbourneBoundary$new()
  boundary$load_data()
  boundary <- boundary$shp

  # Reads employment data
  employments <- MelbourneEmployments$new()
  employments$load_data()
  employments <- employments$data

  # Reads housing data
  housing <- MelbourneDwellingHousing$new()
  housing$load_data()
  housing <- housing$data

  # Merges with employments to have the total employees
  housing <- dplyr::left_join(x = housing, y = employments, by = "sa2_code11")

  # Calculates the indicator: total employees / total houses
  housing$jobsphouse <- housing$total_employees / housing$ttl_houses
  housing$jobsphouse[housing$ttl_houses == 0] <- 0

  # Now we need only the jobsphouse ratio
  housing <- housing[c("sa2_code11", "jobsphouse")]

  # Merges into boundary to get the geom data
  boundary@data <- dplyr::left_join(x = boundary@data, y = housing, by = "sa2_code11")

  return(boundary)
}

run_profiler <- function() {
  shp <- calculate_profiller()

  # Exports to shapefile
  shapefile_name <- "Melb_Jobs_per_House_ratio"
  shapefile_path <- file.path(EXPORTS_DIR, shapefile_name)
  rgdal::writeOGR(
    obj = shp, dsn = shapefile_path,
    layer = shapefile_name, driver = "ESRI Shapefile",
    overwrite_layer = TRUE
  )

  utils.upload_shp_to_geoserver(shapefile_name = shapefile_name, shapefile_path = shapefile_path)
}

run_profiler()
