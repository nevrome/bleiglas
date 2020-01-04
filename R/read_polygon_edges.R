#' read_polygon_edges
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
read_polygon_edges <- function(x) {

  polygon_edges_list <- lapply(
    x,
    function(x) {
      
      string_elems <- unlist(strsplit(x, "§"))
      
      # read id    
      id <- as.numeric(string_elems[1])
      
      # parse polygon vertex coordinates
      vertices_one_poly <- lapply(strsplit(gsub("\\(|\\)", "", unlist(strsplit(string_elems[2], " "))), ","), as.numeric)
      one_poly_many_vertices <- data.table::as.data.table(data.table::transpose(vertices_one_poly))
      colnames(one_poly_many_vertices) <- c("x", "y", "z")
      one_poly_many_vertices$in_poly_id <- 0:(nrow(one_poly_many_vertices) - 1)
      
      # parse polygon edge lines
      faces_one_poly <- lapply(strsplit(gsub("\\(|\\)", "", unlist(strsplit(string_elems[3], " "))), ","), as.numeric)
      one_poly_many_connections <- data.table::rbindlist(
        lapply(
          faces_one_poly,
          function(y) {
            data.frame(
              start = y,
              stop = y[c(2:length(y), 1)]
            )
          }
        )
      )
      
      connections.a <- data.table::merge.data.table(
        one_poly_many_vertices,
        one_poly_many_connections,
        by.x = "in_poly_id",
        by.y = "start"
      )
      
      connections <- data.table::merge.data.table(
          connections.a,
          one_poly_many_vertices,
          by.x = "stop",
          by.y = "in_poly_id",
          suffixes = c(".a", ".b")
        ) 

      connections$id <- id
      
      return(connections)
    }
  )
  
  polygon_edges <- data.table::rbindlist(polygon_edges_list)
  
  return(tibble::as_tibble(polygon_edges[,-c(1, 2)]))

}
