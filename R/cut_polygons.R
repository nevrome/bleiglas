#' cut_polygons
#'
#' Figuratively cut horizontal slices of a 3D, tessellated cube.
#'
#' @param x data.frame with output of voro++ as produced with 
#' \link{tessellate} and then \link{read_polygon_edges}
#' @param cuts numeric vector with z-axis coordinates where cuts should be applied
#' @param crs coordinate reference system of the resulting 2D polygons
#'
#' @return simple features object with 2D polygons that result from the cutting operation
#' 
#' @export
cut_polygons <- function(x, cuts, crs) {

  result_polygons <- lapply(
    cuts, function(z) {
      do.call(rbind, lapply(
        split(x, x$id), function(x, z) {
          
          intersection_points <- as.data.frame(do.call(rbind, by(
            x, 1:nrow(x), function(y, z) {
              line_plane_intersection(c(y$x.a, y$y.a, y$z.a), c(y$x.b, y$y.b, y$z.b), z)
            }, 
            z,
            simplify = FALSE
          )))
          
          if (nrow(intersection_points) < 3 | any(is.na(intersection_points))) {
            return(NULL)
          }

          intersection_points_spatial <- sf::st_as_sf(intersection_points, coords = c(1, 2), crs = crs) 
          polygon_2d <- sf::st_as_sf(sf::st_convex_hull(sf::st_union(intersection_points_spatial)))
          polygon_2d$time <- z
          polygon_2d$id <- x$id[1]
          
          return(polygon_2d)
        },
        z
      ))
    })
  
  return(do.call(rbind, result_polygons))
  
}

line_plane_intersection <- function(point_a, point_b, cutting_height) {
  # check if the line connecting the two points acutally cuts the plane
  if ((point_a[3] > cutting_height) & (point_b[3] > cutting_height) | 
      (point_a[3] < cutting_height) & (point_b[3] < cutting_height)) {
    return(NULL)
  }
  # check if the line is on the plane
  if ((point_a[3] == cutting_height) & (point_b[3] == cutting_height)) {
    # in this case both end points have to be returned
    return(matrix(c(point_a, point_b), 2, 3, byrow = T))
  }
  # prepare base point, vector and plane
  ray_point <- point_a
  ray_vec <- point_a - point_b
  plane_normal <- c(0, 0, 1)
  plane_point <- c(0, 0, cutting_height)
  # calculate point of intersection
  pdiff <- ray_point - plane_point
  prod1 <- pdiff %*% plane_normal
  prod2 <- ray_vec %*% plane_normal
  prod3 <- prod1 / prod2
  point <- ray_point - ray_vec * as.numeric(prod3)
  # return point
  return(point)
}
