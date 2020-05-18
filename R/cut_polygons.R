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
          intersection_points <- do.call(
            rbind, 
            line_segment_plane_intersection_multi(as.matrix(x[,c(1,2,3,4,5,6)]), c(0, 0, z), c(0, 0, 1))                             
          )
          
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
      polygon_2D_dfs_list <- Filter(Negate(is.null), polygon_2D_dfs_list)
      return(polygon_2D_dfs_list)
    })
  
  polygon_2D_dfs_per_cut_list <- Filter(Negate(is.null), polygon_2D_dfs_per_cut_list)
  names(polygon_2D_dfs_per_cut_list) <- cuts

  return(polygon_2D_dfs_per_cut_list)
  
}
