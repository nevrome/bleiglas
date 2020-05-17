#' cut_polygons
#'
#' Figuratively cut horizontal slices of a 3D, tessellated cube.
#'
#' @param x data.frame with output of voro++ as produced with 
#' \link{tessellate} and then \link{read_polygon_edges}
#' @param cuts numeric vector with z-axis coordinates where cuts should be applied
#'
#' @return simple features object with 2D polygons that result from the cutting operation
#' 
#' @export
cut_polygons <- function(x, cuts) {

  # decide if lapply or pblapply should be used
  if (nrow(x) <= 25000) {
    map_fun <- lapply
  } else {
    map_fun <- pbapply::pblapply
  }
  
  polygon_2D_dfs_per_cut_list <- map_fun(
    cuts, function(z) {
      polygon_2D_dfs_list <- lapply(
        split(x, x$id), function(x, z) {
          
          # for future Clemens: that already is a very fast combination
          intersection_points <- do.call(rbind, by(
            x, 1:nrow(x), function(y, z) {
              line_plane_intersection(c(y$x.a, y$y.a, y$z.a), c(y$x.b, y$y.b, y$z.b), z)
            }, 
            z
          ))

          if (is.null(intersection_points) || nrow(intersection_points) < 3 || any(is.na(intersection_points))) {
            return(NULL)
          }
          
          convex_hull_order <- grDevices::chull(intersection_points[,1], intersection_points[,2])

          polygon_2d_df <- as.data.frame(intersection_points[c(convex_hull_order, convex_hull_order[1]),])
          colnames(polygon_2d_df) <- c("x", "y", "z")
          polygon_2d_df$id <- x$id[1]
          polygon_2d_df$time <- z
          
          return(polygon_2d_df)
        },
        z
      )
      data.table::rbindlist(polygon_2D_dfs)
    })
  
  return(tibble::as_tibble(data.table::rbindlist(polygon_2D_dfs_per_cut_list)))
  
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
  return(matrix(point, ncol = 3))
}
