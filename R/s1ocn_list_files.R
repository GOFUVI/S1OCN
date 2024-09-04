#' Build an OData Query for Sentinel-1 Attributes
#'
#' This function constructs a valid OData query string to filter Sentinel-1 attributes based on a specified attribute name, value, and comparison operator.
#' It validates the attribute name and constructs the query according to the attribute's type (string or numeric).
#'
#' @param attribute_name A character string representing the name of the Sentinel-1 attribute to filter by. The attribute name must be one of the valid attributes returned by `s1ocn_the$get_attributes_list()`.
#' @param attribute_value The value of the attribute to filter by. The type of the value must correspond to the attribute's value type (e.g., string or numeric). If the value is a string, it will be automatically encoded for the query.
#' @param value_operator A character string representing the comparison operator to use. Accepted values are:
#' - `"eq"` (equal)
#' - `"le"` (less than or equal)
#' - `"ge"` (greater than or equal)
#' - `"lt"` (less than)
#' - `"gt"` (greater than)
#' Defaults to `"eq"`.
#'
#' @return A character string representing the OData query formatted for Sentinel-1 attributes, with the specified attribute name, value, and operator.
#'
#' @details
#' The function works as follows:
#' 1. **Operator Validation:** The provided `value_operator` is validated to ensure it is one of the accepted values.
#' 2. **Attribute Validation:** The `attribute_name` is validated against the list of acceptable attributes retrieved from `s1ocn_the$get_attributes_list()`. If the attribute is invalid, an error is thrown.
#' 3. **Value Type Handling:** The function determines the attribute's value type from the retrieved attributes list. If the value is a string, it is URL-encoded.
#' 4. **Query Construction:** The function constructs an OData query string in the format required for querying Sentinel-1 attributes.
#'
#' @examples
#' \dontrun{
#' # Build a query for the 'swathIdentifier' attribute with the value 'IW'
#' query <- s1ocn_build_attribute_query("swathIdentifier", "IW")
#' print(query)
#'
#' # Build a query for the 'relativeOrbitNumber' attribute with the value 125 and operator 'gt'
#' query <- s1ocn_build_attribute_query("relativeOrbitNumber", 125, "gt")
#' print(query)
#' }
#'
#' @importFrom rlang arg_match abort is_character
#' @importFrom glue glue
#' @importFrom dplyr filter pull
#' @export
s1ocn_build_attribute_query <- function(attribute_name, attribute_value, value_operator = "eq"){

  Name <- rlang::zap()

  # Ensure that the provided value operator is one of the accepted values
  value_operator <- rlang::arg_match(value_operator, values = c("eq", "le", "ge", "lt", "gt"))

  # Retrieve the list of acceptable attributes
  attributes_list <- s1ocn_the$get_attributes_list()

  # Check if the provided attribute name exists in the list of valid attributes
  if(!attribute_name %in% attributes_list$Name) {
    rlang::abort(glue::glue("{AttributeName} is not a valid attribute", AttributeName = attribute_name))
  }

  # Retrieve the value type of the specified attribute from the attributes list
  value_type <- attributes_list %>%
    dplyr::filter(Name == attribute_name) %>%    # Filter the list for the matching attribute name
    dplyr::pull("ValueType")                     # Extract the corresponding value type

  # If the attribute value is a character, format it for the query (add URL encoding)
  if(rlang::is_character(attribute_value)) {
    attribute_value <- glue::glue("%27{AttributeValue}%27", AttributeValue = attribute_value)
  }

  # Construct the query string using the value type, attribute name, value, and operator
  out <- glue::glue("Attributes/OData.CSC.{ValueType}Attribute/any(att:att/Name%20eq%20%27{AttributeName}%27%20and%20att/OData.CSC.{ValueType}Attribute/Value%20{ValueOperator}%20{AttributeValue})",
                    ValueType = value_type,           # Insert the value type into the query
                    AttributeName = attribute_name,   # Insert the attribute name into the query
                    AttributeValue = attribute_value, # Insert the attribute value into the query
                    ValueOperator = value_operator    # Insert the comparison operator into the query
  )

  # Return the constructed query string
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
#' s1ocn_parse_query_date("invalid-date",
#' default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))
#' # Returns: "2024-09-03T00:00:00.000Z"
#'
#' # Handling NA input by returning the default value
#' s1ocn_parse_query_date(NA,
#' default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))
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
#' polygon <- sf::st_polygon(list(
#' matrix(c(-10, -10, 10, -10, 10, 10, -10, 10, -10, -10), ncol = 2, byrow = TRUE)
#' ))
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

#' Build an OData Search Query for Sentinel-1 Products
#'
#' This function constructs an OData query string to search for Sentinel-1 products based on several filtering criteria.
#' It allows setting filters for  attributes, date ranges, and geographical search areas (polygons).
#' The function integrates with `s1ocn_the$get_attributes_list` to ensure that valid attributes listed in `https://catalogue.dataspace.copernicus.eu/odata/v1/Attributes(SENTINEL-1)` are used in the query.
#'
#' @param max_results An integer representing the maximum number of results to return. Defaults to 20.
#' @param search_polygon An optional search polygon in `sf`, matrix, data frame, or WKT string format. The polygon defines the geographical area to search. If not provided, the query does not include a spatial filter.
#' @param datetime_start The start of the date-time range for the search. Accepts strings in various date-time formats (e.g., "YYYY-MM-DD"). If not provided, defaults to "1900-01-01T00:00:00.000Z".
#' @param datetime_end The end of the date-time range for the search. If not provided, the current date and time in UTC is used.
#' @param attributes_search A list of attribute name-value pairs to filter the results (excluding `productType`, which is handled separately). Each attribute name must be valid according to `s1ocn_the$get_attributes_list()`.
#'
#' @return A character string representing the OData query formatted with the specified filters for querying Sentinel-1 products.
#'
#' @details
#' The function constructs the query as follows:
#' 1. **Base Query:** It starts with a base query that filters the collection to Sentinel-1 products (`Collection/Name eq 'SENTINEL-1'`) and sorts the results by `ContentDate/Start`.
#' 2. **Product Type:** The function appends a filter for the product type (`productType eq 'OCN'`), which is hardcoded in this case.
#' 3. **Attributes:** If additional attributes are provided in the `attributes_search` list, they are validated using `s1ocn_the$get_attributes_list` and appended to the query.
#' 4. **Date-Time Range:** If a `datetime_start` or `datetime_end` is specified, a date filter is added to the query using the specified range.
#' 5. **Search Polygon:** If a search polygon is provided, it is URL-encoded and appended as a spatial filter to the query.
#'
#' @examples
#' \dontrun{
#' # Build a basic query with default parameters
#' query <- s1ocn_build_odata_search_query()
#' print(query)
#'
#' # Build a query with additional attributes and a date range
#' query <- s1ocn_build_odata_search_query(
#'   attributes_search = list(swathIdentifier = "IW", orbitDirection = "DESCENDING"),
#'   datetime_start = "2023-01-01",
#'   datetime_end = "2023-12-31"
#' )
#' print(query)
#'
#' # Build a query with a geographical search polygon
#' polygon <- "POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))"
#' query <- s1ocn_build_odata_search_query(search_polygon = polygon)
#' print(query)
#' }
#'
#' @importFrom glue glue
#' @importFrom purrr reduce2 map_lgl
#' @importFrom rlang zap is_zap
#' @export
s1ocn_build_odata_search_query <- function(max_results = 20, search_polygon = rlang::zap(), datetime_start = rlang::zap(), datetime_end = rlang::zap(), attributes_search = list()) {

  # Build the base URL for the OData query with max results and ordering by ContentDate/Start
  url <- glue::glue("https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top={MaxResults}&$filter=Collection/Name%20eq%20%27SENTINEL-1%27",
                    MaxResults = max_results)

  # Add the product type filter to the query
  product_type_query <- s1ocn_build_attribute_query("productType", "OCN")

  # Append the product type query to the URL
  url <- glue::glue("{url}%20and%20{product_type_query}")

  # Remove the productType attribute from attributes_search since it's already handled
  attributes_search$productType <- NULL

  # If additional attributes are provided, add them to the query
  if(length(attributes_search) > 0) {
    url <- purrr::reduce2(attributes_search, names(attributes_search),
                          \(url_so_far, attribute_value, attribute_name) {
                            # Build the attribute query for each attribute in the list
                            attribute_query <- s1ocn_build_attribute_query(attribute_name, attribute_value, value_operator = "eq")
                            # Append the attribute query to the URL
                            glue::glue("{url_so_far}%20and%20{attribute_query}")
                          },
                          .init = url)
  }

  # Handle the datetime filters if they are provided
  if(!all(purrr::map_lgl(c(datetime_start, datetime_end), \(x) rlang::is_zap(x)))) {

    # Set default start date if not provided
    datetime_start <- if(rlang::is_zap(datetime_start)) "1900-01-01T00:00:00.000Z" else s1ocn_parse_query_date(datetime_start)

    # Set default end date if not provided (current UTC time)
    datetime_end <- if(rlang::is_zap(datetime_end)) s1ocn_parse_query_date(lubridate::now(tzone = "UTC")) else s1ocn_parse_query_date(datetime_end)

    # Append the datetime filter to the URL
    url <- glue::glue("{url}%20and%20ContentDate/Start%20ge%20{StartPeriod}%20and%20ContentDate/Start%20le%20{EndPeriod}",
                      StartPeriod = datetime_start,
                      EndPeriod = datetime_end)
  }

  # Handle the search polygon if provided
  if(!rlang::is_zap(search_polygon)) {

    # Convert and format the search polygon for URL encoding
    search_polygon %<>% s1ocn_parse_search_polygon()

    # Build the search polygon query
    search_polygon_query  <- glue::glue("OData.CSC.Intersects(area=geography%27SRID=4326;{SearchPolygon}%27)",
                                        SearchPolygon = search_polygon)
    # Append the search polygon query to the URL
    url <- glue::glue("{url}%20and%20{search_polygon_query}")
  }

  # Convert the final URL to a character string and return it
  url <- as.character(url)

  return(url)
}



#' Retrieve Sentinel-1 Files Based on Filter Criteria
#'
#' This function retrieves a list of Sentinel-1 files based on various search filters, such as attributes, date ranges, and geographical areas.
#' It supports paginated results when the maximum number of results exceeds 1000. The function queries the Copernicus Data Space Catalogue using OData.
#'
#' @param max_results An integer specifying the maximum number of results to return. Defaults to 20. If greater than 1000, pagination will be handled automatically.
#' @param search_polygon An optional search polygon in `sf`, matrix, data frame, or WKT string format. The polygon defines the geographical area to search. If not provided, no spatial filter is applied.
#' @param datetime_start An optional date-time string specifying the start of the date range for the search. Accepts various date-time formats (e.g., "YYYY-MM-DD"). If not provided, defaults to "1900-01-01T00:00:00.000Z".
#' @param datetime_end An optional date-time string specifying the end of the date range for the search. Defaults to the current UTC date and time if not provided.
#' @param attributes_search A list of key-value pairs representing attributes and their corresponding values for filtering the search. Attribute names must be valid according to `s1ocn_the$get_attributes_list()`. The `productType` attribute is handled separately and should not be included in this list.
#'
#' @return A data frame of Sentinel-1 files matching the search criteria. If no files are found, the function returns `rlang::zap()`.
#'
#' @details
#' The function operates as follows:
#' 1. **Query Construction:** It constructs an OData query based on the provided filter criteria, including attributes, date ranges, and optional geographical areas.
#' 2. **Pagination:** If `max_results` exceeds 1000, the function automatically handles pagination by iterating through multiple result pages.
#' 3. **Data Retrieval:** The function sends a query to the OData API of the Copernicus Data Space Catalogue, reads the JSON response, and processes the result.
#' 4. **Empty Result Handling:** If no files are found, the function returns `rlang::zap()` to signify an empty result.
#'
#' @examples
#' \dontrun{
#' # Retrieve Sentinel-1 files with specified attributes
#' s1ocn_list_files(attributes_search =
#' list(swathIdentifier = "IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125))
#'
#' # Retrieve files with attributes and a date range filter
#' s1ocn_list_files(attributes_search =
#' list(swathIdentifier = "IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125),
#' datetime_start = "2021-01-01")
#'
#' # Retrieve files with attributes, date range, and geographical search polygon
#' search_polygon <- matrix(c(-11, 41, -11, 44, 6, 44, 6, 41, -11, 41), ncol = 2, byrow = TRUE)
#' s1ocn_list_files(attributes_search =
#' list(swathIdentifier = "IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125),
#' datetime_start = "2021-01-01",
#' search_polygon = search_polygon)
#' }
#'
#' @importFrom curl curl
#' @importFrom jsonlite fromJSON
#' @importFrom rlang zap is_zap
#' @importFrom dplyr bind_rows
#' @export
s1ocn_list_files <- function(max_results = 20, search_polygon = rlang::zap(), datetime_start = rlang::zap(), datetime_end = rlang::zap(), attributes_search = list()) {

  # Determine if we need to iterate over multiple pages (when max_results > 1000)
  iterate_pages <- max_results > 1000

  # Limit the maximum results to 1000 to respect API constraints
  max_results <- min(max_results, 1000)

  # Build the OData query URL based on the provided parameters
  url <- s1ocn_build_odata_search_query(max_results = max_results, search_polygon = search_polygon, datetime_start = datetime_start, datetime_end = datetime_end, attributes_search = attributes_search)

  # Open the first connection to the URL
  con1 <- curl::curl(url)

  # Read the response from the connection, suppress warnings during the read
  response <- suppressWarnings(readLines(con1)) %>%
    jsonlite::fromJSON()  # Parse the JSON response

  # Close the first connection after reading the response
  close(con1)

  # Extract the results from the response
  out <- response$value

  # If the result is empty, set the output to 'zap' to signify no results
  out <- if (is.null(out) || length(out) == 0) rlang::zap() else out

  # Continue fetching paginated results if necessary
  while (!rlang::is_zap(out) && iterate_pages && !is.null(response$`@odata.nextLink`)) {

    # Update the URL with the next page link
    url <- as.character(response$`@odata.nextLink`)

    # Open a new connection to the next page URL
    con2 <- curl::curl(url)

    # Read the response from the next page, suppress warnings
    response <- suppressWarnings(readLines(con2)) %>%
      jsonlite::fromJSON()  # Parse the JSON response

    # Close the second connection after reading the response
    close(con2)

    # Append the results from the next page to the existing output
    out %<>% dplyr::bind_rows(response$value)
  }

  # Return the final combined output
  return(out)
}
