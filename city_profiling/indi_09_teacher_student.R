# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

source("manage.R")

source(file.path("data_handlers", "boundary.R"))
source(file.path("data_handlers", "teachers.R"))
source(file.path("data_handlers", "students.R"))

library(dplyr)

calculate_profiler <- function() {
  # Reads boundary data
  boundary <- MelbourneBoundary$new()
  boundary$load_data()
  boundary <- boundary$shp

  # Reads teachers data
  teachers <- MelbourneTeachers$new()
  teachers$load_data()
  teachers <- teachers$data

  # Reads students data
  students <- MelbourneStudents$new()
  students$load_data()
  students <- students$data

  # Merges teachers and students
  teachers_students <- dplyr::left_join(x = teachers, y = students, by = "sa2_main11")

  # Calculates the indicator: teachers / students
  teachers_students$teach_stud <- teachers_students$school_lvl_teachers / teachers_students$full_time_student
  teachers_students$teach_stud[teachers_students$full_time_student == 0] <- 0

  # Only needs the ratio
  teachers_students <- teachers_students[c("sa2_main11", "teach_stud")]

  # Merges to boundary to have geom data
  boundary@data <- dplyr::left_join(x = boundary@data, y = teachers_students, by = "sa2_main11")

  return(boundary)
}

run_profiler <- function() {
  shp <- calculate_profiler()

  # Exports to shapefile
  shapefile_name <- "Melb_Teachers_Students_ratio"
  shapefile_path <- file.path(EXPORTS_DIR, shapefile_name)
  rgdal::writeOGR(
    obj = shp, dsn = shapefile_path,
    layer = shapefile_name, driver = "ESRI Shapefile",
    overwrite_layer = TRUE
  )

  utils.upload_shp_to_geoserver(shapefile_name = shapefile_name, shapefile_path = shapefile_path)
}

run_profiler()
