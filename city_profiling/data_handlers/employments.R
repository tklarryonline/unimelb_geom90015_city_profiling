# ==========================================================================
# Author: Luan Thanh Nguyen
# Email: luan@tklarryonline.me
# UniMelb email: l.nguyen50@student.unimelb.edu.au
# ==========================================================================

library(stats4)
library(dplyr)


MelbourneEmployments <- setRefClass(
  Class = "MelbourneEmployments",
  fields = list(
    url = function()
      return("http://115.146.92.236:8080/geoserver/group2/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=group2:vic_employment_by_sex_and_hours_aus_sa2_2011_ste_gccsa_info&ouputFormat=JSON"),
    data = "SpatialPolygonsDataFrame"
  ),
  methods = list(
    load_data = function() {
      df <- utils.loadGMLtoDF(url = url)

      # Beautify the column names
      colnames(df) <- sapply(
        colnames(df),
        function(x) gsub(layerName, "", x)
      )

      # Drop unnecessary columns
      # These columns affect the numeric transformation
      dropColumns <- c(".id", "null", ".attrs", "X..i..")
      df <- df[, !(names(df) %in% dropColumns)]

      # Drop null df
      df <- df[complete.cases(df),]

      numericCols <- c(
        "ste_code11", "sa2_code11", "sa2_main11", "sa2_code",
        "exmployed_full_time_persons", "exmployed_full_time_male", "exmployed_full_time_female",
        "employed_part_time_persons", "employed_part_time_male", "employed_part_time_female",
        "unemployed_looking_for_work_female", "unemployed_looking_for_work_male", "unemployed_looking_for_work_persons", "total"
      )

      df <- utils.df.toNumeric(df = df, convertColumns = numericCols)

      # Calculate the must have columns for indicators
      dplyr::mutate_(
        df,
        total_employees = quote(exmployed_full_time_persons + employed_part_time_persons),
        female_employees = quote(exmployed_full_time_female + employed_part_time_female),
        total_unemployed = quote(unemployed_looking_for_work_persons),
        # Because the actual total column is wrong
        total_labour = quote(total_employees + total_unemployed),

        # Calculate the indicators
        # Indicator 1: Unemployment Ratio
        unemploy_ratio = quote(total_unemployed / total_labour),

        # Indicator 2: Job Availability Ratio
        job_avail_ratio = quote(total_employees / total_labour),

        # Indicator 10: Female Employees Ratio
        fm_employees_ratio = quote(female_employees / total_labour)
      )

      # Now only select the relevant columns
      df <- df[c(
        "ste_code11", "sa2_code11", "sa2_main11", "sa2_code",
        "total_labour", "unemploy_ratio", "job_avail_ratio", "fm_employees_ratio"
      )]
    },
    get_utm_data = function() {
      utils.project2UTM(data)
    }
  )
)
