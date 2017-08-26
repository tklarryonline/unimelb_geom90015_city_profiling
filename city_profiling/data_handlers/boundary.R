# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(stats4)

MelbourneBoundary <- setRefClass(
  Class = "MelbourneBoundary",
  fields = list(
    url = function() return("http://115.146.93.46:8080/geoserver/Geographic_Boundaries/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Geographic_Boundaries:vic_sa2_2011_aust&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"),
    shp = "SpatialPolygonsDataFrame"
  ),
  methods = list(
    load_data = function() {
      shp <<- utils.loadGeoJSON2SP(url)
    },
    get_utm_data = function() {
      utils.project2UTM(shp)
    }
  )
)
