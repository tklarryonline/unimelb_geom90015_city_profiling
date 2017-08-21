library(plyr)
library(RCurl)
library(uuid)
library(XML)


utils.loadGMLtoDF <- function(url) {
  # create a unique temp file name for gml
  tmpFileName <- UUIDgenerate(FALSE)
  tmpFilePath <- sprintf("%s.xml", tmpFileName)
  tmpFilePath <- file.path(globalGSCredentials$tempDirPath, tmpFilePath)
  tmpCSVPath <- sprintf("%s.csv", tmpFileName)
  tmpCSVPath <- file.path(globalGSCredentials$tempDirPath, tmpCSVPath)

  # if tempDirPath not existed, create
  if (dir.exists(globalGSCredentials$tempDirPath) == FALSE) {
    dir.create(globalGSCredentials$tempDirPath,
               showWarnings = FALSE,
               recursive = TRUE)

    utils.debugprint(sprintf("%s created", globalGSCredentials$tempDirPath))
  }

  df <- tryCatch(
    expr = {
      # Gets the XML string
      xml <- getURL(url, timeout=36000)
      write(xml, tmpFilePath)

      data <- ldply(xmlToList(tmpFilePath), data.frame)

      return(data)
    },
    error = function(cond) {
      print(cond)
      return(NULL)
    },
    finally = {
      file.remove(tmpFilePath)
    }
  )

  return(df)
}

utils.df.toNumeric <- function(df, convertColumns) {
  for(col in convertColumns) {
    df[,col] <- as.numeric(as.character(df[,col]))
  }

  return(df)
}
