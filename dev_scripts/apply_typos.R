#' @title Fix typos in text
#' @description Applies user-supplied table of typos to a character vector.
#' @param x Character vector to process.
#' @param table A 2-column data frame or matrix: first column = pattern to replace, second column = replacement.
#' @param verbose Logical; whether to display a progress bar. Default TRUE.
#' @return Character vector with replacements applied

apply_typos <- function(x, table, verbose = TRUE){
   
  # If no table is provided, return original text
  if (is.null(table)) {
    return(x)
  }
  
  # Ensures table is a data frame with strings and has exactly 2 columns
  table <- as.data.frame(table, stringsAsFactors = FALSE)
  if (ncol(table) != 2) {
    stop("'table' must have exactly two columns: pattern and replacement")
  }
  
  # Optional: initialize progress bar
  if (verbose) {
    message("Apply user-supplied corrections...")
    pb <- pbapply::startpb(0, nrow(table))
  }
  
  # Apply each pattern replacement in sequence
  for (i in seq_len(nrow(table))) {
    x <- stringr::str_replace_all(x, table[[1]][i], table[[2]][i])
    if (verbose) {
      pbapply::setpb(pb, i)
    }
  }
  
  # Close progress bar
  if (verbose) {
    pbapply::closepb(pb)
  }
  
  #remove extra spaces after replacements
  x <- stringr::str_squish(x)
  x
}