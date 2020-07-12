predict_grid <- function(
  x,
  prediction_grid,
  cl
) {
  
  x <- lapply(1:5, function(age_resampling_run) {
    current_iteration <- data.table::data.table(
      id = 1:nrow(dates_prepared),
      x = dates_prepared$x,
      y = dates_prepared$y,
      z = sapply(dates_prepared$calage_sample, function(x){ x[age_resampling_run] }),
      burial_type = dates_prepared$burial_type
    )
    data.table::setkey(current_iteration, "x", "y", "z")
    unique( current_iteration ) 
  })
  
  prediction_grid <- expand.grid(
    x = seq(min(all_iterations$x), max(all_iterations$x), length.out = 100),
    y = seq(min(all_iterations$y), max(all_iterations$y), length.out = 100),
    z = seq(min(all_iterations$z), max(all_iterations$z), length.out = 10)
  )
  
  min_x <- min(prediction_grid$x)
  max_x <- max(prediction_grid$x)
  min_y <- min(prediction_grid$y)
  max_y <- max(prediction_grid$y)
  min_z <- min(prediction_grid$z)
  max_z <- max(prediction_grid$z)
  
  res <- pbapply::pblapply(1:length(x), function(i) {
    
    input <- x[[i]]
    
    raw_voro_output <- tessellate(
      input[, c("id", "x", "y", "z")],
      x_min = min_x, x_max = max_x, 
      y_min = min_y, y_max = max_y, 
      z_min = min_z, z_max = max_z,
      options = ""
    )
    
    polygon_edges <- read_polygon_edges(raw_voro_output) 
    
    attributed_pred_grid <- attribute_grid_points_to_polygons(prediction_grid, polygon_edges)
    
    attributed_pred_grid_with_values <- attributed_pred_grid %>% data.table::merge.data.table(
      input[, -c("x", "y", "z")], by.x = "polygon_id", by.y = "id"
    )
    
    attributed_pred_grid_with_values$run <- i
    
    return(attributed_pred_grid_with_values)
    
  }, cl = cl)
  
  return(res)
  
}

#' predict_grid
#'
#' @param polygon_edges test
#' @param prediction_grid test
#'
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
