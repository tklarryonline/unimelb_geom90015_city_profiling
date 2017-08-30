# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(stats4)


MelbourneTeachers <- setRefClass(
  Class = "MelbourneTeachers",
  fields = list(
    url = function()
      return("http://115.146.93.63:8080/geoserver/group_9/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group_9:Teachers_Pop_VIC&outputFormat=json&cql_filter=gcc_code11=%272GMEL%27"),
    data = "data.frame"
  ),
  methods = list(
    load_data = function() {
      # Reads data from url
      df <- utils.loadGeoJSON2DF(url = url)

      df$school_lvl_teachers <- df$primary_school_teachers + df$secondary_school_teachers + df$middle_school_teachers

      # Keeps the wanted columns
      df <- df[c(
        "gcc_code11", "gcc_name11", "ste_code11", "ste_name11", "sa2_main11", "sa2_name",
        "school_lvl_teachers"
      )]

      data <<- df
    }
  )
)