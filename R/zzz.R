#' @useDynLib bleiglas
#' @importFrom Rcpp evalCpp

#' @importFrom data.table ":="
#'
NULL

#' @export
.onUnload <- function(libpath) {
  library.dynam.unload("bleiglas", libpath)
}
