# ==========================================================================
# Author: Luan Thanh Nguyen
# Email:  luan@tklarryonline.me
#
# ==========================================================================

# Source the manage.R file to setup project
source("manage.R")
source(file.path("data_handlers", "boundary.R"))
source(file.path("data_handlers", "employments.R"))

run_profiler <- function() {
  boundary <- MelbourneBoundary$new()
  boundary$load_data()

  employments <- MelbourneEmployments$new()
  employments$load_data()

  # Merge boundary's data with employments's
  boundary$shp@data <- merge.data.frame(
    x = boundary$shp@data, y = employments$data, by = "sa2_main11",
    sort = FALSE, all.x = TRUE
  )

  # Export to shapefile
  shapefile_name <- "Melb_Unemploy_JobAvail_FemaleEmployees"
  shapefile_path <- file.path(EXPORTS_DIR, shapefile_name)
  rgdal::writeOGR(
    obj = boundary$shp, dsn = shapefile_path,
    layer = shapefile_name, driver = "ESRI Shapefile",
    overwrite_layer = TRUE
  )

  utils.upload_shp_to_geoserver(shapefile_name = shapefile_name, shapefile_path = shapefile_path)
}

run_profiler()
