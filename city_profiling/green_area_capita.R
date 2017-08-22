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
