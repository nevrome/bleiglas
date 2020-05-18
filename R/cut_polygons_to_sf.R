#' cut_polygons_to_sf
#'
#' @param x data.table. Output of cut_polygons
#' @param crs coordinate reference system of the resulting 2D polygons
#'
#' @export
cut_polygons_to_sf <- function(x, crs) {
  
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
