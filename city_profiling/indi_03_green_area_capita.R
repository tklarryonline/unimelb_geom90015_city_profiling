# Author: Luan Thanh Nguyen
# Email: l.nguyen50@student.unimelb.edu.au

# Source manage.R to setup
source("./manage.R")

source(file.path("data_handlers", "boundary.R"))
source(file.path("data_handlers", "green_area.R"))
source(file.path("data_handlers", "population.R"))

library(sp)

calculate_profiller <- function() {
  # Reads boundary data
  boundary <- MelbourneBoundary$new()
  boundary$load_data()

  # Converts boundary to UTM
  boundary <- boundary$get_utm_data()

  # Reads green area data
  green_area <- VictoriaGreenAreas$new()
  green_area$load_data()
  green_area <- green_area$shp

  # Assigns unique IDs to the boundary and green area
  boundary@data$id_bound <- as.numeric(1:nrow(boundary@data))
  green_area@data$id_green <- as.numeric(1:nrow(green_area@data))

  # Make a temp data containing boundaries on top of green areas
  green_bound <- sp::over(green_area, boundary)

  # Since the order stays, each row can be assign the ID like above
  green_bound$id_green <- as.numeric(1:nrow(green_bound))

  # Now, joins each green area to its location
  green_bound <- dplyr::left_join(green_area@data, green_bound, by = c("id_green" = "id_green"))

  # And removes the ones without boundary ID (outside of Melbourne)
  green_bound <- green_bound[!is.na(green_bound$id_bound),]

  # Sum the area by boundary ID
  green_bound_sum <- green_bound %>%
    group_by(id_bound) %>%
    summarise(grarea_sqm = sum(grarea_sqm)) %>%
    arrange(id_bound)

  # Joins back to the boundary data to have the green area calculated
  boundary@data <- dplyr::left_join(x = boundary@data, y = green_bound_sum, by = c("id_bound" = "id_bound"))

  # Now, reads population data
  population <- MelbournePopulation$new()
  population$load_data()
  population <- population$data

  # Joins boundary with population to have the total population
  boundary@data <- dplyr::left_join(x = boundary@data, y = population, by = c("sa2_main11"))

  # Calculates the green area per capita ratio
  boundary@data$grecapita <- boundary@data$grarea_sqm / boundary@data$total_pop

  # Removes unneeded columns
  boundary@data <- boundary@data[c(
    "sa2_main11", "sa2_code11", "sa2_name11", "sa3_code11", "sa3_name11",
    "sa4_code11", "sa4_name11", "grarea_sqm", "total_pop", "grecapita"
  )]

  return(boundary)
}

run_profiler <- function() {
  shp <- calculate_profiller()

  # Exports to shapefile
  shapefile_name <- "Melb_Green_Area_per_Capita"
  shapefile_path <- file.path(EXPORTS_DIR, shapefile_name)
  rgdal::writeOGR(
    obj = shp, dsn = shapefile_path,
    layer = shapefile_name, driver = "ESRI Shapefile",
    overwrite_layer = TRUE
  )

  utils.upload_shp_to_geoserver(shapefile_name = shapefile_name, shapefile_path = shapefile_path)
}

run_profiler()
