#' @export
s1ocn_extrat_wind_data <- function(filepath){

  temp_dir <- tempdir()

  files <- unzip(filepath,exdir = temp_dir)

  nc_file <- files %>% purrr::keep(\(x) stringr::str_detect(x, "measurement/.*?\\.nc")) %>% magrittr::extract(1)

  con <- RNetCDF::open.nc(nc_file)

  data <- RNetCDF::read.nc(con)

  wind_data <- list()

wind_data$vars <- data[stringr::str_starts(names(data),"owi")]

file_info <- RNetCDF::file.inq.nc(con)

wind_data$dims <- ((1:file_info$ndims) -1) %>% purrr::map(\(i) RNetCDF::dim.inq.nc(con, i) ) %>% purrr::keep(\(dim) stringr::str_starts(dim$name, "owi"))

names(wind_data$dims) <- purrr::map(wind_data$dims, "name")

wind_data$global_attributes <- ((1:file_info$ngatts) -1) %>% purrr::map(\(i) RNetCDF::att.get.nc(con,"NC_GLOBAL", i) )



names(wind_data$global_attributes) <-  ((1:file_info$ngatts) -1) %>% purrr::map(\(i) RNetCDF::att.inq.nc(con,"NC_GLOBAL", i) ) %>% purrr::map( "name")


  RNetCDF::close.nc(con)

  return(wind_data)

}


#' @export
s1ocn_extrat_wind_data_from_files <- function(files, workers = 1){

  future::plan("multisession", workers = workers)

out <- files$downloaded_file_path %>% magrittr::set_names(files$Name) %>% furrr::future_map(\(file){

  S1OCN::s1ocn_extrat_wind_data(file)
})

return(out)

}


#' @export
s1ocn_new_S1OCN_wind_data_table <- function(wind_data){

  out <- data.frame()

  vars_to_table <-c("owiLon","owiLat","owiWindSpeed","owiWindDirection","owiMask","owiInversionQuality","owiHeading","owiWindQuality","owiRadVel")

 out <-  wind_data$vars[vars_to_table] %>% purrr::map2(names(.), \(mat, var) data.frame(as.vector(mat)) %>%  magrittr::set_colnames(var)) %>% dplyr::bind_cols() %>%
   dplyr::mutate(
     firstMeasurementTime = wind_data$global_attributes$firstMeasurementTime  %>% lubridate::ymd_hms(),
     lastMeasurementTime = wind_data$global_attributes$lastMeasurementTime  %>% lubridate::ymd_hms(),
     .before = 1)


attributes(out) %<>% append( list(vars = wind_data$vars[!names(wind_data$vars) %in% vars_to_table], dims = wind_data$dims, global_attributes = wind_data$global_attributes))


class(out) <- c("S1OCN_wind_data_table", class(out))

  return(out)

}



#' @export
s1ocn_wind_data_list_to_tables <- function(wind_data_list, workers = 1){

  future::plan("multisession", workers = workers)

  out <- wind_data_list %>% furrr::future_map(\(wind_data){

    S1OCN::s1ocn_new_S1OCN_wind_data_table(wind_data)
  })

  return(out)

}
