#' check_if_packages_are_available
#'
#' @param packages_ch packages that should be available
#'
#' @return NULL - called for side effect stop()
#'
#' @keywords internal
#' @noRd
check_if_packages_are_available <- function(packages_ch) {
  if (!all(sapply(packages_ch, function(x) {
    requireNamespace(x, quietly = TRUE)
  }))) {
    stop(
      paste0(
        "R packages ",
        paste(packages_ch, collapse = ", "),
        " needed for this function to work. Please install with ",
        "install.packages(c('", paste(packages_ch, collapse = "', '"), "'))"
      ),
      call. = FALSE
    )
  }
}
