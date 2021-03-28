#' predict_grid
#'
#' \code{predict_grid} allows to conveniently use the tessellation output as a
#' model to predict values for arbitrary points. See the bleiglass JOSS paper and
#' \code{vignette("complete_example", "bleiglas")} for an example application.
#' \code{attribute_grid_points_to_polygons} is a helper function that does the
#' important step of point-to-polygon attribution, which might be useful by
#' itself.
#'
#' @param x List of data.tables/data.frames with the input points that define
#' the tessellation model:
#' \itemize{
#'   \item id: id number that is passed to the output polygon (integer)
#'   \item x: x-axis coordinate (numeric)
#'   \item y: y-axis coordinate (numeric)
#'   \item z: z-axis coordinate (numeric)
#'   \item ...: arbitrary variables
#' }
#' @param prediction_grid data.table/data.frame with the points that should be
#' predicted by the tessellation model:
#' \itemize{
#'   \item x: x-axis coordinate (numeric)
#'   \item y: y-axis coordinate (numeric)
#'   \item z: z-axis coordinate (numeric)
#' }
#' @param unit_scaling passed to \link{tessellate} - see the documentation there
#' @param ... Further variables passed to \code{pbapply::pblapply} (e.g. \code{cl})
#' @param polygon_edges polygon points as returned by \code{bleiglas::read_polygon_edges}
#'
#' @return list of data.tables with polygon attribution and predictions
#'
#' @examples
#' x <- lapply(1:5, function(i) {
#'   current_iteration <- data.table::data.table(
#'     id = 1:5,
#'     x = c(1, 2, 3, 2, 1) + rnorm(5, 0, 0.3),
#'     y = c(3, 1, 4, 4, 3) + rnorm(5, 0, 0.3),
#'     z = c(1, 3, 4, 2, 5) + rnorm(5, 0, 0.3),
#'     value1 = c("Brot", "Kaese", "Wurst", "Gurke", "Brot"),
#'     value2 = c(5.3, 5.1, 5.8, 1.0, 1.2)
#'   )
#'   data.table::setkey(current_iteration, "x", "y", "z")
#'   unique(current_iteration)
#' })
#'
#' all_iterations <- data.table::rbindlist(x)
#'
#' prediction_grid <- expand.grid(
#'   x = seq(min(all_iterations$x), max(all_iterations$x), length.out = 10),
#'   y = seq(min(all_iterations$y), max(all_iterations$y), length.out = 10),
#'   z = seq(min(all_iterations$z), max(all_iterations$z), length.out = 5)
#' )
#'
#' bleiglas::predict_grid(x, prediction_grid, cl = 1)
#' @name predict_grid
#' @export
predict_grid <- function(x, prediction_grid, unit_scaling = c(1, 1, 1), ...) {
  
  check_if_packages_are_available("pbapply")

  checkmate::assert_list(x, types = "list", any.missing = FALSE, all.missing = FALSE, min.len = 1)
  for (i in length(x)) {
    checkmate::check_data_table(
      x[[i]],
      any.missing = FALSE, all.missing = FALSE, min.rows = 3
    )
    checkmate::check_names(
      colnames(x[[i]]),
      must.include = c("id", "x", "y", "z")
    )
  }
  checkmate::assert_data_frame(prediction_grid, min.rows = 1, types = "numeric")
  checkmate::assert_names(colnames(prediction_grid), identical.to = c("x", "y", "z"))

  # loop through all position iteration
  pbapply::pblapply(seq_along(x), function(i) {
    input <- x[[i]]

    # tessellate current iteration
    raw_voro_output <- tessellate(
      input[, c("id", "x", "y", "z")],
      x_min = min(prediction_grid$x), x_max = max(prediction_grid$x),
      y_min = min(prediction_grid$y), y_max = max(prediction_grid$y),
      z_min = min(prediction_grid$z), z_max = max(prediction_grid$z),
      unit_scaling = unit_scaling,
      options = ""
    )

    polygon_edges <- read_polygon_edges(raw_voro_output)

    # fit prediction grid points to polygons
    attributed_pred_grid <- attribute_grid_points_to_polygons(prediction_grid, polygon_edges)

    # merge polygon values to prediction grid
    attributed_pred_grid_with_values <- data.table::merge.data.table(
      attributed_pred_grid,
      input[, c("x", "y", "z") := NULL],
      by.x = "polygon_id", by.y = "id"
    )

    # store iteration run number
    attributed_pred_grid_with_values$run <- i

    return(attributed_pred_grid_with_values)
  }, ...)
}

#' @rdname predict_grid
#' @export
attribute_grid_points_to_polygons <- function(prediction_grid, polygon_edges) {

  # cut 3D polygons by z level in prediction grid
  polygons_2D <- bleiglas::cut_polygons(
    polygon_edges,
    cuts = unique(prediction_grid$z)
  )

  # cut prediction grid by the same criterion
  prediction_grid_split_by_z <- split(prediction_grid, prediction_grid$z)

  # check for each prediction point in which polygon it belongs by iterating through each z level
  attributed_prediction_grid <- data.table::rbindlist(lapply(names(polygons_2D), function(cur_z) {

    # get prediction grid and 2D polygon corner points for current z level
    grid_points_on_this_z_level <- prediction_grid_split_by_z[[cur_z]]
    polygons_on_this_z_level <- polygons_2D[[cur_z]]

    # if either is NULL return NULL
    if (is.null(grid_points_on_this_z_level) || is.null(polygons_on_this_z_level)) {
      return(NULL)
    }

    # find out in which polygon a prediction grid point appears
    grid_points_on_this_z_level$polygon_id <- as.integer(names(polygons_on_this_z_level))[
      pnpmulti(
        polygons_on_this_z_level, grid_points_on_this_z_level$x, grid_points_on_this_z_level$y
      )
    ]

    return(grid_points_on_this_z_level)
  }))

  return(attributed_prediction_grid)
}
