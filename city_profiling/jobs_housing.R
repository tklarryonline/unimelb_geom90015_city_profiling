# Author: Luan Thanh Nguyen
# email: luan@tklarryonline.me

# Source the manage.R file to setup project
source("./manage.R")

vic.boundary.read_data <- function() {
  url <- "http://115.146.93.46:8080/geoserver/Geographic_Boundaries/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Geographic_Boundaries:vic_sa2_2011_aust&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"
  boundary <- utils.loadGeoJSON2SP(url)

  return(boundary)
}

vic.employment.readData <- function() {
  url <- "http://115.146.92.236:8080/geoserver/group2/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group2:vic_employment_by_sex_and_hours_aus_sa2_2011_ste_gccsa_info&ouputFormat=JSON"
  layerName <- "vic_employment_by_sex_and_hours_aus_sa2_2011_ste_gccsa_info."

  data <- utils.loadGMLtoDF(url = url)

  # Beautify the column names
  colnames(data) <- sapply(colnames(data), function(x) { gsub(layerName, "", x) })

  # Drop unnecessary columns
  dropColumns <- c(".id", "null", ".attrs", "X..i..")
  data <- data[, !(names(data) %in% dropColumns)]

  # Drop null data
  data <- data[complete.cases(data),]

  numericCols <- c(
    "ste_code11", "sa2_code11", "sa2_main11", "sa2_code",
    "exmployed_full_time_persons", "exmployed_full_time_male", "exmployed_full_time_female",
    "employed_part_time_persons", "employed_part_time_male", "employed_part_time_female",
    "unemployed_looking_for_work_female", "unemployed_looking_for_work_male", "unemployed_looking_for_work_persons", "total"
  )

  data <- utils.df.toNumeric(df = data, convertColumns = numericCols)

  data <- rename(
    x = data,
    replace = c("total" = "total_labour")
  )

  # Because the actual total column is wrong
  data$total_labour <- data$exmployed_full_time_persons + data$employed_part_time_persons + data$unemployed_looking_for_work_persons
  data$total_jobs <- data$exmployed_full_time_persons + data$employed_part_time_persons

  # Only keeps necessary columns
  data <- data[, c(
    "ste_code11", "sa2_code11", "sa2_main11", "sa2_code",
    "total_labour", "total_jobs"
  )]

  return(data)
}

vic.housing.read_data <- function() {
  url <- "http://115.146.94.42:8080/geoserver/Group_1/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Group_1:VIC_Dwellings_HomelessShelters&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"

  data <- utils.loadGeoJSON2DF(url)

  data <- rename(
    x = data,
    replace = c("total" = "total_houses")
  )

  return(data)
}

vic.boundary_shp <- vic.boundary.read_data()
vic.employment <- vic.employment.readData()
vic.housing <- vic.housing.read_data()

vic.jobs_housing <- merge.data.frame(
  x = vic.housing, y = vic.employment,
  by = "sa2_code11", sort = FALSE, all.x = TRUE
)
vic.jobs_housing$jh_ratio <- vic.jobs_housing$total_jobs / vic.jobs_housing$total_houses
vic.jobs_housing$jh_ratio[vic.jobs_housing$total_houses == 0] <- 0

vic.boundary_shp@data <- merge.data.frame(
  x = vic.boundary_shp@data, y = vic.jobs_housing,
  by = "sa2_code11", sort = FALSE, all.x = TRUE
)

writeOGR(
  vic.boundary_shp,
  dsn = "exports",
  layer = "jobs_housing", driver = "ESRI Shapefile",
  overwrite_layer = TRUE
)
