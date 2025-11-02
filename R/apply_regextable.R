#' @title Apply a regex table to clean text
#' @description Replaces patterns in text using a table of regex patterns and replacements.
#' @param x Character vector to clean.
#' @param table Data frame with columns `pattern` and `replacement`.
#' @return Cleaned character vector.
#' @export

apply_regextable <- function(x, table) {
  stopifnot(is.character(x)) #checks if x is a character vector
  stopifnot(all(c("pattern", "replacement") %in% names(table))) #makes sure the table has columns named pattern and replacement
  stopifnot(requireNamespace("stringi", quietly=TRUE)) #use stringi for vectorized operations
  
  #replaces all matches in a character vector
  stringi::stri_replace_all_regex(
    str=x,
    pattern=table$pattern,
    replacement=table$replacement,
    vectorize_all=FALSE, #applies all patterns to each string in one pass
    opts_regex=list(case_insensitive=TRUE)
  )
}
