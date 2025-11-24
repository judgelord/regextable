#' @title Extract pattern matches from text
#' @description Uses a regex lookup to extract pattern matches from a data frame, returns matching rows.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with a pattern column.
#' @param pattern_col Name of the regex pattern column in regex_table.
#' @param return_cols Optional vector of column names to include in the output.
#' @param id_col Optional column in `data` used to filter rows before matching.
#' @param id_filter Optional value or vector of IDs to restrict which rows of `data` are matched.
#' @param date_col Optional column in 'data' for date filtering.
#' @param date_start Optional start date for filtering 'data'.
#' @param date_end Optional end date for filtering 'data'.
#' @param typo_table Optional table to fix typos in 'data'. # planned for later versions
#' @param remove_acronyms Logical; if TRUE, removes all-uppercase patterns from regex_table.
#' @param do_clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param verbose Logical; if TRUE, displays progress messages.
#' @return A tibble (data frame) with one row per match. Returns original text column plus `pattern`.
#' @importFrom pbapply pblapply pboptions
#' @importFrom stringi stri_detect_regex
#' @importFrom dplyr as_tibble
#' @importFrom stats na.omit
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
                     do_clean_text = TRUE,
                     verbose = TRUE) {
  
  # Normalize input to data frame
  if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    col_name <- "text"
  } else if (!is.data.frame(data)) {
    stop("`data` must be a data frame or a character vector")
  }
  
  # Validate columns
  if (missing(col_name) || !col_name %in% names(data)) {
    stop(sprintf("Column `%s` not found in data.", col_name))
  }
  if (!is.character(data[[col_name]])) {
    stop(sprintf("Column `%s` must be a character vector.", col_name))
  }
  
  # Fast exit for empty data
  if (nrow(data) == 0) {
    if (verbose) message("Input data is empty")
    return(dplyr::as_tibble(data.frame()))
  }
  
  # Validate regex table
  if (!pattern_col %in% names(regex_table)) {
    stop(sprintf("Column `%s` not found in regex_table.", pattern_col))
  }
  
  original_col_order <- names(data)
  
  # Create a default ID if not provided
  if (is.null(id_col)) {
    if (!"data_id" %in% names(data)) {
      data$data_id <- seq_len(nrow(data))
      id_col <- "data_id"
      original_col_order <- c(original_col_order, "data_id")
    } else {
      id_col <- "data_id"
    }
  } else if (!id_col %in% names(data)) {
    stop(sprintf("ID Column `%s` not found in data.", id_col))
  }
  
  
  # Filter by Date
  if (!is.null(date_col)) {
    if (!date_col %in% names(data)) stop(sprintf("Date column `%s` not found.", date_col))
    
    if (!inherits(data[[date_col]], "Date")) {
      data[[date_col]] <- as.Date(data[[date_col]])
    }
    
    if (!is.null(date_start)) data <- data[data[[date_col]] >= as.Date(date_start), ]
    if (!is.null(date_end))   data <- data[data[[date_col]] <= as.Date(date_end), ]
    
    if (nrow(data) == 0) {
      if (verbose) message("No data remaining after date filter")
      return(dplyr::as_tibble(data.frame()))
    }
  }
  
  # Prepare unique patterns
  patterns <- unique(stats::na.omit(regex_table[[pattern_col]]))
  
  if (remove_acronyms) {
    patterns <- patterns[!grepl("^[A-Z]{2,}$", patterns)]
  }
  
  if (length(patterns) == 0) {
    if (verbose) message("No patterns provided (or all removed via filters).")
    return(dplyr::as_tibble(data.frame()))
  }
  
  # Clean text if requested
  text_to_match <- data[[col_name]]
  if (do_clean_text) {
    # Robust check for internal package function
    text_to_match <- tryCatch({
      clean_text(text_to_match)
    }, error = function(e) {
      warning("`clean_text` failed or not found. Using original text.")
      return(text_to_match)
    })
  }
  
  # Setup progress bar
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb))
  
  # Run the optimized matching strategy (Shrinking Pool)
  matches_found <- extract_matches_shrinking_pool(
    text_vector = text_to_match,
    row_ids = data[[id_col]],
    patterns = patterns,
    id_col_name = id_col,
    verbose = verbose
  )
  
  # Finalize output using fast matching
  if (nrow(matches_found) > 0) {
    
    # Use match() for speed instead of join
    row_indices <- match(matches_found[[id_col]], data[[id_col]])
    result <- data[row_indices, , drop = FALSE]
    result$pattern <- matches_found$pattern
    
    # Select and order columns
    if (!is.null(return_cols)) {
      valid_cols <- return_cols[return_cols %in% names(result)]
      cols_to_keep <- unique(c(id_col, "pattern", valid_cols))
      result <- result[, cols_to_keep, drop = FALSE]
    } else {
      final_cols <- c(original_col_order, "pattern")
      final_cols <- final_cols[final_cols %in% names(result)]
      result <- result[, final_cols, drop = FALSE]
    }
  } else {
    result <- data.frame()
  }
  
  if (verbose) message("Number of matches found: ", nrow(result))
  
  return(dplyr::as_tibble(result))
}

#' @title Extract matches for a specific group (Optimized)
#' @description Internal function to extract matches using a shrinking pool strategy.
#' @keywords internal
extract_matches_shrinking_pool <- function(text_vector,
                                           row_ids,
                                           patterns,
                                           id_col_name,
                                           verbose = FALSE) {
  
  n_rows <- length(text_vector)
  
  # Track matches and unmatched rows
  matched_patterns <- rep(NA_character_, n_rows)
  is_unmatched <- rep(TRUE, n_rows)
  
  if (verbose) {
    message(sprintf("Matching %d patterns against %d text entries", length(patterns), n_rows))
  }
  
  # Loop patterns and update matches via side-effects
  dummy <- pbapply::pblapply(patterns, function(pat) {
    
    # Stop if everyone matches
    if (!any(is_unmatched)) return(NULL)
    
    # Check only unmatched rows
    indices_to_check <- which(is_unmatched)
    subset_text <- text_vector[indices_to_check]
    
    has_match <- stringi::stri_detect_regex(subset_text, pat, case_insensitive = TRUE)
    
    if (any(has_match)) {
      matched_indices <- indices_to_check[has_match]
      matched_patterns[matched_indices] <<- pat
      is_unmatched[matched_indices] <<- FALSE
    }
    return(NULL)
  })
  
  # Build result data frame
  final_match_indices <- which(!is.na(matched_patterns))
  
  if (length(final_match_indices) == 0) {
    return(data.frame())
  }
  
  df <- data.frame(
    id = row_ids[final_match_indices],
    pattern = matched_patterns[final_match_indices],
    stringsAsFactors = FALSE
  )
  
  names(df)[1] <- id_col_name
  
  return(df)
}