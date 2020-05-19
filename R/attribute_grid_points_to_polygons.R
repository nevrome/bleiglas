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
  
  polygons_2D <- bleiglas::cut_polygons(
    polygon_edges, 
    cuts = unique(pred_grid$z)
  )
  
  pred_grid_split_by_z <- split(pred_grid, pred_grid$z)

  attributed_pred_grid <- data.table::rbindlist(lapply(names(polygons_2D), function(cur_z) {
      
      grid_points_on_this_z_level <- pred_grid_split_by_z[[cur_z]]
      polygons_on_this_z_level <- polygons_2D[[cur_z]]
      
      if (is.null(grid_points_on_this_z_level) || is.null(polygons_on_this_z_level)) {
        return( NULL )
      }
      
      grid_points_on_this_z_level$polygon_id <- as.integer(names(polygons_on_this_z_level))[pnpmulti(
        polygons_on_this_z_level, grid_points_on_this_z_level$x, grid_points_on_this_z_level$y
      )]
      
      return(grid_points_on_this_z_level)
    })
  )
  
  return(attributed_pred_grid)
  
}
