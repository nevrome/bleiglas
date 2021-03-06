# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#' Find the intersection points of a line segment and a plane
#' Based on this solution:
#' \url{https://rosettacode.org/wiki/Find_the_intersection_of_a_line_with_a_plane#C.2B.2B}
#' @noRd
line_segment_plane_intersection <- function(point_a, point_b, plane_point, plane_normal) {
    .Call('_bleiglas_line_segment_plane_intersection', PACKAGE = 'bleiglas', point_a, point_b, plane_point, plane_normal)
}

#' Find the intersection points of multiple line segments and a plane
#' @noRd
line_segment_plane_intersection_multi <- function(points, plane_point, plane_normal) {
    .Call('_bleiglas_line_segment_plane_intersection_multi', PACKAGE = 'bleiglas', points, plane_point, plane_normal)
}

#' Check if a point is within a polygon (2D)
#' Based on this solution:
#' Copyright (c) 1970-2003, Wm. Randolph Franklin
#' \url{http://wrf.ecse.rpi.edu/pmwiki/pmwiki.php/Main/Software#toc24}
#' For discussion see: \url{http://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon/2922778#2922778}
#' @noRd
pnp <- function(vertx, verty, testx, testy) {
    .Call('_bleiglas_pnp', PACKAGE = 'bleiglas', vertx, verty, testx, testy)
}

#' Check if multiple points are within multiple polygons (2D)
#' @noRd
pnpmulti <- function(polygons, testx, testy) {
    .Call('_bleiglas_pnpmulti', PACKAGE = 'bleiglas', polygons, testx, testy)
}

