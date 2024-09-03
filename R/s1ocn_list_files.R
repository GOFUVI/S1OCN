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


#' Parse and Format Date-Time Strings to ISO 8601
#'
#' This function attempts to parse a variety of date-time string formats and returns a formatted
#' string in the ISO 8601 format (`YYYY-MM-DDTHH:MM:SS.000Z`). If the input string cannot be
#' parsed, the function returns a default value.
#'
#' @param x A character string representing a date-time in one of several possible formats. The supported
#' formats include:
#' - `"YYYY-MM-DD HH:MM:SS"` (year, month, day, hour, minute, second)
#' - `"YYYY-MM-DD HH:MM"` (year, month, day, hour, minute)
#' - `"YYYY-MM-DD HH"` (year, month, day, hour)
#' - `"YYYY-MM-DD"` (year, month, day)
#' If `x` is `NA`, `NULL`, or a special "zap" value, the function will return the `default` value.
#' @param default A date-time object returned if the input `x` is `NA`, `NULL`, a "zap" value,
#' or if parsing fails. The default value is the current time in UTC when not specified.
#'
#' @details
#' The function uses a series of parsing attempts to handle various date-time formats. It begins with the
#' most detailed format (`ymd_hms`) and progressively attempts less detailed formats (`ymd_hm`, `ymd_h`, `ymd`).
#' If all parsing attempts fail, the function returns the `default` value.
#'
#' The output is formatted to the ISO 8601 standard, which is widely used for representing date-time values
#' in a way that is unambiguous and timezone-independent.
#'
#' @return A character string representing the parsed date-time in ISO 8601 format (`YYYY-MM-DDTHH:MM:SS.000Z`).
#' If the parsing fails or the input is not provided, the function returns the specified `default` value.
#'
#' @examples
#' \dontrun{
#' # Parsing a full date-time string
#' s1ocn_parse_query_date("2024-09-03 14:23:45")
#' # Returns: "2024-09-03T14:23:45.000Z"
#'
#' # Parsing a date-time string without seconds
#' s1ocn_parse_query_date("2024-09-03 14:23")
#' # Returns: "2024-09-03T14:23:00.000Z"
#'
#' # Parsing a date-time string without minutes and seconds
#' s1ocn_parse_query_date("2024-09-03 14")
#' # Returns: "2024-09-03T14:00:00.000Z"
#'
#' # Parsing a date string
#' s1ocn_parse_query_date("2024-09-03")
#' # Returns: "2024-09-03T00:00:00.000Z"
#'
#' # Providing an invalid date string with a default value
#' s1ocn_parse_query_date("invalid-date", default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))
#' # Returns: "2024-09-03T00:00:00.000Z"
#'
#' # Handling NA input by returning the default value
#' s1ocn_parse_query_date(NA, default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))
#' # Returns: "2024-09-03T00:00:00.000Z"
#' }
#'
#' @importFrom lubridate ymd_hms ymd_hm ymd_h is.timepoint now
#' @importFrom rlang is_null is_zap try_fetch
s1ocn_parse_query_date <- function(x, default = lubridate::now(tzone = "UTC")) {

  # Check if the input `x` is NA, NULL, or a special "zap" value
  # If any of these conditions are true, assign the default value to `x`
  x <- if(is.na(x) || rlang::is_null(x) || rlang::is_zap(x)) default else x

  # Attempt to parse the input string `x` as a date-time with ymd_hms format
  out <- rlang::try_fetch(
    lubridate::ymd_hms(x, tz = "UTC"),

    # If a warning is encountered, try parsing with ymd_hm format
    warning = function(cnd)
      rlang::try_fetch(
        lubridate::ymd_hm(x, tz = "UTC"),

        # If a warning is encountered again, try parsing with ymd_h format
        warning = function(cnd)
          rlang::try_fetch(
            lubridate::ymd_h(x, tz = "UTC"),

            # If a warning is encountered again, try parsing with ymd format
            warning = function(cnd)
              # If all parsing attempts fail, use the `default` value provided
              rlang::try_fetch(
                lubridate::ymd(x, tz = "UTC"),
                warning = function(cnd)
                  default)
          )
      )
  )

  # If `out` is a valid timepoint, format it as an ISO 8601 string
  if(lubridate::is.timepoint(out)){
    out <- format(out, "%Y-%m-%dT%H:%M:%S.000Z")
  }

  # Return the parsed and formatted date-time or the default value
  return(out)
}



#' Parse and Format a Search Polygon for URL Encoding
#'
#' This function processes an input representing a search polygon, converts it to a valid Well-Known Text (WKT)
#' format, and ensures it is properly URL-encoded. The function supports inputs in various formats including
#' `sf` polygon objects, matrices, data frames, and WKT strings. If the input cannot be converted to a valid polygon,
#' the function defaults to a worldwide search polygon.
#'
#' @param search_polygon An object representing a search polygon. The input can be:
#' - An `sf` polygon object
#' - A matrix or data frame representing the polygon coordinates
#' - A character string in Well-Known Text (WKT) format
#' If the input is `NULL`, `NA`, or otherwise invalid, the function defaults to using a worldwide polygon.
#'
#' @details
#' The function performs the following steps:
#' 1. **Input Type Checking and Conversion:** The function checks if the input is a polygon. If it is a data frame,
#'    it converts it to a matrix. If it is a matrix, it attempts to convert it to an `sf` polygon. If it is a character
#'    string, it attempts to parse it as WKT.
#' 2. **Validation:** After conversion, the function validates the `sf` object to ensure it is a valid polygon. If the
#'    validation fails, the function defaults to a pre-defined worldwide search polygon.
#' 3. **WKT Formatting and URL Encoding:** The valid polygon is then converted to WKT format, and all spaces in the
#'    WKT string are replaced with `%20` to ensure proper URL encoding.
#'
#' The default search polygon is a rectangle that covers the entire globe, with coordinates (-90, -180), (-90, 180),
#' (90, 180), and (90, -180).
#'
#' @return A character string representing the search polygon in WKT format, with spaces replaced by `%20` for
#' URL encoding. This string can be used in queries that require a properly formatted polygon parameter.
#'
#' @examples
#' \dontrun{
#' # Example 1: Valid sf polygon input
#' polygon <- sf::st_polygon(list(matrix(c(-10, -10, 10, -10, 10, 10, -10, 10, -10, -10), ncol = 2, byrow = TRUE)))
#' s1ocn_parse_search_polygon(polygon)
#' # Returns: "POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))"
#'
#' # Example 2: Valid data frame input
#' df <- data.frame(x = c(-10, 10, 10, -10, -10), y = c(-10, -10, 10, 10, -10))
#' s1ocn_parse_search_polygon(df)
#' # Returns: "POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))"
#'
#' # Example 3: Valid WKT string input
#' wkt <- "POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))"
#' s1ocn_parse_search_polygon(wkt)
#' # Returns: "POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))"
#'
#' # Example 4: Invalid input defaults to worldwide polygon
#' s1ocn_parse_search_polygon("invalid input")
#' # Returns: "POLYGON%20((-90%20-180,%20-90%20180,%2090%20180,%2090%20-180,%20-90%20-180))"
#' }
#'
#' @importFrom sf st_polygon st_as_sfc st_is_valid st_as_text st_is
#' @importFrom rlang inherits_any try_fetch warn
#' @importFrom stringr str_replace_all
s1ocn_parse_search_polygon <- function(search_polygon) {

  # Define the default search polygon as a worldwide search area (a rectangle covering the whole globe)
  default_search_polygon <- sf::st_polygon(list(matrix(c(-90, -180, -90, 180, 90, 180, 90, -180, -90, -180), ncol = 2, byrow = TRUE)))

  # Check if the input `search_polygon` is not a "POLYGON" object
  if(!rlang::inherits_any(search_polygon, c("POLYGON"))) {

    # If the input is a data frame, convert it to a matrix
    if(rlang::inherits_any(search_polygon, "data.frame")) {
      search_polygon <- as.matrix(search_polygon)
    }

    # If the input is now a matrix, attempt to convert it to an sf polygon
    if(is.matrix(search_polygon)) {
      search_polygon <- rlang::try_fetch(
        sf::st_polygon(list(search_polygon)),
        error = function(cnd) {
          # If conversion fails, warn the user and return the default worldwide search polygon
          rlang::warn("Search polygon conversion failed. Performing worldwide search.", parent = cnd)
          default_search_polygon
        }
      )
    }

    # If the input is a character (e.g., a WKT string), attempt to convert it to an sf object
    if(rlang::inherits_any(search_polygon, "character")) {
      search_polygon <- rlang::try_fetch(
        sf::st_as_sfc(search_polygon),
        error = function(cnd) {
          # If conversion fails, warn the user and return the default worldwide search polygon
          rlang::warn("Search polygon conversion failed. Performing worldwide search.", parent = cnd)
          default_search_polygon
        }
      )
    }
  }

  # Validate the `search_polygon` object to ensure it is a valid sf polygon
  if(!rlang::inherits_any(search_polygon, c("sf", "sfg", "sfc")) || !sf::st_is_valid(search_polygon) || !sf::st_is(search_polygon, "POLYGON")) {
    # If not valid, set it to the default worldwide search polygon
    search_polygon <- default_search_polygon
  }

  # Convert the sf polygon to a WKT string
  search_polygon %<>% sf::st_as_text()

  # Replace all spaces in the WKT string with `%20` for URL encoding
  search_polygon %<>% stringr::str_replace_all("\\s", "%20")

  # Return the formatted WKT string representing the search polygon
  return(search_polygon)
}



#' @param max_results The default value is set to 20.The acceptable arguments for this option: Integer <0,1000>.https://documentation.dataspace.copernicus.eu/APIs/OData.html#top-option
#' @param attributes_list swathIdentifier is one of Aquisition modes here https://sentiwiki.copernicus.eu/web/s1-products#S1Products-Level-2ProductsS1-Products-Level-2-Products
#' @export
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
