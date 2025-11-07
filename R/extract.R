#' @title Extract pattern matches from text
#' @description Uses A regex lookup to extract pattern matches from data frame.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with at least a pattern column.
#' @param pattern_col Name of the column in regex_table with regex patterns (default "pattern").
#' @param id_col Optional column in regex_table to include as an identifier in the output.
#' @param date_col Optional column in regex_table for date filtering.
#' @param date_start Optional start date for filtering regex_table.
#' @param date_end Optional end date for filtering regex_table.
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
                    strict = TRUE,
                    remove_acronyms = FALSE,
                    clean_text = TRUE,
                    verbose = TRUE) {
  
  # Input validation and preparation
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
  
  # Filter regex_table by date
  if (!is.null(date_start) || !is.null(date_end)) {
    if (is.null(date_col) || !date_col %in% names(regex_table))
      stop("Please provide a valid `date_col` in regex_table for filtering.")
    date_start <- if (!is.null(date_start)) as.Date(date_start) else -Inf
    date_end <- if (!is.null(date_end)) as.Date(date_end) else Inf
    regex_table <- regex_table[regex_table[[date_col]] >= date_start & 
                                 regex_table[[date_col]] <= date_end, , drop = FALSE]
  }
  
  # Apply user-specified pattern filter
  if (!is.null(pattern_filter)) {
    if (is.character(pattern_filter) && pattern_filter %in% names(regex_table)) {
      # If user gives a column name, ask interactively or require specific values
      if (verbose) message("Filtering regex table by column: ", pattern_filter)
      # Example: regex_table$type == "strict"
      # You can refine this for your dataset, e.g. only keep strict patterns
      regex_table <- regex_table[regex_table[[pattern_filter]] == "strict", , drop = FALSE]
    } else if (is.vector(pattern_filter)) {
      # If user passes vector of allowed pattern names
      regex_table <- regex_table[regex_table[[pattern_col]] %in% pattern_filter, , drop = FALSE]
    } else {
      stop("`pattern_filter` must be a column name or vector of pattern values.")
    }
  }
  
  # Get patterns after filtering
  patterns <- regex_table[[pattern_col]]
  if (strict) {
    patterns <- paste0("\\b(", patterns, ")\\b")
  }
  
  if (verbose) message("Extracting pattern matches...")
  
  # Optimized matchign with vector
  text_vector <- data[[original_col]]
  
  # Combine all patterns into single regex
  combined_pattern <- paste(patterns, collapse = "|")
  
  # Vectorized matching
  has_match <- grepl(combined_pattern, text_vector, ignore.case = TRUE, perl = TRUE)
  
  if (sum(has_match) == 0) {
    if (verbose) message("No matches found.")
    return(create_empty_output(id_col))
  }
  
  # Get matching rows
  matched_data <- data[has_match, , drop = FALSE]
  
  # Extract which pattern matched
  if (requireNamespace("stringr", quietly = TRUE)) {
    matched_data$pattern <- stringr::str_extract(
      matched_data[[original_col]], 
      combined_pattern
    )
  } else {
    # If no match
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