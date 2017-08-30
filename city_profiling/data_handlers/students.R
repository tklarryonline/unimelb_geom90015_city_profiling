# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(stats4)


MelbourneStudents <- setRefClass(
  Class = "MelbourneStudents",
  fields = list(
    url = function()
      return("http://115.146.93.63:8080/geoserver/group_9/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group_9:Student_Pop_Vic&outputFormat=json&cql_filter=gcc_code11=%272GMEL%27"),
    data = "data.frame"
  ),
  methods = list(
    load_data = function() {
      # Reads data from url
      df <- utils.loadGeoJSON2DF(url = url)

      # Keeps the wanted columns
      df <- df[c(
        "gcc_code11", "gcc_name11", "ste_code11", "ste_name11", "sa2_main11", "sa2_name",
        "full_time_student"
      )]

      data <<- df
    }
  )
)