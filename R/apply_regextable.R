#' @title Apply a regex table to clean text
#' @description Replaces patterns in text using a table of regex patterns and replacements.
#' @param x Character vector to clean.
#' @param table Data frame with columns `pattern` and `replacement`.
#' @return Cleaned character vector.
#' @export

apply_regextable <- function(x, table) {
  stopifnot(is.character(x))
  stopifnot(all(c("pattern", "replacement") %in% names(table)))
  
  for (i in seq_len(nrow(table))) {
    x <- gsub(table$pattern[i], table$replacement[i], x, perl = TRUE)
  }
  
  x
}
