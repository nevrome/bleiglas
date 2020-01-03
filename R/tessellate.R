tessellate <- function(x) {

  to_voro <- tempfile()
  from_voro <- paste0(to_voro, ".vol")
  
  readr::write_delim(x, path = to_voro, col_names = F)
  
  system(paste(
    "voro++",
    # output string
    "-c %i§%P§%t",
    # verbose
    "-v",
    # x_min x_max y_min y_max z_min z_max
    min(x$x),
    max(x$x),
    min(x$y),
    max(x$y),
    min(x$z),
    max(x$z),
    to_voro
  ))
  
  poly_raw <- readLines(from_voro)
  return(poly_raw)
  
}
