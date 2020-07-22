context("predict grid")

test_data_set <- lapply(1:5, function(i) {
  current_iteration <- data.table::data.table(
    id = 1:5,
    x = c(1, 2, 3, 2, 1) + rnorm(5, 0, 0.1),
    y = c(3, 1, 4, 4, 3) + rnorm(5, 0, 0.1),
    z = c(1, 3, 4, 2, 5) + rnorm(5, 0, 0.1),
    value1 = c("Brot", "Kaese", "Wurst", "Gurke", "Brot"),
    value2 = c(5.3, 5.1, 5.8, 1.0, 1.2)
  )
  data.table::setkey(current_iteration, "x", "y", "z")
  unique( current_iteration )
})

all_iterations <- data.table::rbindlist(test_data_set)
prediction_grid <- expand.grid(
  x = seq(min(all_iterations$x), max(all_iterations$x), length.out = 10),
  y = seq(min(all_iterations$y), max(all_iterations$y), length.out = 10),
  z = seq(min(all_iterations$z), max(all_iterations$z), length.out = 5)
)

prediction_list <- predict_grid(test_data_set, prediction_grid, cl = 1)

test_that("predict_grid produces the expected output structure", {
  expect_type(
    prediction_list, "list"
  )
  expect_s3_class(
    prediction_list[[1]], "data.table"
  )
  expect_equal(
    colnames(prediction_list[[1]]), c("polygon_id", "x", "y", "z", "value1", "value2", "run")
  )
})
