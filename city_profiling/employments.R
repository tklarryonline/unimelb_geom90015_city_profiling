# Author: Luan Thanh Nguyen
# Email:  luan@tklarryonline.me

# Source the manage.R file to setup project
source("./manage.R")

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

  # Because the actual total column is wrong
  data$total <- data$exmployed_full_time_persons + data$employed_part_time_persons + data$unemployed_looking_for_work_persons

  return(data)
}

# Loads boundary from geoserver
boundary.url <- "http://115.146.93.46:8080/geoserver/Geographic_Boundaries/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Geographic_Boundaries:vic_sa2_2011_aust&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"
boundary.shp <- utils.loadGeoJSON2SP(boundary.url)

vic.employment.data <- vic.employment.readData()

# Calculates unemployment ratio
vic.employment.data$unemployment <- vic.employment.data$unemployed_looking_for_work_persons / vic.employment.data$total

# Unemployment is 1 when total = 0
vic.employment.data$unemployment[vic.employment.data$total == 0] <- 1

# Calculates job availability ratio
vic.employment.data$jobAvailability <- (vic.employment.data$exmployed_full_time_persons + vic.employment.data$employed_part_time_persons) / vic.employment.data$total

# Job Availability is 0 when total = 0
vic.employment.data$jobAvailability[vic.employment.data$total == 0] <- 0

melb.shp <- boundary.shp
melb.shp@data <- vic.employment.data[vic.employment.data$gcc_code11 == "2GMEL",]

# Writes to Shapefile
writeOGR(melb.shp, dsn = "exports/employment", layer = "melb_employment", driver = "ESRI Shapefile", overwrite_layer = TRUE)

