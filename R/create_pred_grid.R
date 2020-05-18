create_pred_grid <- function(x, y, z, polygon_edges) {
  
  pred_grid <- expand.grid(
    x = seq(937143, 1900000, 50000),
    y = seq(0, 1500000, 50000),
    z = seq(1000, 2000, 200)
  )
  
  polygons <- bleiglas::cut_polygons(
    polygon_edges, 
    cuts = seq(1000, 2000, 200)
  )
  
  pred_grid_split_by_z <- split(pred_grid, pred_grid$z)

  pred_grid_attributed <- data.table::rbindlist(lapply(z, function(cur_z) {
    grid_points_on_this_z_level <- pred_grid_split_by_z[[as.character(cur_z)]]
    polygons_on_this_z_level <- polygons[[as.character(cur_z)]]
    grid_points_on_this_z_level$id <- pnpmulti(polygons_on_this_z_level, grid_points_on_this_z_level$x, grid_points_on_this_z_level$y)
    return(grid_points_on_this_z_level)
  }))
  
  hu <- pred_grid_attributed %>% dplyr::filter(
    z == 1200
  )
  
  ggplot() +
    geom_point(
      data = hu,
      mapping = aes(x, y, color = as.character(id)),
      alpha = 0.5, size = 10
    ) +
    geom_point(
      data = do.call(rbind, polygons[[1]]),
      mapping = aes(x, y, color = as.character(id)),
      shape = 2, size = 10
    )

  }