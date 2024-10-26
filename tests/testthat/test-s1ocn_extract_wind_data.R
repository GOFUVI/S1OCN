test_that("s1ocn_extrat_wind_data_from_files works correctly",{

  credentials <- readLines("tools/credentials")

  search_polygon <- matrix(c(-11, 41, -11, 44, 6, 44, 6, 41, -11, 41), ncol = 2, byrow = TRUE)
  files <- s1ocn_list_files(attributes_search =
                              list(swathIdentifier = "IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125),
                            datetime_start = "2021-01-01",
                            search_polygon = search_polygon,max_results = 1
                            )

  temp_dir <- tempdir()

  files <- s1ocn_download_files(files = files, dest = temp_dir, username = credentials[1], passwd = credentials[2], workers = 1)



  test <- s1ocn_extrat_wind_data_from_files(files, workers = 1)



})


test_that("s1ocn_extrat_wind_data_from_files works correctly",{

  credentials <- readLines("tools/credentials")

  search_polygon <- matrix(c(-11, 41, -11, 44, 6, 44, 6, 41, -11, 41), ncol = 2, byrow = TRUE)
  files <- s1ocn_list_files(attributes_search =
                              list(swathIdentifier = "IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125),
                            datetime_start = "2021-01-01",
                            search_polygon = search_polygon,max_results = 3
  )

  temp_dir <- tempdir()

  files <- s1ocn_download_files(files = files, dest = temp_dir, username = credentials[1], passwd = credentials[2], workers = 1)



  data <- s1ocn_extrat_wind_data_from_files(files, workers = 1)

  test <- s1ocn_wind_data_list_to_tables(data)

})
