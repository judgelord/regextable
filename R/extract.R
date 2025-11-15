#' @title Extract pattern matches from text
#' @description Uses a regex lookup to extract pattern matches from a data frame, efficiently using batching. Returns original text.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with at least one pattern column.
#' @param pattern_col Name of the regex pattern column in regex_table.
#' @param return_cols Optional vector of column names to include in the output.
#' @param id_col Optional column in `data` used to filter rows before matching.
#' @param id_filter Optional value or vector of IDs to restrict which rows of `data` are matched.
#' @param date_col Optional column in 'data' for date filtering.
#' @param date_start Optional start date for filtering 'data'.
#' @param date_end Optional end date for filtering 'data'.
#' @param typo_table Optional table to fix typos in 'data'. # planned for later versions
#' @param remove_acronyms Logical; if TRUE, removes all-uppercase patterns from regex_table.
#' @param clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param batch_size Integer; number of patterns per batch.
#' @param verbose Logical; if TRUE, displays progress messages.
#' @return A data frame with one row per match. Returns original text column plus `matched_pattern`.
#' @export
extract <- function(data,
                    col_name,
                    regex_table,
                    pattern_col = "pattern",
                    return_cols = NULL,
                    id_col = NULL,
                    id_filter = NULL,
                    date_col = NULL,
                    date_start = NULL,
                    date_end = NULL,
                    typo_table = NULL,
                    remove_acronyms = FALSE,
                    clean_text = TRUE,
                    batch_size = 1000,
                    verbose = TRUE) {
  
  # Input validation 
  if (is.character(data) && is.null(dim(data))) {
    original_text <- data
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    if (missing(col_name)) col_name <- "text"
  } else if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data)) {
      stop("Please provide a valid column name for `col_name`.")
    }
    original_text <- data[[col_name]]  # store original text
  } else {
    stop("`data` must be a data frame or character vector.")
  }
  
  if (!pattern_col %in% names(regex_table) || all(is.na(regex_table[[pattern_col]]))) {
    stop("Please provide a valid pattern column name for 'pattern_col'")
  }
  
  # Optional text cleaning
  cleaned_text <- data[[col_name]]
  if (clean_text) {
    cleaned_text <- clean_text(cleaned_text)
  }
  
  # ID filtering
  if (!is.null(id_filter)) {
    if (is.null(id_col) || !id_col %in% names(data)) {
      stop("If 'id_filter' is used, a valid 'id_col' in 'data' must be specified")
    }
    data <- data[data[[id_col]] %in% id_filter, , drop = FALSE]
    cleaned_text <- cleaned_text[data[[id_col]] %in% id_filter]
    original_text <- original_text[data[[id_col]] %in% id_filter]
  }
  
  # Date filtering
  if (!is.null(date_start) || !is.null(date_end)) {
    if (is.null(date_col) || !date_col %in% names(data)) {
      stop("Please provide a valid `date_col` in 'data' for filtering.")
    }
    date_start <- if (!is.null(date_start)) as.Date(date_start) else -Inf
    date_end <- if (!is.null(date_end)) as.Date(date_end) else Inf
    data[[date_col]] <- as.Date(data[[date_col]])
    keep_idx <- data[[date_col]] >= date_start & data[[date_col]] <= date_end
    data <- data[keep_idx, , drop = FALSE]
    cleaned_text <- cleaned_text[keep_idx]
    original_text <- original_text[keep_idx]
  }
  
  # Prepare patterns
  patterns <- regex_table[[pattern_col]]
  patterns <- stringr::str_squish(trimws(patterns))
  patterns <- patterns[nchar(patterns) > 0 & !duplicated(patterns)]
  
  if (remove_acronyms) {
    patterns <- patterns[!grepl("^[A-Z]{2,}$", patterns)]
    if (length(patterns) == 0) return(create_empty_output(data))
  }
  
  if (verbose) message("Starting batch pattern detection with ", length(patterns), " patterns...")
  
  # Batching for detection
  batches <- split(patterns, ceiling(seq_along(patterns) / batch_size))
  has_match <- logical(length(cleaned_text))
  
  for (i in seq_along(batches)) {
    if (verbose) message("Processing batch ", i, "/", length(batches))
    batch_pattern <- paste0("(", paste(batches[[i]], collapse = ")|("), ")")
    has_match <- has_match | stringi::stri_detect_regex(cleaned_text, batch_pattern, case_insensitive = TRUE)
  }
  
  if (sum(has_match) == 0) {
    if (verbose) message("No matches found.")
    return(create_empty_output(data))
  }
  
  # Extract matched patterns efficiently
  matched_data <- data[has_match, , drop = FALSE]
  matched_text <- cleaned_text[has_match]
  original_matched_text <- original_text[has_match]
  matched_patterns <- rep(NA_character_, length(matched_text))
  
  for (i in seq_along(batches)) {
    batch <- batches[[i]]
    batch_pattern <- paste0("(", paste(batch, collapse = ")|("), ")")
    unmatched_idx <- which(is.na(matched_patterns))
    if (length(unmatched_idx) == 0) break
    extracted <- stringi::stri_extract_first_regex(matched_text[unmatched_idx], batch_pattern, case_insensitive = TRUE)
    matched_patterns[unmatched_idx[!is.na(extracted)]] <- extracted[!is.na(extracted)]
  }
  
  # Assign original text back
  matched_data[[col_name]] <- original_matched_text
  matched_data$matched_pattern <- matched_patterns
  
  # Return requested columns
  if (!is.null(return_cols)) {
    needed <- unique(c(return_cols, col_name, "matched_pattern"))
    if (!is.null(id_col)) needed <- unique(c(id_col, needed))
    needed <- needed[needed %in% names(matched_data)]
    matched_data <- matched_data[, needed, drop = FALSE]
  }
  
  if (verbose) message("Done. Found ", nrow(matched_data), " matches.")
  return(matched_data)
}


#' @title Create Empty Output
#' @description Returns an empty data frame with the same columns as 'data'.
#' @param data A data frame to copy column structure from.
#' @return An empty data frame with 0 rows.
#' @keywords internal
create_empty_output <- function(data) {
  empty_df <- data[0, , drop = FALSE]
  empty_df$matched_pattern <- character(0)
  empty_df
}
