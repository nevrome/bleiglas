#' @useDynLib bleiglas
#' @importFrom Rcpp evalCpp

#' @export
.onUnload <- function (libpath) {
  library.dynam.unload("bleiglas", libpath)
}