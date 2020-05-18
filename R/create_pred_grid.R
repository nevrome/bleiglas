create_pred_grid <- function(x, y, z, polygon_edges) {
  
  pred_grid <- expand.grid(
    x = seq(0, 100, 5),
    y = seq(0, 100, 5),
    z = seq(1000, 2000, 200)
  )
  
  polygons <- bleiglas::cut_polygons(
    polygon_edges, 
    cuts = seq(1000, 2000, 200)
  )
  
  pred_grid_split_by_z <- split(pred_grid, pred_grid$z)

  lapply(z, function(cur_z) {
    grid_points_on_this_z_level <- pred_grid_split_by_z[[as.character(cur_z)]]
    polygons_on_this_z_level <- polygons[[as.character(cur_z)]]
  })
  z
  
}