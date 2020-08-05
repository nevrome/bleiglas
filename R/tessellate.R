#' tessellate
#'
#' Command line utility wrapper for the \href{http://math.lbl.gov/voro++}{voro++} software library.
#' voro++ must be installed on your system to use this function.
#'
#' @param x data.table/data.frame with the input points described by four variables (named columns):
#' \itemize{
#'   \item id: id number that is passed to the output polygon (integer)
#'   \item x: x-axis coordinate (numeric)
#'   \item y: y-axis coordinate (numeric)
#'   \item z: z-axis coordinate (numeric)
#' }
#' @param x_min minimum x-axis coordinate of the tessellation box. Default: min(x).
#' These values are automatically multiplied by the scaling factor in \code{unit_scaling}!
#' @param x_max maximum x-axis coordinate of the tessellation box. Default: max(x)
#' @param y_min minimum y-axis coordinate of the tessellation box. Default: min(y)
#' @param y_max maximum y-axis coordinate of the tessellation box. Default: max(y)
#' @param z_min minimum z-axis coordinate of the tessellation box. Default: min(z)
#' @param z_max maximum z-axis coordinate of the tessellation box. Default: max(z)
#' @param unit_scaling numeric vector with 3 scaling factors for x, y and z axis values.
#' As a default setting (c(1,1,1)) tesselate assumes that the values given as x, y and z are comparable in units.
#' If you input spatio-temporal data, make sure that you have units that determine your 3D distance
#' metric the way you intend it to be. For example, if you need 1km=1year, use those units in the input. 
#' Otherwise, rescale appropriately. Mind that the values of *_min and *_max are adjusted 
#' as well by these factors. The unit_scaling parameter is stored as an attribute of the output
#' to scale the output back automatically in \link{read_polygon_edges}.
#' @param output_definition string that describes how the output file of voro++ should be structured.
#' This is passed to the -c option of the command line interface. All possible customization options
#' are documented \href{http://math.lbl.gov/voro++/doc/custom.html}{here}. Default: "\%i*\%P*\%t"
#' @param options string with additional options passed to voro++. All options are documented
#' \href{http://math.lbl.gov/voro++/doc/cmd.html}{here}. Default: "-v"
#' @param voro_path system path to the voro++ executable. Default: "voro++"
#'
#' @return raw, linewise output of voro++ in a character vector with an attribute "unit scaling" (see above)
#'
#' @examples
#' random_unique_points <- unique(data.table::data.table(
#'   id = NA,
#'   x = runif(10, 0, 100000),
#'   y = runif(10, 0, 100000),
#'   z = runif(10, 0, 100)
#' ))
#' random_unique_points$id <- 1:nrow(random_unique_points)
#'
#' voro_output <- tessellate(random_unique_points, unit_scaling = c(0.001, 0.001, 1))
#'
#' polygon_points <- read_polygon_edges(voro_output)
#'
#' cut_surfaces <- cut_polygons(polygon_points, c(20, 40, 60))
#'
#' cut_surfaces_sf <- cut_polygons_to_sf(cut_surfaces, crs = 25832)
#' \donttest{
#' polygons_z_20 <- sf::st_geometry(cut_surfaces_sf[cut_surfaces_sf$z == 20, ])
#' plot(polygons_z_20, col = sf::sf.colors(10, categorical = TRUE))
#' }
#' 
#' @export
tessellate <- function(
  x,
  x_min = NA, x_max = NA, y_min = NA, y_max = NA, z_min = NA, z_max = NA,
  unit_scaling = c(1, 1, 1),
  output_definition = "%i*%P*%t", options = "-v",
  voro_path = "voro++"
) {
  
  checkmate::assert_data_frame(x)
  checkmate::assert_names(colnames(x), must.include = c("id", "x", "y", "z"))
  checkmate::assert_true(nrow(x) == nrow(unique(x[, c("x", "y", "z")])))
  checkmate::assert_numeric(unit_scaling, len = 3)
  checkmate::assert_number(x_min, na.ok = T)
  checkmate::assert_number(x_max, na.ok = T)
  checkmate::assert_number(y_min, na.ok = T)
  checkmate::assert_number(y_max, na.ok = T)
  checkmate::assert_number(z_min, na.ok = T)
  checkmate::assert_number(z_max, na.ok = T)
  checkmate::assert_string(output_definition, na.ok = F)
  checkmate::assert_string(options, na.ok = F)
  checkmate::assert_string(voro_path, na.ok = F)
  check_for_voro(voro_path)
  
  to_voro <- tempfile()
  from_voro <- paste0(to_voro, ".vol")

  # rescaling
  if (!is.na(x_min)) { x_min <- x_min * unit_scaling[1] }
  if (!is.na(x_max)) { x_max <- x_max * unit_scaling[1] }
  if (!is.na(y_min)) { y_min <- y_min * unit_scaling[2] }
  if (!is.na(y_max)) { y_max <- y_max * unit_scaling[2] }
  if (!is.na(z_min)) { z_min <- z_min * unit_scaling[3] }
  if (!is.na(z_max)) { z_max <- z_max * unit_scaling[3] }
  x$x <- x$x * unit_scaling[1]
  x$y <- x$y * unit_scaling[2]
  x$z <- x$z * unit_scaling[3]
  
  # create voro++ input file
  utils::write.table(x, file = to_voro, quote = FALSE, row.names = F, col.names = F)

  # run voro++
  system(paste(
    voro_path,
    # output string
    paste("-c", output_definition),
    # additional options
    options,
    # x_min x_max y_min y_max z_min z_max
    ifelse(is.na(x_min), min(x$x), x_min),
    ifelse(is.na(x_max), max(x$x), x_max),
    ifelse(is.na(y_min), min(x$y), y_min),
    ifelse(is.na(y_max), max(x$y), y_max),
    ifelse(is.na(z_min), min(x$z), z_min),
    ifelse(is.na(z_max), max(x$z), z_max),
    # input file
    to_voro
  ))

  # read voro output
  poly_raw <- readLines(from_voro)
  
  # store unit sclaing as an attribute
  attr(poly_raw, "unit_scaling") <- unit_scaling
  
  return(poly_raw)
}

#' @keywords internal
#' @noRd
check_for_voro <- function(voro_path) {
  tryCatch({
    works <- !substr(system(paste(voro_path, "-h"), intern = TRUE)[1], 1, 6) == "Voro++"
  }, error = function(e) {
    stop_missing_voro()
  })
  if (works) {
    stop_missing_voro()
  }
}

#' @keywords internal
#' @noRd
stop_missing_voro <- function() {
  stop(
    "voro++ does not seem to be avaible. ",
    "Please make sure that it is installed (http://math.lbl.gov/voro++) ",
    "and that voro_path points to the executable."
  )
}

