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
