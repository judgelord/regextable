#' @title Fix typos in text
#' @description Applies user-supplied table of typos to a character vector.
#' @param x Character vector to process.
#' @param table A 2-column data frame or matrix: first column = pattern to replace, second column = replacement.
#' @param verbose Logical; whether to display a progress bar. Default TRUE.
#' @return Character vector with replacements applied
#' @export

apply_typos <- function(x, table, verbose = TRUE){
  if (is.null(table)) {
    return(x)
  }
  
  table <- as.data.frame(table, stringsAsFactors = FALSE)
  if (ncol(table) != 2) {
    stop("'table' must have exactly two columns: pattern and replacement")
  }
  
  if (verbose) {
    message("Apply user-supplied corrections...")
    pb <- pbapply::startpb(0, nrow(table))
  }
  
  for (i in seq_len(nrow(table))) {
    x <- stringr::str_replace_all(x, table[[1]][i], table[[2]][i])
    if (verbose) {
      pbapply::setpb(pb, i)
    }
  }
  
  if (verbose) {
    pbapply::closepb(pb)
  }
  
  #remove extra spaces after replacements
  x <- stringr::str_squish(x)
  x
}