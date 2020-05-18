hu <- create_pred_grid(polygon_edges) %>% dplyr::filter(
  z == 1011
)

ggplot() +
  geom_point(
    data = hu,
    mapping = aes(x, y, color = as.character(id)),
    alpha = 0.5, size = 10
  ) +
  geom_point(
    data = do.call(rbind, polygons_2D[[1]]),
    mapping = aes(x, y, color = as.character(id)),
    shape = 18, size = 10, alpha = 0.5
  )
