#' read_polygon_edges
#'
#' Special reader function for polygon edge output of voro++.
#'
#' @param x character vector with raw, linewise output of voro++ as produced with 
#' \link{tessellate} when \code{output_definition = "\%i*\%P*\%t"} 
#'
#' @return data.frame with columns for the coordinates x, y and z of the starting and 
#' end point of each polygon edge
#' 
#' @export
read_polygon_edges <- function(x) {

  # apply read for each polygon
  polygon_edges_list <- lapply(
    x,
    function(x) {
      
      string_elems <- unlist(strsplit(x, "\\*"))
      
      # parse polygon vertex coordinates
      vertices_one_poly <- lapply(strsplit(gsub("\\(|\\)", "", unlist(strsplit(string_elems[2], " "))), ","), as.numeric)
      one_poly_many_vertices <- data.table::as.data.table(data.table::transpose(vertices_one_poly))
      colnames(one_poly_many_vertices) <- c("x", "y", "z")
      one_poly_many_vertices$in_poly_id <- 0:(nrow(one_poly_many_vertices) - 1)
      
      # parse polygon edge lines
      faces_one_poly <- lapply(strsplit(gsub("\\(|\\)", "", unlist(strsplit(string_elems[3], " "))), ","), as.numeric)
      one_poly_many_connections_start <- unlist(faces_one_poly)
      one_poly_many_connections_stop <- unlist(lapply(faces_one_poly, function(y) { y[c(2:length(y), 1)] }))
      one_poly_many_connections <- data.table::data.table(start = one_poly_many_connections_start, stop = one_poly_many_connections_stop)
      
      # merge vertex and edge information
      connections.a <- data.table::merge.data.table(
        one_poly_many_connections,
        one_poly_many_vertices,
        by.x = "start",
        by.y = "in_poly_id"
      )
      connections <- data.table::merge.data.table(
          connections.a,
          one_poly_many_vertices,
          by.x = "stop",
          by.y = "in_poly_id",
          suffixes = c(".a", ".b")
        ) 

      connections$polygon_id <- as.integer(string_elems[1])
      
      return(connections)
    }
  )
  
  polygon_edges <- data.table::rbindlist(polygon_edges_list)
  
  return(polygon_edges[,-c(1, 2)])

}
