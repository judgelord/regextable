#' @title Extract pattern matches from text
#' @description Uses A regex lookup to extract pattern matches from data frame.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Name of the variable in `data` containing text to search.
#' @param regex_table A regex lookup table with at least a pattern column.
#' @param pattern_col Name of the column in regex_table with regex patterns (default "pattern").
#' @param id_col Optional column in regex_table to include as an identifier in the output.
#' @param date_col Optional column in regex_table for date filtering.
#' @param date_start Optional start date for filtering regex_table.
#' @param date_end Optional end date for filtering regex_table.
#' @param pattern_filter Optional expression or vector to filter which patterns to use 
#'   (e.g., a column name with values like "strict", "loose", etc.).
#' @param strict Logical; if TRUE, matches are treated as whole-word; if FALSE, partial matches allowed.
#' @param remove_acronyms Logical; if TRUE, removes all-uppercase patterns from regex_table.
#' @param clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param verbose Logical; whether to display basic progress messages.
#' @return A data frame with one row per match and with all columns.
#' @export

extract <- function(data,
                    col_name,
                    regex_table,
                    pattern_col = "pattern",
                    id_col = NULL,
                    date_col = NULL,
                    date_start = NULL,
                    date_end = NULL,
                    pattern_filter = NULL,
                    strict = TRUE,
                    remove_acronyms = FALSE,
                    clean_text = TRUE,
                    verbose = TRUE) {
  
  # Input validation and preparation (keep your existing code)
  if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    if (missing(col_name)) col_name <- "text"
  } else if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data))
      stop("Please provide a valid column name for `col_name`.")
  } else stop("`data` must be a data frame or character vector.")
  
  data$data_id <- seq_len(nrow(data))
  original_col <- col_name
  
  # Text cleaning
  if (clean_text) {
    if (!requireNamespace("stringr", quietly = TRUE))
      stop("Package 'stringr' is required for text cleaning.")
    data[[original_col]] <- stringr::str_squish(tolower(data[[original_col]]))
  }
  
  # Filter regex_table (keep your existing filtering logic)
  # [Your existing filtering code here...]
  
  # Get patterns after filtering
  patterns <- regex_table[[pattern_col]]
  if (strict) {
    patterns <- paste0("\\b(", patterns, ")\\b")
  }
  
  if (verbose) message("Extracting pattern matches...")
  
  # OPTIMIZED MATCHING APPROACH
  text_vector <- data[[original_col]]
  
  # Combine all patterns into single regex (much faster)
  combined_pattern <- paste(patterns, collapse = "|")
  
  # Vectorized matching
  has_match <- grepl(combined_pattern, text_vector, ignore.case = TRUE, perl = TRUE)
  
  if (sum(has_match) == 0) {
    if (verbose) message("No matches found.")
    return(create_empty_output(id_col))
  }
  
  # Get matching rows
  matched_data <- data[has_match, , drop = FALSE]
  
  # Extract which pattern matched (using str_extract for actual pattern)
  if (requireNamespace("stringr", quietly = TRUE)) {
    matched_data$pattern <- stringr::str_extract(
      matched_data[[original_col]], 
      combined_pattern
    )
  } else {
    # Fallback - less precise but still better than original
    matched_data$pattern <- sapply(matched_data[[original_col]], function(x) {
      matches <- patterns[sapply(patterns, function(p) grepl(p, x, ignore.case = TRUE))]
      if (length(matches) > 0) matches[1] else NA
    })
    matched_data <- matched_data[!is.na(matched_data$pattern), , drop = FALSE]
  }
  
  if (verbose) message("Done. Found ", nrow(matched_data), " matches.")
  return(matched_data)
}

create_empty_output <- function(id_col) {
  out <- data.frame(
    data_id = integer(),
    text = character(),
    pattern = character(),
    stringsAsFactors = FALSE
  )
  if (!is.null(id_col)) out[[id_col]] <- character()
  return(out)
}