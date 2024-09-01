s1ocn_the <- rlang::new_environment()

s1ocn_the$cache <- list(
  attibutes_list = rlang::zap()
)


s1ocn_the$get_attributes_list <- function(){

  out <- s1ocn_the$cache$attibutes_list

if(rlang::is_zap(out)){



  con <- curl::curl("https://catalogue.dataspace.copernicus.eu/odata/v1/Attributes(SENTINEL-1)")

  out <- suppressWarnings(readLines(con)) %>% jsonlite::fromJSON()


  s1ocn_the$cache$attibutes_list <- out

}

  return(out)

}


