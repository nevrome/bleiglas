#' #' @param crs coordinate reference system of the resulting 2D polygons
#' 
#' 
#' polygon_2d_raw <- sf::st_polygon(list())
#' polygon_2d_sfc <- sf::st_sfc(polygon_2d_raw)
#' polygon_2d <- sf::st_as_sf(polygon_2d_sfc)
#' 
#' sf::st_crs(polygon_2d) <- crs