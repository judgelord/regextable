#' regextable: Tools for Regex Extraction and Cleaning
#'
#' The regextable package provides functions for extracting patterns from text
#' using regex lookup tables and cleaning text data. It is particularly useful
#' for text analysis tasks where you need to match multiple patterns.
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{extract}} - Extract pattern matches from text using regex lookup
#'   \item \code{\link{clean_text}} - Clean and normalize text for consistent matching
#' }
#'
#' @section Datasets:
#' \itemize{
#'   \item \code{\link{members}} - Lookup table of member names for regex matching
#'   \item \code{\link{cr2007_03_01}} - Sample text data for demonstration
#' }
#'
#' @docType package
#' @name regextable
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dplyr %>%
#' @importFrom pbapply pblapply
#' @importFrom stringi stri_detect_regex
## usethis namespace: end
NULL