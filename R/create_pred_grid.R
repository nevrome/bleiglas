#' create_pred_grid
#'
#' @param polygon_edges test
#' @param res_x test
#' @param res_y test
#' @param res_z test
#'
#' @export
create_pred_grid <- function(
  polygon_edges, 
  res_x = 50000, 
  res_y = 50000, 
  res_z = 200
) {
  
  pred_grid <- expand.grid(
    x = seq(min(c(polygon_edges$x.a, polygon_edges$x.b)) + 1, max(c(polygon_edges$x.a, polygon_edges$x.b)) - 1, by = res_x),
    y = seq(min(c(polygon_edges$y.a, polygon_edges$y.b)) + 1, max(c(polygon_edges$y.a, polygon_edges$y.b)) - 1, by = res_y),
    z = seq(min(c(polygon_edges$z.a, polygon_edges$z.b)) + 1, max(c(polygon_edges$z.a, polygon_edges$z.b)) - 1, by = res_z)
  )
  
  polygons_2D <- bleiglas::cut_polygons(
    polygon_edges, 
    cuts = unique(pred_grid$z)
  )
  
  pred_grid_split_by_z <- split(pred_grid, pred_grid$z)

  pred_grid_attributed <- data.table::rbindlist(
    lapply(names(polygons_2D), function(cur_z) {
      grid_points_on_this_z_level <- pred_grid_split_by_z[[cur_z]]
      polygons_on_this_z_level <- polygons_2D[[cur_z]]
      if (is.null(grid_points_on_this_z_level) || is.null(polygons_on_this_z_level)) {
        return( NULL )
      }
      grid_points_on_this_z_level$id <- as.integer(names(polygons_on_this_z_level))[pnpmulti(
        polygons_on_this_z_level, grid_points_on_this_z_level$x, grid_points_on_this_z_level$y
      )]
      return(grid_points_on_this_z_level)
    })
  )
  
  return(pred_grid_attributed)
  
}
