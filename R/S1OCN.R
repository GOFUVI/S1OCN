s1ocn_build_attribute_query <- function(attribute_name, attribute_value, value_operator = "eq"){

  value_operator <- rlang::arg_match(value_operator,values = c("eq","le","ge","lt","gt"))

  attributes_list <- s1ocn_the$get_attributes_list()

  if(!attribute_name %in% attributes_list$Name) rlang::abort(glue::glue("{AttributeName} is not a valid attribute", AttributeName = attribute_name))

  value_type <-attributes_list %>% dplyr::filter(Name == attribute_name) %>% dplyr::pull("ValueType")

  if(rlang::is_character(attribute_value)){
    attribute_value <- glue::glue("%27{AttributeValue}%27", AttributeValue = attribute_value)
  }

  out <- glue::glue("Attributes/OData.CSC.{ValueType}Attribute/any(att:att/Name%20eq%20%27{AttributeName}%27%20and%20att/OData.CSC.{ValueType}Attribute/Value%20{ValueOperator}%20{AttributeValue})",
                    ValueType = value_type,
                    AttributeName = attribute_name,
                    AttributeValue = attribute_value,
                    ValueOperator = value_operator
  )

  return(out)

}

s1ocn_parse_query_date <- function(x, default = lubridate::now(tzone = "UTC")) {

  out <- rlang::try_fetch(
    lubridate::ymd_hms(x,tz = "UTC"),
    warning = function(cnd)
      rlang::try_fetch(
        lubridate::ymd_hm(x,tz = "UTC"),
        warning = function(cnd)
          rlang::try_fetch(
            lubridate::ymd_h(x,tz = "UTC"),
            warning = function(cnd)
              rlang::try_fetch(
                lubridate::ymd(x,tz = "UTC"),
                warning = function(cnd)
                  default)
          )
      )
  )
  if(lubridate::is.timepoint(out)){
    out <- format(out, "%Y-%m-%dT%H:%M:%S.000Z")
  }
  return(out)
}

s1ocn_parse_search_polygon <- function(search_polygon){

  default_search_polygon <- sf::st_polygon(list(matrix(c(-90,-180,-90,180,90,180,90,-180,-90,-180), ncol = 2, byrow = T)))

  if(!rlang::inherits_any(search_polygon, c("POLYGON"))){

    if(rlang::inherits_any(search_polygon, "data.frame")){

      search_polygon <- as.matrix(search_polygon)
    }

    if(is.matrix(search_polygon)){
      search_polygon <- rlang::try_fetch(sf::st_polygon(list(search_polygon)),
                                         error = function(cnd){
                                           rlang::warn("Search polygon conversion failed. Performing worldwide search.", parent = cnd)
                                           default_search_polygon
                                         })
    }

    if(rlang::inherits_any(search_polygon, "character")){
      search_polygon <- rlang::try_fetch(sf::st_as_sfc(search_polygon),
                                         error = function(cnd){
                                           rlang::warn("Search polygon conversion failed. Performing worldwide search.", parent = cnd)
                                           default_search_polygon
                                         })
    }

  }

  if(!sf::st_is_valid(search_polygon) || !sf::st_is(search_polygon, "POLYGON")){
    search_polygon <- default_search_polygon
  }

  search_polygon %<>% sf::st_as_text()

  search_polygon %<>% stringr::str_replace_all("\\s","%20")


  return(search_polygon)

}

#' @param max_results The default value is set to 20.The acceptable arguments for this option: Integer <0,1000>.https://documentation.dataspace.copernicus.eu/APIs/OData.html#top-option
#' @param attributes_list swathIdentifier is one of Aquisition modes here https://sentiwiki.copernicus.eu/web/s1-products#S1Products-Level-2ProductsS1-Products-Level-2-Products
#' @examples
#' s1ocn_list_files(attributes_search = list("swathIdentifier"="IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125))
#' s1ocn_list_files(attributes_search = list("swathIdentifier"="IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125), datetime_start = "2021-01-01")
#' s1ocn_list_files(attributes_search = list("swathIdentifier"="IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125), datetime_start = "2021-01-01", search_polygon = matrix(c(-11, 41, -11, 44, 6, 44, 6, 41, -11, 41), ncol = 2, byrow = T))
s1ocn_list_files <-function(search_polygon = rlang::zap(), datetime_start = rlang::zap(), datetime_end = rlang::zap(), max_results = 20, attributes_search = list()){

  iterate_pages <- max_results > 1000




  url <- glue::glue("https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top={MaxResults}&$filter=Collection/Name%20eq%20%27SENTINEL-1%27", MaxResults = max_results)

  product_type_query <- s1ocn_build_attribute_query("productType","OCN") #https://sentiwiki.copernicus.eu/web/s1-products#S1Products-Level-2ProductsS1-Products-Level-2-Products

  url <- glue::glue("{url}%20and%20{product_type_query}")

  attributes_search$productType <- NULL

  if(length(attributes_search) > 0){
    url <- purrr::reduce2(attributes_search, names(attributes_search),
                          \(url_so_far,attribute_value, attribute_name){

                            attribute_query <- s1ocn_build_attribute_query(attribute_name, attribute_value, value_operator = "eq")

                            glue::glue("{url_so_far}%20and%20{attribute_query}")

                          }, .init = url)
  }


  if(any(!rlang::is_zap(c(datetime_start, datetime_end)))){

    datetime_start <- if(rlang::is_zap(datetime_start)) "1900-01-01T00:00:00.000Z" else s1ocn_parse_query_date(datetime_start)

    datetime_end <- if(rlang::is_zap(datetime_end)) s1ocn_parse_query_date(lubridate::now(tzone = "UTC")) else s1ocn_parse_query_date(datetime_end)

    url <- glue::glue("{url}%20and%20ContentDate/Start%20ge%20{StartPeriod}%20and%20ContentDate/Start%20le%20{EndPeriod}", StartPeriod = datetime_start, EndPeriod = datetime_end)

  }

  if(!rlang::is_zap(search_polygon)){

search_polygon %<>% s1ocn_parse_search_polygon()

    search_polygon_query  <- glue::glue("OData.CSC.Intersects(area=geography%27SRID=4326;{SearchPolygon}%27)", SearchPolygon = search_polygon)
    url <- glue::glue("{url}%20and%20{search_polygon_query}")

  }

  url <- as.character(url)

  con <- curl::curl(url)

  response <-suppressWarnings(readLines(con)) %>% jsonlite::fromJSON()

  out <- response$value

  while(iterate_pages && !is.null(response$`@odata.nextLink`)){

    url <- as.character(response$`@odata.nextLink`)

    con <- curl::curl(url)
    response <- suppressWarnings(readLines(con)) %>% jsonlite::fromJSON()

    out %<>% dplyr::bind_rows(response$value)

  }


  return(out)

}
