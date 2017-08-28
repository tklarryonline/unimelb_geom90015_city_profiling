# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Written by: Dr. Yiqun Chen    yiqun.c@unimelb.edu.au
#
# sample datasets wfs url:
# (1)greenarea: http://144.6.224.184:8080/geoserver/UADI/wfs?request=GetFeature&version=1.0.0&typeName=UADI:mcc_base_prop_use&outputFormat=json&cql_filter=usecode=%27LO%27%20OR%20usecode=%27LR%27
#
# (2)pop (Melbourne Meshblock): http://144.6.224.184:8080/geoserver/wfs?service=wfs&version=1.0.0&request=GetFeature&typeName=UADI:mb_2011_aust_pop&outputFormat=json&cql_filter=INTERSECTS(geom,%20buffer(collectGeometries(queryCollection(%27UADI:lga_2011_aust%27,%27geom%27,%27lga_code11=%27%2724600%27%27%27)),-0.00001))
#
# DevLogs:
#
# v1.0 2017-07-18
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

library(maptools)
library(rgdal)
library(rgeos)
library(jsonlite)
library(doParallel)

# using 4 cores for parallel computing
registerDoParallel(cores=4)

# change working directory to your own dir path where the r-geoserver.zip is unzipped to
setwd("C:\\Users\\FT\\Desktop\\r-geoserver-master")


# calcuate green area index for city of melbourne using meshblock population
execIndicatorGreenArea <- function(){

  # the follow two lines are for testing
  boundary_url = "http://115.146.93.46:8080/geoserver/Geographic_Boundaries/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Geographic_Boundaries:vic_sa2_2011_aust&outputFormat=JSON&cql_filter=gcc_code11=%272GMEL%27"
  motor_vehicles_url = "http://115.146.93.197:8080/geoserver/SDI07/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=SDI07:motor_vehicles_for_households_ste_gccsa_info_VIC&outputFormat=JSON"
  dwellings_url = "http://115.146.94.42:8080/geoserver/Group_1/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=Group_1:vic_dwelling_types_sa2_2011_ste_gccsa_info&outputFormat=JSON"
  population_url = "http://115.146.92.210:8080/geoserver/group5_Brisbane/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group5_Brisbane:vic_population_by_age_aus_sa2_2011_ste_gccsa_info&outputFormat=JSON"

  # load spatial object direct from geojson
  boundary = utils.loadGeoJSON2SP(boundary_url)
  # check if data layer can be successfully loaded
  if(is.null(boundary)){
    utils.debugprint("fail to load data layer for boundary")
    return(FALSE)
  }

  motor_vehicles = utils.loadGeoJSON2DF(motor_vehicles_url)
  # check if data layer can be successfully loaded
  if(is.null(motor_vehicles)){
    utils.debugprint("fail to load data layer for motor_vehicles")
    return(FALSE)
  }

  dwellings = utils.loadGeoJSON2DF(dwellings_url)

  # check if data layer can be successfully loaded
  if(is.null(dwellings)){
    utils.debugprint("fail to load data layer for dwellings")
    return(FALSE)
  }

  population = utils.loadGeoJSON2DF(population_url)

  if(is.null(population)){
    utils.debugprint("fail to load data layer for population")
    return(FALSE)
  }

  bymotor_vehicles=merge.data.frame(x=boundary@data, y=motor_vehicles, by.x="sa2_main11", by.y="sa2_main11", sort=FALSE, all.x = TRUE)
  bydwellings=merge.data.frame(x=bymotor_vehicles, y=dwellings, by.x="sa2_main11", by.y="sa2_main11", sort=FALSE, all.x = TRUE)
  all=merge.data.frame(x=bydwellings, y=population, by.x="sa2_main11", by.y="sa2_main11", sort=FALSE, all.x = TRUE)

  boundary@data=all
  boundary@data$albers_sqm <- NULL

  names(boundary@data)

  boundary@data[,"priv_vehicle"] = 0.0
  boundary@data$priv_vehicle = with(boundary@data,total/total/total)

  hidata = boundary@data

  # this example shows how to publish a geolayer by creating multiple wms styles on various attributes of the same data layer.

  # the data layer will be only published one time, with various wms styles generated for selected attributes

  publishedinfo = utils.publishSP2GeoServerWithMultiStyles(spobj=boundary,

                                                           attrname_vec=c("Number_of_private_vehicles_per_capita"),
                                                           palettename_vec=c("Reds","Blues"),
                                                           colorreverseorder_vec=c(FALSE),
                                                           geomtype = "Geometry",
                                                           colornum_vec=c(6),
                                                           classifier_vec=c("Jenks")
  )
  writeOGR(boundary, dsn = "exports/indi_12", layer = "PrivateVehiclesPerCapita", driver = "ESRI Shapefile", overwrite_layer = TRUE)


  if(is.null(publishedinfo) || length(publishedinfo)==0){
    utils.debugprint("fail to save data to geoserver")
    return(FALSE)
  }


  # print the outputs in json format

  utils.debugprint(sprintf("outputs: %s", toJSON(publishedinfo, auto_unbox=TRUE)))


  return(TRUE)
}

execIndicatorGreenArea()
