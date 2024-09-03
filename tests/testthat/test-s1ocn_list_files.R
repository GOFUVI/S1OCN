
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

