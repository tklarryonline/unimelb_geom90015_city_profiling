# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(stats4)


MelbournePopulation <- setRefClass(
  Class = "MelbournePopulation",
  fields = list(
    url = function() {
      return(paste(
        "http://115.146.92.210:8080/geoserver/group5_Brisbane/ows?",
        "service=WFS&version=1.0.0&request=GetFeature&",
        "typeName=group5_Brisbane:vic_population_by_age_aus_sa2_2011_ste_gccsa_info&",
        "outputFormat=JSON&",
        "cql_filter=gcc_code11=%272GMEL%27",
        sep = ""
      ))
    },
    data = "data.frame"
  ),
  methods = list(
    load_data = function() {
      # Reads data from url
      df <- utils.loadGeoJSON2DF(url = url)

      # The total column is incorrect
      df$total_pop <- rowSums(df[, 7:(ncol(df) - 1)])

      # Keeps the wanted columns
      df <- df[c("gcc_code11", "gcc_name11", "ste_code11", "ste_name11", "sa2_main11", "sa2_name", "total_pop")]

      data <<- df
    }
  )
)