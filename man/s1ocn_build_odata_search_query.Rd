% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/s1ocn_list_files.R
\name{s1ocn_build_odata_search_query}
\alias{s1ocn_build_odata_search_query}
\title{Build an OData Search Query for Sentinel-1 Products}
\usage{
s1ocn_build_odata_search_query(
  max_results = 20,
  search_polygon = rlang::zap(),
  datetime_start = rlang::zap(),
  datetime_end = rlang::zap(),
  attributes_search = list()
)
}
\arguments{
\item{max_results}{An integer representing the maximum number of results to return. Defaults to 20.}

\item{search_polygon}{An optional search polygon in \code{sf}, matrix, data frame, or WKT string format. The polygon defines the geographical area to search. If not provided, the query does not include a spatial filter.}

\item{datetime_start}{The start of the date-time range for the search. Accepts strings in various date-time formats (e.g., "YYYY-MM-DD"). If not provided, defaults to "1900-01-01T00:00:00.000Z".}

\item{datetime_end}{The end of the date-time range for the search. If not provided, the current date and time in UTC is used.}

\item{attributes_search}{A list of attribute name-value pairs to filter the results (excluding \code{productType}, which is hardcoded as "OCN"). Each attribute name must be valid according to \code{s1ocn_the$get_attributes_list()}.}
}
\value{
A character string representing the OData query formatted with the specified filters for querying Sentinel-1 products.
}
\description{
This function constructs an OData query string to search for Sentinel-1 products based on several filtering criteria.
It allows setting filters for  attributes, date ranges, and geographical search areas (polygons).
The function integrates with \code{s1ocn_the$get_attributes_list} to ensure that valid attributes listed in \verb{https://catalogue.dataspace.copernicus.eu/odata/v1/Attributes(SENTINEL-1)} are used in the query.
}
\details{
The function constructs the query as follows:
\enumerate{
\item \strong{Base Query:} It starts with a base query that filters the collection to Sentinel-1 products (\verb{Collection/Name eq 'SENTINEL-1'}) and sorts the results by \code{ContentDate/Start}.
\item \strong{Product Type:} The function appends a filter for the product type (\verb{productType eq 'OCN'}), which is hardcoded in this case.
\item \strong{Attributes:} If additional attributes are provided in the \code{attributes_search} list, they are validated using \code{s1ocn_the$get_attributes_list} and appended to the query.
\item \strong{Date-Time Range:} If a \code{datetime_start} or \code{datetime_end} is specified, a date filter is added to the query using the specified range.
\item \strong{Search Polygon:} If a search polygon is provided, it is URL-encoded and appended as a spatial filter to the query.
}
}
\examples{
\dontrun{
# Build a basic query with default parameters
query <- s1ocn_build_odata_search_query()
print(query)

# Build a query with additional attributes and a date range
query <- s1ocn_build_odata_search_query(
  attributes_search = list(swathIdentifier = "IW", orbitDirection = "DESCENDING"),
  datetime_start = "2023-01-01",
  datetime_end = "2023-12-31"
)
print(query)

# Build a query with a geographical search polygon
polygon <- "POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))"
query <- s1ocn_build_odata_search_query(search_polygon = polygon)
print(query)
}

}
