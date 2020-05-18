library(magrittr)
library(ggplot2)

# download raw data
c14_cmr <- c14bazAAR::get_c14data("adrac") %>% 
  # filter data
  dplyr::filter(!is.na(lat) & !is.na(lon), c14age > 1000, c14age < 3000, country == "CMR") 

# remove doubles
c14_cmr_unique <- c14_cmr %>%
  dplyr::mutate(
    rounded_coords_lat = round(lat, 3),
    rounded_coords_lon = round(lon, 3)
  ) %>%
  dplyr::group_by(rounded_coords_lat, rounded_coords_lon, c14age) %>%
  dplyr::filter(dplyr::row_number() == 1) %>%
  dplyr::ungroup()

# transform coordinates
coords <- data.frame(c14_cmr_unique$lon, c14_cmr_unique$lat) %>% 
  sf::st_as_sf(coords = c(1, 2), crs = 4326) %>% 
  sf::st_transform(crs = 4088) %>% 
  sf::st_coordinates()

# create active dataset
c14 <- c14_cmr_unique %>% 
  dplyr::transmute(
    id = 1:nrow(.),
    x = coords[,1], 
    y = coords[,2], 
    z = c14age * 1000, # rescaling of temporal data
    material = material
  )



raw_voro_output <- bleiglas::tessellate(
  c14[, c("id", "x", "y", "z")],
  x_min = min(c14$x) - 150000, x_max = max(c14$x) + 150000, 
  y_min = min(c14$y) - 150000, y_max = max(c14$y) + 150000
)

polygon_edges <- bleiglas::read_polygon_edges(raw_voro_output)

polygon_edges %<>% dplyr::mutate(
  z.a = z.a / 1000,
  z.b = z.b / 1000
)

c14 %<>% dplyr::mutate(
  z = z / 1000
)

pred_grid <- expand.grid(
  x = seq(min(c(polygon_edges$x.a, polygon_edges$x.b)) + 1, max(c(polygon_edges$x.a, polygon_edges$x.b)) - 1, by = 50000),
  y = seq(min(c(polygon_edges$y.a, polygon_edges$y.b)) + 1, max(c(polygon_edges$y.a, polygon_edges$y.b)) - 1, by = 50000),
  z = seq(min(c(polygon_edges$z.a, polygon_edges$z.b)) + 1, max(c(polygon_edges$z.a, polygon_edges$z.b)) - 1, by = 200)
)

pred_grid$polygon_id <- bleiglas::attribute_grid_points(polygon_edges, pred_grid)

spu <- pred_grid %>% data.table::merge.data.table(
  c14 %>% dplyr::select(id, material), by.x = "polygon_id", by.y = "id"
)

ggplot() +
  geom_point(
    data = spu %>% dplyr::filter(z == 2611),
    mapping = aes(x, y, color = material),
    alpha = 0.5, size = 10
  )
