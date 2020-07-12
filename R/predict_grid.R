#' predict_grid
#'
#' @param x test
#' @param prediction_grid test
#' @param ... test
#' @param polygon_edges test
#' 
#' @return test
#'  
#' @name predict_grid  
#' @export
predict_grid <- function(
  x,
  prediction_grid,
  ...
) {
  
  check_if_packages_are_available("pbapply")
  
  # loop through all position iteration
  pbapply::pblapply(1:length(x), function(i) {
    
    input <- x[[i]]
    
    # tessellate current iteration
    raw_voro_output <- tessellate(
      input[, c("id", "x", "y", "z")],
      x_min = min(prediction_grid$x), x_max = max(prediction_grid$x), 
      y_min = min(prediction_grid$y), y_max = max(prediction_grid$y), 
      z_min = min(prediction_grid$z), z_max = max(prediction_grid$z),
      options = ""
    )
    
    polygon_edges <- read_polygon_edges(raw_voro_output) 
    
    # fit prediction grid points to polygons
    attributed_pred_grid <- attribute_grid_points_to_polygons(prediction_grid, polygon_edges)
    
    # merge polygon values to prediction grid
    attributed_pred_grid_with_values <- data.table::merge.data.table(
      attributed_pred_grid,
      input[, c("x", "y", "z"):=NULL], 
      by.x = "polygon_id", by.y = "id"
    )
    
    # store iteration run number
    attributed_pred_grid_with_values$run <- i
    
    return(attributed_pred_grid_with_values)
    
  }, ...)
  
}

#' @rdname predict_grid  
#' @export
attribute_grid_points_to_polygons <- function(
  prediction_grid,
  polygon_edges
) {
  
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
        return( NULL )
      }
      
      # find out in which polygon a prediction grid point appears
      grid_points_on_this_z_level$polygon_id <- as.integer(names(polygons_on_this_z_level))[
        pnpmulti(
          polygons_on_this_z_level, grid_points_on_this_z_level$x, grid_points_on_this_z_level$y
        )
      ]
      
      return(grid_points_on_this_z_level)
    })
  )
  
  return(attributed_prediction_grid)
  
}
