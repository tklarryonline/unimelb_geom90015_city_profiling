# Author: Luan Thanh Nguyen
# Email: l.nguyen50@student.unimelb.edu.au

# Source manage.R to setup
source("./manage.R")

vic.boundary.read_data <- function() {
  url <- "http://115.146.93.46:8080/geoserver/Geographic_Boundaries/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Geographic_Boundaries:vic_sa2_2011_aust&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"
  boundary <- utils.loadGeoJSON2SP(url)

  # Reprojects to UTM for metrics purposes
  boundary <- utils.project2UTM(boundary)

  return(boundary)
}

vic.green_areas.read_data <- function() {
  #' Read data from WFS GeoJSON link
  #' do some basic cleanings
  #' and return the data

  url <- "http://115.146.94.88:8080/geoserver/Group8/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Group8:Greenspaces%20VIC&outputFormat=Json"

  # Get the green spaces
  green_spaces <- utils.loadGeoJSON2SP(url)

  # Reprojects to UTM for metrics purposes
  green_spaces <- utils.project2UTM(green_spaces)

  return(green_spaces)
}

vic.population.read_data <- function() {
  url <- "http://115.146.92.210:8080/geoserver/group5_Brisbane/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group5_Brisbane:vic_population_by_age_aus_sa2_2011_ste_gccsa_info&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"

  # Get the population data
  vic.boundary_shp <- vic.boundary.read_data()
  population <- utils.loadGeoJSON2DF(url)

  # Merge with boundary data
  temp_boundary_data <- merge.data.frame(
    x = vic.boundary_shp@data, y = population,
    by = "sa2_main11", sort = FALSE, all.x = TRUE
  )
  vic.boundary_shp@data <- temp_boundary_data

  return(vic.boundary_shp)
}

# green area index calculation base is for every 100,000 people
pop_basenum = 100000

vic.population <- vic.population.read_data()
vic.green_spaces <- vic.green_areas.read_data()

vic.population@data[, "gaarea"] = 0.0
vic.population@data[, "idxval"] = 0.0

result <- foreach(
  i = 1:nrow(vic.population),
  .combine = rbind,
  .export = c("SpatialPolygons", "over", "gIntersection", "gArea")
) %dopar% {
  # get the geometry polgyon of population, return 0 for gaarea and idxval if geometry is NULL
  if (is.null(vic.population@polygons[i])) {
    out = c(0, 0)
  } else {
    geom_pop = SpatialPolygons(vic.population@polygons[i], proj4string = vic.population@proj4string)

    # accumulate the total size of intersected greenarea for the current population geometry
    intersectedGreenArea = 0.0

    # this 'over' method is much faster to find all intersected green area polygons of current pop polygon
    # temporarily save all intersected greenarea into a sub spatialdataframe
    intersectedGADF = vic.green_spaces[!is.na(over(vic.green_spaces, vic.population[i, ]))[, 1], ]

    # if intersected with one or more greenarea polygon, calculate and accumulate the intersected area for each population meshblock
    if (nrow(intersectedGADF) > 0) {
      for (j in nrow(intersectedGADF):1) {
        geom_greenarea = SpatialPolygons(intersectedGADF@polygons[j], proj4string =
                                           intersectedGADF@proj4string)

        # do the actual intersction process
        intsectedGeom = gIntersection(geom_pop, geom_greenarea)
        # accumulate the size of intersected greenarea
        intersectedGreenArea = intersectedGreenArea + gArea(intsectedGeom)

      }
    }

    # check population attribute, make sure it is valid
    population = vic.population@data[i, "total"]

    if (is.null(population) || is.na(population))
      population = 0

    # for those polygons with 0 population, assign idxval = 0
    idx_val = 0
    if (population > 0) {
      idx_val = intersectedGreenArea / (population / (pop_basenum * 1.0))
    }

    out = c(intersectedGreenArea, idx_val)
  }
}
