context("normal pipeline")

x <- data.table::data.table(
  id = 1:9,
  x = c(1.5, 1, 2, 1, 2, 1, 2, 1, 2),
  y = c(1.5, 1, 1, 2, 2, 1, 1, 2, 2),
  z = c(1.5, 1, 1, 1, 1, 2, 2, 2, 2)
)

#### tessellate ####

run1 <- tessellate(
  x,
  x_min = 0, x_max = 3, y_min = 0, y_max = 3, z_min = 0, z_max = 3, options = ""
)

test_that("tessellate returns a character vector with 9 values", {
  expect_type(run1, "character")
  expect_length(run1, 9)
})

test_that("tessellate returns an output vector with the correct %i*%P*%t format and values", {
  expect_equal(
    run1[1],
    "2*(0,0,0) (1.5,0,0) (0,1.5,0) (1.5,1.5,0) (0,0,1.5) (1.5,0,1.5) (0,1.5,1.5) (1.5,1.5,0.75) (0.75,1.5,1.5) (1.5,0.75,1.5)*(1,5,9,7,3) (1,0,4,5) (1,3,2,0) (2,3,7,8,6) (2,6,4,0) (4,6,8,9,5) (7,9,8)"
  )
})

run2 <- tessellate(
  x,
  x_min = 0, x_max = 3, y_min = 0, y_max = 3, z_min = 0, z_max = 3,
  output_definition = "%i", options = ""
)

test_that("tessellate argument output_definition changes the output format correctly", {
  expect_equal(
    run2,
    c("2", "3", "4", "5", "6", "7", "8", "1", "9")
  )
})

run3 <- tessellate(
  x,
  x_min = 0, x_max = 3, y_min = 0, y_max = 3, z_min = 0, z_max = 3,
  options = "-g"
)

test_that("tessellate argument options works and can be used to get different output", {
  expect_gt(
    length(list.files(tempdir(), pattern = ".gnu")), 0
  )
})

#### read polygon edges ####

polygon_edges <- read_polygon_edges(run1)

test_that("read_polygon_edges can read the default tessellate output correctly", {
  expect_s3_class(
    polygon_edges, "data.table"
  )
  expect_equal(
    nrow(polygon_edges), 264
  )
  expect_equal(
    unique(polygon_edges$polygon_id), c(2, 3, 4, 5, 6, 7, 8, 1, 9)
  )
})

#### cut_surfaces ####

cuts_levels <- c(1, 2, 3, 4)
cut_surfaces <- cut_polygons(polygon_edges, cuts_levels)

test_that("cut_polygons can cut the tessellate output as prepared by read_polygons", {
  expect_equal(
    length(cut_surfaces) + 1, length(cuts_levels)
  )
  expect_type(
    cut_surfaces, "list"
  )
  expect_type(
    cut_surfaces[[1]], "list"
  )
  expect_s3_class(
    cut_surfaces[[1]][[1]], "data.frame"
  )
  expect_equal(
    colnames(cut_surfaces[[1]][[1]]), c("x", "y", "z", "polygon_id")
  )
})

#### cut_surfaces_sf ####

cut_surfaces_sf <- cut_polygons_to_sf(cut_surfaces, crs = 25832)

test_that("cut_surfaces_sf transforms the output of cut_surfaces to sf", {
  expect_s3_class(cut_surfaces_sf, "sf")
  expect_true(
    all(cut_surfaces_sf$id %in% 1:9)
  )
})
