# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

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
      shp <<- utils.loadGeoJSON2SP(url = url)
    },
    get_utm_data = function() {
      utils.project2UTM(shp)
    }
  )
)
