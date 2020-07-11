# This code runs before the tests.

random_unique_points <- unique(data.table::data.table(
  id = NA,
  x = runif(10),
  y = runif(10),
  z = runif(10)
))
random_unique_points$id <- 1:10

voro_output <- tessellate(random_unique_points)

polygon_points <- read_polygon_edges(voro_output)

cut_surfaces <- cut_polygons(polygon_points, c(0.2, 0.4, 0.6))

cut_surfaces_sf <- cut_polygons_to_sf(cut_surfaces, crs = 25832)