#' Title
#'
#' @param x 
#' @param cuts 
#' @param crs 
#'
#' @return
#' @export
#'
#' @examples
cut_polygons <- function(x, cuts, crs) {

  ju <- pbapply::pblapply(
    cuts, function(z) {
      lapply(
        split(x, x$id), function(x, z) {
          
          intersection_points <- by(
            x, 1:nrow(x), function(y, z) {
              line_plane_intersection(c(y$x.a, y$y.a, y$z.a), c(y$x.b, y$y.b, y$z.b), z)
            }, 
            z
          ) %>% 
            do.call(rbind, .) %>%
            as.data.frame()
          
          if (nrow(intersection_points) < 3 | any(is.na(intersection_points))) {
            return(NULL)
          }
          
          hull_polygon <- intersection_points %>%
            sf::st_as_sf(coords = c(1, 2), crs = crs) %>%
            #sf::st_union() %>%
            concaveman::concaveman() %>%
            #sf::st_convex_hull() %>% plot
            sf::st_as_sf() %>%
            dplyr::mutate(
              time = z
            )
          hull_polygon$id <- x$id[1]
          
          return(hull_polygon)
        },
        z
      ) %>% 
        purrr::compact() %>%
        mapedit:::combine_list_of_sf(.)
    })
  
  schu <- ju %>% purrr::compact() %>% mapedit:::combine_list_of_sf(.)

  return(schu)
  
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
