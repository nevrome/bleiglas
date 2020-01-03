#' read_polygon_edges
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
read_polygon_edges <- function(x) {

  polygon_edges <- lapply(
    x,
    function(x) {
      
      string_elems <- x %>% strsplit("§") %>% unlist()
      
      # read id    
      id <- string_elems[1] %>% as.numeric()
      
      # parse polygon vertex coordinates
      vertices_one_poly <- string_elems[2] %>% strsplit(" ") %>% unlist()
      one_poly_many_vertices <- lapply(
        vertices_one_poly,
        function(y) {
          one_poly_one_vertex <- y %>% gsub("\\(", "", .) %>% gsub("\\)", "", .) %>% strsplit(",") %>% unlist() %>% as.numeric()
          return(one_poly_one_vertex)
        }
      ) %>% do.call(rbind, .) 
      colnames(one_poly_many_vertices) <- c("x", "y", "z")
      one_poly_many_vertices %<>% tibble::as_tibble()
      one_poly_many_vertices$in_poly_id <- 0:(nrow(one_poly_many_vertices) - 1)
      
      # parse polygon edge lines
      faces_one_poly <- string_elems[3] %>% strsplit(" ") %>% unlist()
      one_poly_many_connections <- lapply(
        faces_one_poly,
        function(y) {
          one_poly_one_face <- y %>% gsub("\\(", "", .) %>% gsub("\\)", "", .) %>% strsplit(",") %>% unlist() %>% as.numeric()
          one_poly_one_face_connections <- tibble::tibble(
            start = one_poly_one_face,
            stop = one_poly_one_face[c(2:length(one_poly_one_face), 1)]
          )
          return(one_poly_one_face_connections)
        }
      ) %>% do.call(rbind, .) 
      
      connections <- dplyr::left_join(
        one_poly_many_vertices,
        one_poly_many_connections,
        by = c("in_poly_id" = "start")
      ) %>%
        dplyr::left_join(
          one_poly_many_vertices,
          by = c("stop" = "in_poly_id"),
          suffix = c(".a", ".b")
        ) %>%
        dplyr::select(
          -in_poly_id, -stop
        )
      
      connections$id <- id
      
      return(connections)
    }
  ) %>% do.call(rbind, .)

}
