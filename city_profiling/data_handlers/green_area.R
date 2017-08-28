# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(dplyr)
library(rgeos)
library(stats4)


VictoriaGreenAreas <- setRefClass(
  Class = "VictoriaGreenAreas",
  fields = list(
    url = function()
      return(paste(
        "http://115.146.94.88:8080/geoserver/Group8/ows?",
        "service=WFS&version=1.0.0&request=GetFeature&",
        "typeName=Group8:Greenspaces%20VIC&outputFormat=Json",
        sep = ""
      )),
    shp = "SpatialPolygonsDataFrame"
  ),
  methods = list(
    load_data = function() {
      # Loads data from GeoServer
      shp_df <- utils.loadGeoJSON2SP(url = url)

      # Converts this data into metre
      shp_df <- utils.project2UTM(shp_df)

      # Calculates the area of the green areas in square metres
      shp_df@data$grarea_sqm <- gArea(shp_df, byid = TRUE)

      shp <<- shp_df
    }
  )
)
