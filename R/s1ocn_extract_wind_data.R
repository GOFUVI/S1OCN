#' Extract wind data from a zipped Sentinel-1 OCN product
#'
#' Reads the NetCDF measurement file contained in the provided archive and
#' returns wind-related variables, dimensions, and global attributes.
#'
#' @param filepath Path to a zipped Sentinel-1 OCN product.
#' @return A list with elements `vars`, `dims`, and `global_attributes`.
#' @details The file is unzipped to a temporary directory. Only components whose
#'   names start with `"owi"` are retrieved from the NetCDF file.
#' @examples
#' filepath <- system.file("extdata", "sample.zip", package = "S1OCN")
#' if (file.exists(filepath)) {
#'   wind_data <- s1ocn_extrat_wind_data(filepath)
#' }
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


#' Extract wind data from multiple files
#'
#' Processes several downloaded products and extracts wind data from each of
#' them.
#'
#' @param files Data frame returned by [s1ocn_download_files()] with at least
#'   columns `downloaded_file_path` and `Name`.
#' @param workers Number of parallel workers to use.
#' @return A named list of wind data objects.
#' @details Parallel processing is performed with `furrr` using a multisession
#'   plan.
#' @examples
#' filepath <- system.file("extdata", "sample.zip", package = "S1OCN")
#' if (file.exists(filepath)) {
#'   files <- data.frame(Name = "sample", downloaded_file_path = filepath)
#'   wind <- s1ocn_extrat_wind_data_from_files(files, workers = 1)
#' }
#' @export
s1ocn_extrat_wind_data_from_files <- function(files, workers = 1){

  future::plan("multisession", workers = workers)

out <- files$downloaded_file_path %>% magrittr::set_names(files$Name) %>% furrr::future_map(\(file){

  S1OCN::s1ocn_extrat_wind_data(file)
})

return(out)

}


#' Create a table of wind variables
#'
#' Builds a tidy table from the wind data list returned by
#' [s1ocn_extrat_wind_data()].
#'
#' @param wind_data List produced by [s1ocn_extrat_wind_data()].
#' @return A data frame of class `S1OCN_wind_data_table`.
#' @details Selected wind variables are converted to columns and additional
#'   information is stored as attributes.
#' @examples
#' filepath <- system.file("extdata", "sample.zip", package = "S1OCN")
#' if (file.exists(filepath)) {
#'   wind_data <- s1ocn_extrat_wind_data(filepath)
#'   table <- s1ocn_new_S1OCN_wind_data_table(wind_data)
#' }
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



#' Convert a list of wind data to tables
#'
#' Applies [s1ocn_new_S1OCN_wind_data_table()] to each element of a wind data
#' list.
#'
#' @param wind_data_list List of wind data objects returned by
#'   [s1ocn_extrat_wind_data()].
#' @param workers Number of parallel workers to use.
#' @return A list of objects of class `S1OCN_wind_data_table`.
#' @details The conversion is parallelized using `furrr` with a multisession
#'   plan.
#' @examples
#' filepath <- system.file("extdata", "sample.zip", package = "S1OCN")
#' if (file.exists(filepath)) {
#'   files <- data.frame(Name = "sample", downloaded_file_path = filepath)
#'   wind_list <- s1ocn_extrat_wind_data_from_files(files, workers = 1)
#'   tables <- s1ocn_wind_data_list_to_tables(wind_list, workers = 1)
#' }
#' @export
s1ocn_wind_data_list_to_tables <- function(wind_data_list, workers = 1){

  future::plan("multisession", workers = workers)

  out <- wind_data_list %>% furrr::future_map(\(wind_data){

    S1OCN::s1ocn_new_S1OCN_wind_data_table(wind_data)
  })

  return(out)

}
