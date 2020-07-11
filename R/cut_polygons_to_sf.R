#' cut_polygons_to_sf
#'
#' Transform the polygon cut slices to the sf format. This only makes sense
#' if the x and y coordinate of your input dataset are spatial coordinates.
#'
#' @param x data.table. Output of cut_polygons
#' @param crs coordinate reference system of the resulting 2D polygons. 
#' Integer with the EPSG code, or character with proj4string
#' 
#' @inherit tessellate examples
#' 
#' @export
cut_polygons_to_sf <- function(x, crs) {
  
  check_if_packages_are_available("sf")
  
  x <- unlist(x, recursive = F)
  
  polygon_list <- lapply(
    x, function(y) {
      sf::st_polygon(list(as.matrix(y[,c(1,2)])))
    }
  )

  polygon_2d_sfc <- sf::st_sfc(polygon_list)
  polygon_2d <- sf::st_as_sf(polygon_2d_sfc)
  sf::st_crs(polygon_2d) <- crs
  
  ids_times <- do.call(rbind, strsplit(names(x), "\\."))
  polygon_2d$time <- as.numeric(ids_times[,1])
  polygon_2d$id <- as.numeric(ids_times[,2])
  
  return(polygon_2d)
  
}
