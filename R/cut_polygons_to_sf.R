#' cut_polygons_to_sf
#'
#' Transform the polygon cut slices to the sf format. This only makes sense
#' if the x and y coordinate of your input dataset are spatial coordinates.
#'
#' @param x list of lists of data.tables. Output of cut_polygons
#' @param crs coordinate reference system of the resulting 2D polygons. 
#' Integer with the EPSG code, or character with proj4string
#' 
#' @inherit tessellate examples
#' 
#' @export
cut_polygons_to_sf <- function(x, crs) {
  
  check_if_packages_are_available("sf")
  
  checkmate::assert_list(x, types = "list", any.missing = FALSE, all.missing = FALSE, min.len = 1)
  for (i in length(x)) {
    for (j in length(x[[i]])) {
      checkmate::check_data_table(
        x[[i]][[j]], types = "numeric", any.missing = FALSE, all.missing = FALSE, min.rows = 3
      )
      checkmate::check_names(
        colnames(x[[i]][[j]]), identical.to = c("x", "y", "z", "polygon_id")
      )
    }
  }
  
  x <- unlist(x, recursive = F)
  
  polygon_list <- lapply(
    x, function(y) {
      sf::st_polygon(list(as.matrix(y[,c(1,2)])))
    }
  )

  polygon_2d_sfc <- sf::st_sfc(polygon_list)
  polygon_2d <- sf::st_as_sf(polygon_2d_sfc)
  sf::st_crs(polygon_2d) <- crs
  
  ids_zs <- do.call(rbind, strsplit(names(x), "\\."))
  polygon_2d$z <- as.numeric(ids_zs[,1])
  polygon_2d$id <- as.numeric(ids_zs[,2])
  
  return(polygon_2d)
  
}
