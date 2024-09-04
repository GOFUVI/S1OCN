
test_that("s1ocn_list_files is defined and is exported",{

  testthat::expect_true(is_exported(S1OCN::s1ocn_list_files))

})

#### s1ocn_parse_query_date ####

describe("s1ocn_parse_query_date", {

  it("returns a properly formatted date-time string for ymd_hms input", {
    # Input with full date-time format (year, month, day, hour, minute, second)
    input <- "2024-09-03 14:23:45"
    expected <- "2024-09-03T14:23:45.000Z"

    result <- s1ocn_parse_query_date(input)

    # Expect the result to match the expected ISO 8601 format
    expect_equal(result, expected)
  })

  it("returns a properly formatted date-time string for ymd_hm input", {
    # Input with date-time format without seconds (year, month, day, hour, minute)
    input <- "2024-09-03 14:23"
    expected <- "2024-09-03T14:23:00.000Z"

    result <- s1ocn_parse_query_date(input)

    # Expect the result to match the expected ISO 8601 format
    expect_equal(result, expected)
  })

  it("returns a properly formatted date-time string for ymd_h input", {
    # Input with date-time format without minutes and seconds (year, month, day, hour)
    input <- "2024-09-03 14"
    expected <- "2024-09-03T14:00:00.000Z"

    result <- s1ocn_parse_query_date(input)

    # Expect the result to match the expected ISO 8601 format
    expect_equal(result, expected)
  })

  it("returns a properly formatted date string for ymd input", {
    # Input with only date format (year, month, day)
    input <- "2024-09-03"
    expected <- "2024-09-03T00:00:00.000Z"

    result <- s1ocn_parse_query_date(input)

    # Expect the result to match the expected ISO 8601 format
    expect_equal(result, expected)
  })

  it("returns the default value when input is invalid", {
    # Input that is not a valid date format
    input <- "invalid-date"

    # Mock the default value to a known fixed time
    default_time <- "2024-09-03T00:00:00.000Z"
    result <- s1ocn_parse_query_date(input, default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))

    # Expect the result to be the mocked default value
    expect_equal(result, default_time)
  })

  it("handles NA input by returning the default value", {
    # NA input should return the default value
    result <- s1ocn_parse_query_date(NA, default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))

    # Expect the result to be the mocked default value
    expect_equal(result, "2024-09-03T00:00:00.000Z")
  })

  it("returns the default value if parsing fails after trying all formats", {
    # Input with incorrect format that doesn't match any valid date-time format
    input <- "Wrong format"

    # Mock the default value to a known fixed time
    default_time <- "2024-09-03T00:00:00.000Z"
    result <- s1ocn_parse_query_date(input, default = lubridate::ymd_hms("2024-09-03 00:00:00", tz = "UTC"))

    # Expect the result to be the mocked default value
    expect_equal(result, default_time)
  })

})

#### s1ocn_parse_search_polygon ####

describe("s1ocn_parse_search_polygon", {

  it("returns a valid WKT string with %20 after 'POLYGON' and each comma for a valid POLYGON input", {
    # Create a valid polygon as an sf object
    valid_polygon <- sf::st_polygon(list(matrix(c(-10, -10, 10, -10, 10, 10, -10, 10, -10, -10), ncol = 2, byrow = TRUE)))

    # Expected WKT output with %20 after "POLYGON" and each comma
    expected <- "POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))"

    result <- s1ocn_parse_search_polygon(valid_polygon)

    # Expect the result to match the expected WKT string
    expect_equal(result, expected)
  })

  it("returns a valid WKT string with %20 after 'POLYGON' and each comma for a valid data frame input", {
    # Create a data frame representing a polygon
    df_polygon <- data.frame(x = c(-10, 10, 10, -10, -10), y = c(-10, -10, 10, 10, -10))

    # Expected WKT output with %20 after "POLYGON" and each comma
    expected <- "POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))"

    result <- s1ocn_parse_search_polygon(df_polygon)

    # Expect the result to match the expected WKT string
    expect_equal(result, expected)
  })

  it("returns a valid WKT string with %20 after 'POLYGON' and each comma for a valid character input", {
    # Create a WKT string representing a polygon
    wkt_polygon <- "POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))"

    # Expected WKT output with %20 after "POLYGON" and each comma
    expected <- "POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))"

    result <- s1ocn_parse_search_polygon(wkt_polygon)

    # Expect the result to match the expected WKT string
    expect_equal(result, expected)
  })

  it("returns the default WKT string with %20 after 'POLYGON' and each comma when input is invalid", {
    # Provide an invalid input (a random list)
    invalid_input <- list(a = 1, b = 2)

    # Expected WKT for the default worldwide search polygon with %20 after "POLYGON" and each comma
    expected <- "POLYGON%20((-90%20-180,%20-90%20180,%2090%20180,%2090%20-180,%20-90%20-180))"

    result <- s1ocn_parse_search_polygon(invalid_input)

    # Expect the result to be the default worldwide search WKT string with %20 replacements
    expect_equal(result, expected)
  })

  it("returns the default WKT string with %20 after 'POLYGON' and each comma when the input POLYGON is invalid", {
    # Create an invalid polygon (crossing lines)
    invalid_polygon <- sf::st_polygon(list(matrix(c(0, 0, 10, 10, 0, 10, 10, 0, 0, 0), ncol = 2, byrow = TRUE)))

    # Expected WKT for the default worldwide search polygon with %20 after "POLYGON" and each comma
    expected <- "POLYGON%20((-90%20-180,%20-90%20180,%2090%20180,%2090%20-180,%20-90%20-180))"

    result <- s1ocn_parse_search_polygon(invalid_polygon)

    # Expect the result to be the default worldwide search WKT string with %20 replacements
    expect_equal(result, expected)
  })

  it("replaces spaces with %20 in the final WKT string, including after 'POLYGON' and each comma", {
    # Create a simple valid polygon
    valid_polygon <- sf::st_polygon(list(matrix(c(-5, -5, 5, -5, 5, 5, -5, 5, -5, -5), ncol = 2, byrow = TRUE)))

    # Expected WKT output with %20 after "POLYGON" and each comma
    expected <- "POLYGON%20((-5%20-5,%205%20-5,%205%205,%20-5%205,%20-5%20-5))"

    result <- s1ocn_parse_search_polygon(valid_polygon)

    # Expect the result to have spaces replaced with %20
    expect_equal(result, expected)
  })

})

#### s1ocn_build_attribute_query ####

describe("s1ocn_build_attribute_query", {

  it("builds a valid query for string attributes with 'eq' operator", {
    # Test query construction for a string attribute using the default 'eq' operator
    result <- s1ocn_build_attribute_query("swathIdentifier", "IW")

    # Expected query string
    expected <- "Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27swathIdentifier%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27IW%27)"

    # Check that the query is as expected
    expect_equal(result, expected)
  })



  it("builds a valid query for integer attributes with 'gt' operator", {
    # Test query construction for an integer attribute using the 'gt' operator
    result <- s1ocn_build_attribute_query("relativeOrbitNumber", 125, "gt")

    # Expected query string
    expected <- "Attributes/OData.CSC.IntegerAttribute/any(att:att/Name%20eq%20%27relativeOrbitNumber%27%20and%20att/OData.CSC.IntegerAttribute/Value%20gt%20125)"

    # Check that the query is as expected
    expect_equal(result, expected)
  })

  it("throws an error for invalid attribute name", {
    # Test that an error is thrown if the attribute name is invalid
    expect_error(
      s1ocn_build_attribute_query("invalidAttribute", "someValue"),
      regexp = "invalidAttribute is not a valid attribute"
    )
  })

  it("uses the correct value operator when specified", {
    # Test query construction for a string attribute with a custom operator 'le' (less or equal)
    result <- s1ocn_build_attribute_query("orbitDirection", "ASCENDING", "le")

    # Expected query string
    expected <- "Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27orbitDirection%27%20and%20att/OData.CSC.StringAttribute/Value%20le%20%27ASCENDING%27)"

    # Check that the query is as expected
    expect_equal(result, expected)
  })

  it("handles integer attributes without quoting the value", {
    # Test that integer values are not quoted
    result <- s1ocn_build_attribute_query("relativeOrbitNumber", 100, "eq")

    # Expected query string (integer values should not be in quotes)
    expected <- "Attributes/OData.CSC.IntegerAttribute/any(att:att/Name%20eq%20%27relativeOrbitNumber%27%20and%20att/OData.CSC.IntegerAttribute/Value%20eq%20100)"

    # Check that the query is as expected
    expect_equal(result, expected)
  })

})

#### s1ocn_build_odata_search_query ####

describe("s1ocn_build_odata_search_query", {

  it("constructs a basic query with default parameters", {
    # Test the default query without extra parameters
    result <- s1ocn_build_odata_search_query()

    # Expected base query string
    expected <- "https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top=20&$filter=Collection/Name%20eq%20%27SENTINEL-1%27%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27productType%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27OCN%27)"

    # Check that the constructed query matches the expected query
    expect_equal(result, expected)
  })

  it("constructs a query with additional attributes", {
    # Create a list of additional attributes to include in the query
    attributes <- list(swathIdentifier = "IW", orbitDirection = "DESCENDING")

    # Build the query with the additional attributes
    result <- s1ocn_build_odata_search_query(attributes_search = attributes)

    # Expected query string with additional attributes
    expected <- "https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top=20&$filter=Collection/Name%20eq%20%27SENTINEL-1%27%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27productType%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27OCN%27)%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27swathIdentifier%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27IW%27)%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27orbitDirection%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27DESCENDING%27)"

    # Check that the constructed query matches the expected query
    expect_equal(result, expected)
  })

  it("constructs a query with datetime filters", {
    # Build the query with datetime start and end filters
    result <- s1ocn_build_odata_search_query(datetime_start = "2023-01-01", datetime_end = "2023-12-31")

    # Expected query string with datetime filters
    expected <- "https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top=20&$filter=Collection/Name%20eq%20%27SENTINEL-1%27%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27productType%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27OCN%27)%20and%20ContentDate/Start%20ge%202023-01-01T00:00:00.000Z%20and%20ContentDate/Start%20le%202023-12-31T00:00:00.000Z"

    # Check that the constructed query matches the expected query
    expect_equal(result, expected)
  })

  it("constructs a query with a search polygon", {
    # Mock a polygon (this example assumes the WKT is returned properly from the parsing function)
    polygon <- "POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))"

    # Build the query with a search polygon
    result <- s1ocn_build_odata_search_query(search_polygon = polygon)

    # Expected query string with a polygon
    expected <- "https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top=20&$filter=Collection/Name%20eq%20%27SENTINEL-1%27%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27productType%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27OCN%27)%20and%20OData.CSC.Intersects(area=geography%27SRID=4326;POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))%27)"

    # Check that the constructed query matches the expected query
    expect_equal(result, expected)
  })

  it("constructs a query with all parameters", {
    # Test the query with all parameters: attributes, datetime, and polygon
    attributes <- list(swathIdentifier = "IW", orbitDirection = "DESCENDING")
    polygon <- "POLYGON((-10 -10, 10 -10, 10 10, -10 10, -10 -10))"
    datetime_start <- "2023-01-01"
    datetime_end <- "2023-12-31"

    # Build the full query
    result <- s1ocn_build_odata_search_query(attributes_search = attributes, search_polygon = polygon, datetime_start = datetime_start, datetime_end = datetime_end)

    # Expected query string with all parameters
    expected <- "https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$orderby=ContentDate/Start%20asc&$top=20&$filter=Collection/Name%20eq%20%27SENTINEL-1%27%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27productType%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27OCN%27)%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27swathIdentifier%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27IW%27)%20and%20Attributes/OData.CSC.StringAttribute/any(att:att/Name%20eq%20%27orbitDirection%27%20and%20att/OData.CSC.StringAttribute/Value%20eq%20%27DESCENDING%27)%20and%20ContentDate/Start%20ge%202023-01-01T00:00:00.000Z%20and%20ContentDate/Start%20le%202023-12-31T00:00:00.000Z%20and%20OData.CSC.Intersects(area=geography%27SRID=4326;POLYGON%20((-10%20-10,%2010%20-10,%2010%2010,%20-10%2010,%20-10%20-10))%27)"

    # Check that the constructed query matches the expected query
    expect_equal(result, expected)
  })

})

#### s1ocn_list_files ####

describe("s1ocn_list_files", {

  # Factory function to create a mock curl connection that returns different responses on each call
  mock_curl_factory <- function(responses) {
    index <- 1  # Start from the first response
    return(function(...) {
      temp_file <- tempfile()
      writeLines(responses[[index]], temp_file)
      index <<- index + 1  # Increment the index for the next call
      file(temp_file, "r")
    })
  }

  it("returns results for a basic query", {
    # Simulate the API response as a JSON string
    mock_response <- jsonlite::toJSON(list(value = data.frame(id = 1:3, name = c("file1", "file2", "file3"))), auto_unbox = TRUE)

    # Create a mock curl connection using the factory with a single response
    mock_curl <- mock_curl_factory(list(mock_response))

    # Use mockthat to mock curl::curl, let jsonlite::fromJSON behave normally
    mockthat::with_mock(
      `curl::curl` = mock_curl,
      {
        result <- s1ocn_list_files(max_results = 20)

        # Expect the result to be a data frame with 3 rows
        expect_equal(nrow(result), 3)
        expect_equal(result$name, c("file1", "file2", "file3"))
      }
    )
  })

  it("handles paginated results", {
    # Simulate two paginated JSON responses
    mock_response_page1 <- jsonlite::toJSON(list(
      value = data.frame(id = 1:2, name = c("file1", "file2")),
      `@odata.nextLink` = "next_page_url"
    ), auto_unbox = TRUE)

    mock_response_page2 <- jsonlite::toJSON(list(
      value = data.frame(id = 3:4, name = c("file3", "file4"))
    ), auto_unbox = TRUE)

    # Create a mock curl connection using the factory with two responses for pagination
    mock_curl <- mock_curl_factory(list(mock_response_page1, mock_response_page2))

    # Use mockthat to mock curl::curl, let jsonlite::fromJSON behave normally
    mockthat::with_mock(
      `curl::curl` = mock_curl,
      {
        result <- s1ocn_list_files(max_results = 2000)

        # Expect the result to be a data frame with 4 rows
        expect_equal(nrow(result), 4)
        expect_equal(result$name, c("file1", "file2", "file3", "file4"))
      }
    )
  })

  it("returns zap when no files are found", {
    # Simulate an empty API response as a JSON string
    mock_response <- '{"@odata.context":"$metadata#Products","value":[]}'

    # Create a mock curl connection using the factory with an empty response
    mock_curl <- mock_curl_factory(list(mock_response))

    # Use mockthat to mock curl::curl, let jsonlite::fromJSON behave normally
    mockthat::with_mock(
      `curl::curl` = mock_curl,
      {
        result <- s1ocn_list_files(max_results = 20)

        # Expect the result to be zap when no files are found
        expect_true(rlang::is_zap(result))
      }
    )
  })

  it("handles errors when the API call fails", {
    # Simulate an error during the API call
    mock_curl <- mockthat::mock(stop("API call failed"))

    # Use mockthat to mock curl::curl and simulate an error
    mockthat::with_mock(
      `curl::curl` = mock_curl,
      {
        # Expect an error when calling s1ocn_list_files
        expect_error(s1ocn_list_files(max_results = 20), "API call failed")
      }
    )
  })

})





