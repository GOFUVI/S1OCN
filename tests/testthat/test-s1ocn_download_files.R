test_that("s1ocn_download_files is defined and is exported",{

  testthat::expect_true(is_exported(S1OCN::s1ocn_download_files))

})


test_that("s1ocn_download_files works correctly",{

  credentials <- readLines("tools/credentials")

  search_polygon <- matrix(c(-11, 41, -11, 44, 6, 44, 6, 41, -11, 41), ncol = 2, byrow = TRUE)
  files <- s1ocn_list_files(attributes_search =
  list(swathIdentifier = "IW", orbitDirection = "DESCENDING", relativeOrbitNumber = 125),
  datetime_start = "2021-01-01",
  search_polygon = search_polygon)

  temp_dir <- tempdir()

s1ocn_download_files(files = files, dest = temp_dir, username = credentials[1], passwd = credentials[2])


})
