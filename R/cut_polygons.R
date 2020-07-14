#' cut_polygons
#'
#' Figuratively cut horizontal slices of a 3D, tessellated cube.
#'
#' @param x data.table with output of voro++ as produced with 
#' \link{tessellate} and then \link{read_polygon_edges}
#' @param cuts numeric vector with z-axis coordinates where cuts should be applied
#'
#' @return list of lists. One list element for each cutting surface and within these
#' data.tables for each 2D polygon that resulted from the cutting operation. 
#' Each data.table holds the corner coordinates for one 2D polygon.
#' 
#' @inherit tessellate examples
#' 
#' @export
cut_polygons <- function(x, cuts) {

  checkmate::assert_data_table(x, min.rows = 6)
  checkmate::assert_names(colnames(x), identical.to = c("x.a", "y.a", "z.a", "x.b", "y.b", "z.b", "polygon_id"))
  checkmate::assert_numeric(cuts, any.missing = FALSE, all.missing = FALSE)
  
  polygon_2D_dfs_per_cut_list <- lapply(
    cuts, function(z) {
      polygon_2D_dfs_list <- lapply(
        split(x, x$polygon_id), function(y, z) {
          
          # for future Clemens: that already is a very fast combination
          intersection_points <- do.call(
            rbind, 
            line_segment_plane_intersection_multi(as.matrix(y[,c(1,2,3,4,5,6)]), c(0, 0, z), c(0, 0, 1))
          )
          
          if (is.null(intersection_points) || nrow(intersection_points) < 3 || any(is.na(intersection_points))) {
            return(NULL)
          }
          
          convex_hull_order <- grDevices::chull(intersection_points[,1], intersection_points[,2])

          polygon_2d_df <- as.data.frame(intersection_points[c(convex_hull_order, convex_hull_order[1]),])
          colnames(polygon_2d_df) <- c("x", "y", "z")
          polygon_2d_df$polygon_id <- y$polygon_id[1]
          
          return(polygon_2d_df)
        },
        z
      )
      polygon_2D_dfs_list <- Filter(Negate(is.null), polygon_2D_dfs_list)
      if (length(polygon_2D_dfs_list) == 0) {
        return(NULL)
      } else {
        return(polygon_2D_dfs_list)
      }
    })
  
  polygon_2D_dfs_per_cut_list_without_empty <- Filter(Negate(is.null), polygon_2D_dfs_per_cut_list)
  names(polygon_2D_dfs_per_cut_list_without_empty) <- cuts[!sapply(polygon_2D_dfs_per_cut_list, function(x) {is.null(x)})]

  return(polygon_2D_dfs_per_cut_list_without_empty)
  
}
