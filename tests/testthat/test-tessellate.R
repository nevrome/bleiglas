context("tessellate")

x <- data.table::data.table(
  id = 1:9,
  x = c(1.5,1,2,1,2,1,2,1,2),
  y = c(1.5,1,1,2,2,1,1,2,2),
  z = c(1.5,1,1,1,1,2,2,2,2)
)

run1 <- tessellate(
  x, x_min = 0, x_max = 3, y_min = 0, y_max = 3, z_min = 0, z_max = 3
)

test_that("tessellate returns an output vector with 9 values", {
  expect_length(run1, 9)
})

test_that("tessellate returns an output vector with the correct %i*%P*%t format and values", {
  expect_equal(
    run1[1],
    "2*(0,0,0) (1.5,0,0) (0,1.5,0) (1.5,1.5,0) (0,0,1.5) (1.5,0,1.5) (0,1.5,1.5) (1.5,1.5,0.75) (0.75,1.5,1.5) (1.5,0.75,1.5)*(1,5,9,7,3) (1,0,4,5) (1,3,2,0) (2,3,7,8,6) (2,6,4,0) (4,6,8,9,5) (7,9,8)"
  )
})

run2 <- tessellate(
  x, x_min = 0, x_max = 3, y_min = 0, y_max = 3, z_min = 0, z_max = 3, 
  output_definition = "%i"
)

test_that("tessellate argument output_definition changes the output format correctly", {
  expect_equal(
    run2,
    c("2", "3", "4", "5", "6", "7", "8", "1", "9")
  )
})

run3 <- tessellate(
  x, x_min = 0, x_max = 3, y_min = 0, y_max = 3, z_min = 0, z_max = 3, 
  options = paste("-g") 
)

test_that("tessellate argument options works and can be used to get different output", {
  expect_gt(
    length(list.files(tempdir(), pattern = ".gnu")), 0
  )
})
