# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(dplyr)
library(rgdal)
library(stats4)


MelbourneDwellingHousing <- setRefClass(
  Class = "MelbourneDwellingHousing",
  fields = list(
    url = function()
      return(paste(
        "http://115.146.94.42:8080/geoserver/Group_1/ows?",
        "service=WFS&version=1.0.0&request=GetFeature&",
        "typeName=Group_1:VIC_Dwellings_HomelessShelters&",
        "outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27",
        sep = ""
      )),
    data = "data.frame"
  ),
  methods = list(
    load_data = function() {
      df <- utils.loadGeoJSON2DF(url)

      df <- rename(
        x = df,
        replace = c("total" = "ttl_houses")
      )

      data <<- df[c("sa2_code11", "ttl_houses")]
    }
  )
)
