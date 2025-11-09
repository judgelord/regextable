#' @title Fix typos in text
#' @description Applies user-supplied table of typos to a character vector.
#' @param x Character vector to process.
#' @param table A 2-column data frame or matrix: first column = pattern to replace, second column = replacement.
#' @param verbose Logical; whether to display a progress bar. Default TRUE.
#' @return Character vector with replacements applied
#' @export

apply_typos <- function(x, table, verbose = TRUE)