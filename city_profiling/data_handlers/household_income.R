# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(dplyr)
library(rgdal)
library(stats4)


MelbourneHouseholdIncome <- setRefClass(
  Class = "MelbourneHouseholdIncome",
  fields = list(
    url = function()
      return("http://115.146.92.210:8080/geoserver/group5_Brisbane/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group5_Brisbane:vic_household_income_aus_sa2_2011_ste_gccsa_info&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"),
    data = "data.frame"
  ),
  methods = list(
    load_data = function() {
      # Reads data from url
      df <- utils.loadGeoJSON2DF(url = url)

      # The total column is incorrect
      df$ttl_house <- rowSums(df[, 7:(ncol(df) - 1)])

      # Calculates the poverty
      df$povrt <- rowSums(df[, 7:12]) / df$total
      df$povrt[is.na(df$povrt)] <- 0

      # Keeps the wanted columns
      df <- df[c(
        "gcc_code11", "gcc_name11", "ste_code11", "ste_name11", "sa2_main11", "sa2_name",
        "povrt", "ttl_house"
      )]

      data <<- df
    }
  )
)