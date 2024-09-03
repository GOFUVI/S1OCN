s1ocn_the <- rlang::new_environment()

s1ocn_the$cache <- list(
  attibutes_list = rlang::zap()
)


#' Retrieve and Cache the List of Acceptable Attribute Names for Sentinel-1
#'
#' This function retrieves a list of acceptable attribute names and their types for the Copernicus Sentinel-1 Mission.
#' The data is retrieved from the Copernicus Data Space Catalogue via an OData API. To improve performance, the results
#' are cached after the first retrieval. Subsequent calls will return the cached list unless the cache is reset.
#'
#' @return A list of acceptable attribute names and their types for the Sentinel-1 mission, retrieved from the
#' Copernicus Data Space Catalogue. If the data has already been retrieved during the session, the function returns
#' the cached version to avoid unnecessary API calls.
#'
#' @details
#' The function operates as follows:
#' 1. **Cache Check:** The function first checks if the list of attributes is stored in the cache (`s1ocn_the$cache$attibutes_list`).
#'    If the cache is "zapped" (a state indicating it is not set or has been reset), the function proceeds to retrieve the data.
#' 2. **Data Retrieval:** If the cache is empty, the function opens a connection to the OData API at the URL
#'    `https://catalogue.dataspace.copernicus.eu/odata/v1/Attributes(SENTINEL-1)`.
#' 3. **Data Parsing:** The function reads the JSON data from the API and parses it into a list format.
#' 4. **Caching:** After retrieving and parsing the data, the function stores the result in the cache to improve the efficiency of
#'    subsequent calls.
#' 5. **Return:** The function returns the list of attributes, either from the cache or freshly retrieved.
#'
#' The attributes list includes the names of acceptable attributes for querying the Sentinel-1 dataset, along with their respective types.
#'
#' @examples
#' \dontrun{
#' # Retrieve the list of attributes for Sentinel-1
#' attributes_list <- s1ocn_the$get_attributes_list()
#'
#' # View the list of attribute names and types
#' print(attributes_list)
#' }
#'
#' @importFrom curl curl
#' @importFrom jsonlite fromJSON
#' @importFrom rlang is_zap
#' @importFrom magrittr %>%
s1ocn_the$get_attributes_list <- function() {

  # Retrieve the cached attributes list from the object `s1ocn_the`
  out <- s1ocn_the$cache$attibutes_list

  # Check if the cached list is "zapped" (a special null-like state in rlang)
  if(rlang::is_zap(out)) {

    # If the cache is zapped (i.e., empty or not set), open a connection to the URL
    con <- curl::curl("https://catalogue.dataspace.copernicus.eu/odata/v1/Attributes(SENTINEL-1)")

    # Read the data from the connection, suppressing any warnings
    out <- suppressWarnings(
      readLines(con) %>%                   # Read the lines from the connection
        jsonlite::fromJSON()                 # Parse the JSON content from the lines
    )

    # Cache the retrieved attributes list for future use
    s1ocn_the$cache$attibutes_list <- out
  }

  # Return the attributes list (either from the cache or freshly retrieved)
  return(out)
}




