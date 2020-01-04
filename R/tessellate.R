#' tessellate
#' 
#' Command line utility wrapper for the \href{http://math.lbl.gov/voro++}{voro++} software library.
#' 
#' @param x data.frame with the input points described by four variables (named columns):
#' \itemize{
#'   \item id: id number that is passed to the output polygon (integer)
#'   \item x: x-axis coordinate (numeric)
#'   \item y: y-axis coordinate (numeric)
#'   \item z: z-axis coordinate (numeric)
#' }
#' @param x_min minimum x-axis coordinate of the box. Default: min(x)
#' @param x_max maximum x-axis coordinate of the box. Default: max(x)
#' @param y_min minimum y-axis coordinate of the box. Default: min(y)
#' @param y_max maximum y-axis coordinate of the box. Default: max(y)
#' @param z_min minimum z-axis coordinate of the box. Default: min(z)
#' @param z_max maximum z-axis coordinate of the box. Default: max(z)
#' @param output_definition string that describes how the output file of voro++ should be structured.
#' This is passed to the -c option of the command line interface. All possible customization options 
#' are documented \href{http://math.lbl.gov/voro++/doc/custom.html}{here}. Default: "\%i§\%P§\%t"
#' @param options string with additional options passed to voro++. All options are documented 
#' \href{http://math.lbl.gov/voro++/doc/cmd.html}{here}. Default: "-v"
#' @param voro_path system path to the voro++ executable. Default: "voro++"
#'
#' @return The raw, linewise output of voro++ in a character vector
#' @export
tessellate <- function(
  x, 
  x_min = NA, x_max = NA, y_min = NA, y_max = NA, z_min = NA, z_max = NA,
  output_definition = "%i§%P§%t", options = "-v",
  voro_path = "voro++"
) {

  to_voro <- tempfile()
  from_voro <- paste0(to_voro, ".vol")
  
  readr::write_delim(x, path = to_voro, col_names = F)
  
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
  
  poly_raw <- readLines(from_voro)
  return(poly_raw)
  
}
