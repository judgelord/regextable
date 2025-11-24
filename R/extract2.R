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
#' @importFrom dplyr left_join as_tibble
#' @export
extract2 <- function(data,
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
  
  # Validate input and ensure character column
  
  if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data)) {
      stop("Please provide a valid column name for `col_name`.")
    }
    if (!is.character(data[[col_name]])) {
      stop("the variable named in `col_name` must be a character vector")
    }
    original_col_order <- names(data)
  } else if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    col_name <- "text"
    original_col_order <- names(data)
  } else {
    stop("`data` must be a data frame or a character vector")
  }
  
  if (nrow(data) == 0) {
    if (verbose) message("Input data is empty")
    return(dplyr::as_tibble(data.frame()))
  }
  
  if (!pattern_col %in% names(regex_table)) {
    stop("`pattern_col` must be a column in `regex_table`")
  }
  
  # Apply row-level filters (ID and date)
  
  if (is.null(id_col)) {
    data$data_id <- seq_len(nrow(data))
    id_col <- "data_id"
    original_col_order <- c(original_col_order, "data_id")
  } else if (!id_col %in% names(data)) {
    stop("`id_col` must be a column in `data`")
  }
  
  if (!is.null(id_filter)) {
    data <- data[data[[id_col]] %in% id_filter, ]
    if (nrow(data) == 0) {
      if (verbose) message("No data remaining after ID filter")
      return(dplyr::as_tibble(data.frame()))
    }
  }
  
  if (!is.null(date_col)) {
    if (!date_col %in% names(data)) {
      stop("`date_col` must be a column in `data`")
    }
    if (!inherits(data[[date_col]], "Date")) {
      data[[date_col]] <- as.Date(data[[date_col]])
    }
    if (!is.null(date_start)) {
      data <- data[data[[date_col]] >= as.Date(date_start), ]
    }
    if (!is.null(date_end)) {
      data <- data[data[[date_col]] <= as.Date(date_end), ]
    }
    if (nrow(data) == 0) {
      if (verbose) message("No data remaining after date filter")
      return(dplyr::as_tibble(data.frame()))
    }
  }
  
  # Prepare regex patterns (remove acronyms if requested)
  
  if (remove_acronyms) {
    is_acronym <- grepl("^[A-Z]{2,}$", regex_table[[pattern_col]])
    regex_table <- regex_table[!is_acronym, ]
    if (nrow(regex_table) == 0) {
      if (verbose) message("No patterns remaining after removing acronyms")
      return(dplyr::as_tibble(data.frame()))
    }
  }
  
  # Run pattern matching on cleaned or original text
  
  original_text <- data[[col_name]]
  
  data_for_matching <- data
  if (do_clean_text) {
    # Expects clean_text to be available
    data_for_matching[[col_name]] <- clean_text(data[[col_name]])
  }
  
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb))
  
  result <- extract_matches_shrinking_pool(
    data = data_for_matching,
    original_data = data,
    col_name = col_name,
    regex_table = regex_table,
    pattern_col = pattern_col,
    id_col = id_col,
    verbose = verbose
  )
  
  # Assemble and reorder output columns
  
  if (!is.null(result) && nrow(result) > 0) {
    row_indices <- match(result[[id_col]], data[[id_col]])
    result[[col_name]] <- original_text[row_indices]
    
    if (!is.null(return_cols)) {
      available_cols <- return_cols[return_cols %in% names(result)]
      if (length(available_cols) > 0) {
        cols_to_keep <- unique(c(id_col, "pattern", available_cols))
        result <- result[cols_to_keep]
      }
    } else {
      existing_cols <- names(result)
      final_cols <- original_col_order[original_col_order %in% existing_cols]
      final_cols <- c(final_cols, setdiff(existing_cols, final_cols))
      result <- result[final_cols]
    }
  } else {
    # If NULL result, return empty tibble
    return(dplyr::as_tibble(data.frame()))
  }
  
  if (verbose) message("Number of matches found: ", nrow(result))
  
  # THE FIX: Convert to tibble for cleaner printing
  return(dplyr::as_tibble(result))
}

#' @title Extract matches for a specific group (Optimized)
#' @description Internal function to extract matches using a shrinking pool strategy.
#' @keywords internal
extract_matches_shrinking_pool <- function(data,
                                           original_data,
                                           col_name,
                                           regex_table,
                                           pattern_col,
                                           id_col,
                                           verbose = FALSE) {
  
  text_vector <- data[[col_name]]
  row_ids <- data[[id_col]]
  patterns <- unique(na.omit(regex_table[[pattern_col]]))
  n_rows <- length(text_vector)
  
  matched_patterns <- rep(NA_character_, n_rows)
  is_unmatched <- rep(TRUE, n_rows)
  
  if (verbose) {
    message(sprintf("Matching %d patterns against %d text entries", length(patterns), n_rows))
  }
  
  dummy_output <- pbapply::pblapply(patterns, function(pat) {
    if (!any(is_unmatched)) return(NULL)
    
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
  
  final_match_indices <- which(!is.na(matched_patterns))
  
  if (length(final_match_indices) == 0) {
    return(data.frame())
  }
  
  matches_df <- data.frame(
    id_temp = row_ids[final_match_indices],
    pattern = matched_patterns[final_match_indices],
    stringsAsFactors = FALSE
  )
  
  names(matches_df)[1] <- id_col
  
  result <- dplyr::left_join(matches_df, original_data, by = id_col)
  
  return(result)
}