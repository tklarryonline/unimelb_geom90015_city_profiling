#

library(plyr)
library(RCurl)
library(uuid)
library(XML)

WFS_URL_TEMPLATE <- "%s/wfs?service=wfs&version=1.0.0&request=GetFeature&typeName=%s:%s&outputFormat=json"

utils.loadGMLtoDF <- function(url) {
  # create a unique temp file name for gml
  tmp_file_name <- UUIDgenerate(FALSE)
  tmp_file_path <- sprintf("%s.xml", tmp_file_name)
  tmp_file_path <- file.path(TEMP_DIR, tmp_file_path)
  tmp_csv_path <- sprintf("%s.csv", tmp_file_name)
  tmp_csv_path <- file.path(TEMP_DIR, tmp_csv_path)

  # if tempDirPath not existed, create
  if (dir.exists(TEMP_DIR) == FALSE) {
    dir.create(
      TEMP_DIR,
      showWarnings = FALSE,
      recursive = TRUE
    )

    utils.debugprint(sprintf("%s created", TEMP_DIR))
  }

  df <- tryCatch(
    expr = {
      # Gets the XML string
      xml <- getURL(url, timeout=36000)
      write(xml, tmp_file_path)

      data <- ldply(xmlToList(tmp_file_path), data.frame)

      return(data)
    },
    error = function(cond) {
      print(cond)
      return(NULL)
    },
    finally = {
      file.remove(tmp_file_path)
    }
  )

  return(df)
}

utils.df.toNumeric <- function(df, convertColumns) {
  for (col in convertColumns) {
    df[, col] <- as.numeric(as.character(df[, col]))
  }

  return(df)
}

utils.add_shp_to_datastore <- function(filepath) {
  #' upload a shpfile (zip) to geoserver
  #'
  #' @param filepath
  #'
  #' @return empty string if success or error message
  #' @export
  #'
  #' @examples

  #create workspace if it doesn't exist
  utils.createWorkspace(globalGSCredentials$gsWORKSPACENAME)

  #ref: https://github.com/omegahat/RCurl/issues/18

  h <- basicTextGatherer()
  url <- sprintf('%s/rest/workspaces/%s/datastores/%s/file.shp'
                 ,globalGSCredentials$gsRESTURL
                 ,globalGSCredentials$gsWORKSPACENAME
                 ,globalGSCredentials$gsDATASTORESNAME
                )

  content.type <- guessMIMEType(filepath, "application/zip")

  # upload shpfile by sending a PUT request
  res <- ftpUpload(what=filepath
                   ,to=url
                   ,httpheader = c('Content-Type'=content.type[[1]])
                   ,customrequest='PUT'
                   ,upload=TRUE
                   ,httpheader=c(Accept="*/*",'Content-Type'="application/zip")
                   ,username = globalGSCredentials$gsRESTUSER
                   ,password = globalGSCredentials$gsRESTPW
                   ,timeout = 36000
                   ,httpauth=AUTH_BASIC
                   ,verbose = TRUE
                   ,writefunction = h$update)

  #utils.debugprint(sprintf("utils.add_shp_to_datastore output: %s",h$value()))
  return(h$value())
}

utils.publish_shp_to_geoserver <- function(spobj) {
  #' publish a sp object to geoserver using RESTful API via curl
  #'
  #' @param spobj A sp object
  #'
  #' @return A wfs url string of successfully published data layer
  #' @export
  #'
  #' @examples

  procflag <- TRUE
  published_wfs_url <- NULL #if error occurs, return published_wfs_url as NULL

  # check if sp is null, return null if null
  if (is.null(spobj)) {
    return(NULL)
  }

  # save spobj as shp file
  tmp_file_name <- UUIDgenerate(FALSE)
  tmp_file_path <- file.path(TEMP_DIR, tmp_file_name)
  dir.create(tmp_file_path, showWarnings = FALSE, recursive = TRUE)
  writeOGR(
    spobj,
    dsn = tmp_file_path,
    layer = tmp_file_name,
    driver = "ESRI Shapefile",
    check_exists = TRUE,
    overwrite_layer = TRUE
  )

  # zip shp file
  # ref: for windows, install Rtools from https://cran.r-project.org/bin/windows/Rtools/
  # and make sure it is on the system Path
  # flag -j to store just the name of a saved file (junk the path), and do not store directory names.
  # By default, zip will store the full path
  zip(zipfile = tmp_file_path, files = dir(tmp_file_path, full.names = TRUE), flags = "-j")
  zipfile <- sprintf("%s.zip", tmp_file_path)

  # upload zip for geoserver
  out <- utils.add_shp_to_datastore(zipfile)
  if (nchar(out) > 0) {
    procflag <- FALSE
  }

  if (procflag) {
    # publish it as new featuretype
    out <- utils.create_feature_type(tmp_file_name)
  }

  # return wfs url for the uploaded datalayer
  # wfsUrlTemplate: %s/wfs?service=wfs&version=1.0.0&request=GetFeature&typeName=%s:%s&outputFormat=json
  if (procflag) {
    published_wfs_url <- sprintf(
      WFS_URL_TEMPLATE,
      GEOSERVER_CREDENTIALS$URL, GEOSERVER_CREDENTIALS$WORKSPACE, tmp_file_name
    )
  }

  # remove tmp zip file
  file.remove(zipfile)
  # remove tmp shp file folder
  unlink(tmp_file_path, recursive = TRUE)

  return(published_wfs_url)
}

utils.create_feature_type <- function(filename) {
  #' create a featuretype in geoserver datastore, which makes the uploaded shpfile 'published'
  #'
  #' @param filename
  #'
  #' @return empty string if success or error message
  #' @export
  #'
  #' @examples

  # publish uploaded datalayer
  h <- basicTextGatherer()
  url <- sprintf('%s/rest/workspaces/%s/datastores/%s/featuretypes.xml'
                 ,globalGSCredentials$gsRESTURL
                 ,globalGSCredentials$gsWORKSPACENAME
                 ,globalGSCredentials$gsDATASTORESNAME
                 )

  body <- sprintf('<featureType><enabled>true</enabled><metadata /><keywords /><metadataLinks /><attributes /><name>%s</name><title>%s</title><srs>EPSG:4326</srs><projectionPolicy>FORCE_DECLARED</projectionPolicy></featureType>'
                  ,filename
                  ,filename)

  # add a new featuretype by sending a POST request
  curlPerform(url = url
              ,httpheader=c(Accept="text/xml", 'Content-Type'="text/xml")
              ,username = globalGSCredentials$gsRESTUSER
              ,password = globalGSCredentials$gsRESTPW
              ,httpauth=AUTH_BASIC
              ,post=1
              ,postfields=body
              ,writefunction = h$update
              ,verbose = TRUE)

  #utils.debugprint(sprintf("utils.create_feature_type output: %s",h$value()))

  return(h$value())
}

utils.upload_shp_to_geoserver <- function(shapefile_name, shapefile_path) {
  # Zip the shapefile
  zip(zipfile = shapefile_path, files = dir(shapefile_path, full.names = TRUE), flags = "-j")
  zipped_shapefile_path <- sprintf("%s.zip", shapefile_path)

  # Upload the zipped shapefile to the GeoServer
  results <- utils.addShp2DataStore(zipped_shapefile_path)

  if (nchar(results) > 0) {
    print("Something is wrong with the uploading")
    print("Shapefile: %s", zipped_shapefile_path)

    return(NULL)
  }

  # Create new FeatureType based on the uploaded shapefile
  results <- utils.createFeatureType(shapefile_name)
  published_url <- sprintf(
    WFS_URL_TEMPLATE,
    GEOSERVER_CREDENTIALS$URL,
    GEOSERVER_CREDENTIALS$WORKSPACE,
    shapefile_name
  )

  # Removes the shapefile and zipped shapefile
  file.remove(zipped_shapefile_path)
  unlink(shapefile_path, recursive = TRUE)

  print("Shapefile publish!")
  print(published_url)
}
