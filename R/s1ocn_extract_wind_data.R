#' Extract wind data from a Sentinel-1 OCN product
#'
#' Reads a Sentinel-1 Ocean (OCN) zipped product and returns wind-related
#' variables, dimensions and global attributes from its NetCDF file.
#'
#' @param filepath Path to a Sentinel-1 OCN ZIP archive.
#'
#' @details
#' The archive is unpacked in a temporary directory. The function locates the
#' NetCDF file within the `measurement` folder, extracts all variables whose
#' names begin with `owi`, and gathers their corresponding dimensions and global
#' attributes.
#'
#' @return A list with elements `vars`, `dims` and `global_attributes`.
#'
#' @examples
#' \dontrun{
#' wind <- s1ocn_extrat_wind_data("path/to/product.zip")
#' }
#'
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
#' Applies [s1ocn_extrat_wind_data()] to each product listed in a table of
#' downloaded files.
#'
#' @param files A data frame containing at least the columns
#'   `downloaded_file_path` and `Name`.
#' @param workers Number of parallel workers to use.
#'
#' @details
#' The function processes the products in parallel with
#' `furrr::future_map()`. The resulting list is named using the product
#' names provided in `files`.
#'
#' @return A named list of wind data objects.
#'
#' @examples
#' \dontrun{
#' files <- data.frame(
#'   downloaded_file_path = "path/to/product.zip",
#'   Name = "Product1"
#' )
#' wind_list <- s1ocn_extrat_wind_data_from_files(files)
#' }
#'
#' @export
s1ocn_extrat_wind_data_from_files <- function(files, workers = 1){

  future::plan("multisession", workers = workers)

out <- files$downloaded_file_path %>% magrittr::set_names(files$Name) %>% furrr::future_map(\(file){

  S1OCN::s1ocn_extrat_wind_data(file)
})

return(out)

}


#' Build a wind data table
#'
#' Convert a wind data list into a structured data frame with metadata.
#'
#' @param wind_data A list returned by [s1ocn_extrat_wind_data()].
#'
#' @details
#' Selected wind variables are flattened into columns and combined with the
#' first and last measurement timestamps. Remaining variables, dimensions and
#' attributes are stored in the resulting object's attributes.
#'
#' @return An object of class `S1OCN_wind_data_table`.
#'
#' @examples
#' \dontrun{
#' wind <- s1ocn_extrat_wind_data("path/to/product.zip")
#' tbl <- s1ocn_new_S1OCN_wind_data_table(wind)
#' }
#'
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



#' Convert a list of wind data into tables
#'
#' Transform each element of a wind data list into a
#' [`S1OCN_wind_data_table`][s1ocn_new_S1OCN_wind_data_table].
#'
#' @param wind_data_list A list of wind data objects from
#'   [s1ocn_extrat_wind_data()].
#' @param workers Number of parallel workers to use.
#'
#' @details
#' The conversion is executed in parallel using `furrr::future_map()`.
#'
#' @return A list of `S1OCN_wind_data_table` objects.
#'
#' @examples
#' \dontrun{
#' wind <- list(
#'   a = s1ocn_extrat_wind_data("path/to/a.zip"),
#'   b = s1ocn_extrat_wind_data("path/to/b.zip")
#' )
#' tbls <- s1ocn_wind_data_list_to_tables(wind, workers = 2)
#' }
#'
#' @export
s1ocn_wind_data_list_to_tables <- function(wind_data_list, workers = 1){

  future::plan("multisession", workers = workers)

  out <- wind_data_list %>% furrr::future_map(\(wind_data){

    S1OCN::s1ocn_new_S1OCN_wind_data_table(wind_data)
  })

  return(out)

}
