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
#' @return A data frame with one row per match. Returns original text column plus `pattern`.
#' @importFrom pbapply pblapply pboptions
#' @importFrom stringi stri_detect_regex
#' @importFrom dplyr left_join
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
  
  # --- 1. Validation & Setup ---
  
  # Process data and col_name
  if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data)) {
      stop("Please provide a valid column name for `col_name`.")
    }
    if (!is.character(data[[col_name]])) {
      stop("the variable named in `col_name` must be a character vector")
    }
    # Store original column order
    original_col_order <- names(data)
  } else if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    col_name <- "text"
    original_col_order <- names(data)
  } else {
    stop("`data` must be a data frame or a character vector")
  }
  
  # Check for empty data
  if (nrow(data) == 0) {
    if (verbose) message("Input data is empty")
    return(data.frame())
  }
  
  # Validate regex_table
  if (!pattern_col %in% names(regex_table)) {
    stop("`pattern_col` must be a column in `regex_table`")
  }
  
  # --- 2. Filtering ---
  
  # Add data_id if not provided
  if (is.null(id_col)) {
    data$data_id <- seq_len(nrow(data))
    id_col <- "data_id"
    original_col_order <- c(original_col_order, "data_id")
  } else if (!id_col %in% names(data)) {
    stop("`id_col` must be a column in `data`")
  }
  
  # Apply ID filter if specified
  if (!is.null(id_filter)) {
    data <- data[data[[id_col]] %in% id_filter, ]
    if (nrow(data) == 0) {
      if (verbose) message("No data remaining after ID filter")
      return(data.frame())
    }
  }
  
  # Apply date filter if specified
  if (!is.null(date_col)) {
    if (!date_col %in% names(data)) {
      stop("`date_col` must be a column in `data`")
    }
    
    # Convert date_col to Date if not already
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
      return(data.frame())
    }
  }
  
  # --- 3. Regex Preparation ---
  
  # Remove acronyms if requested
  if (remove_acronyms) {
    # Remove patterns that are all uppercase (acronyms)
    is_acronym <- grepl("^[A-Z]{2,}$", regex_table[[pattern_col]])
    regex_table <- regex_table[!is_acronym, ]
    if (nrow(regex_table) == 0) {
      if (verbose) message("No patterns remaining after removing acronyms")
      return(data.frame())
    }
  }
  
  # --- 4. Execution ---
  
  # Store original text separately
  original_text <- data[[col_name]]
  
  # Clean text if requested (only for matching, keep original in output)
  data_for_matching <- data
  if (do_clean_text) {
    # We assume clean_text function exists in your package
    data_for_matching[[col_name]] <- clean_text(data[[col_name]])
  }
  
  # Set up progress bar options
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb))
  
  # Process the data using the optimized shrinking pool strategy
  result <- extract_matches_shrinking_pool(
    data = data_for_matching,
    original_data = data,
    col_name = col_name,
    regex_table = regex_table,
    pattern_col = pattern_col,
    id_col = id_col,
    verbose = verbose
  )
  
  # --- 5. Finalize Output ---
  
  # Restore original text and formatting
  if (!is.null(result) && nrow(result) > 0) {
    
    # Ensure we align the original text correctly using ID
    # Note: result already contains original columns via left_join in the helper,
    # but we want to make sure the text column is the *original* (uncleaned) text.
    row_indices <- match(result[[id_col]], data[[id_col]])
    result[[col_name]] <- original_text[row_indices]
    
    # Select return columns if specified
    if (!is.null(return_cols)) {
      available_cols <- return_cols[return_cols %in% names(result)]
      if (length(available_cols) > 0) {
        # Keep ID, pattern, and specified return columns
        cols_to_keep <- unique(c(id_col, "pattern", available_cols))
        result <- result[cols_to_keep]
      }
    } else {
      # If no specific columns requested, order nicely: Original cols + Pattern
      existing_cols <- names(result)
      final_cols <- original_col_order[original_col_order %in% existing_cols]
      final_cols <- c(final_cols, setdiff(existing_cols, final_cols))
      result <- result[final_cols]
    }
  }
  
  if (verbose) message("Number of matches found: ", nrow(result))
  return(result)
}

#' @title Extract matches for a specific group (Optimized)
#' @description Internal function to extract matches using a shrinking pool strategy.
#' Rows that find a match are removed from the search pool for subsequent patterns.
#' @keywords internal
extract_matches_shrinking_pool <- function(data,
                                           original_data,
                                           col_name,
                                           regex_table,
                                           pattern_col,
                                           id_col,
                                           verbose = FALSE) {
  
  # Extract vectors for speed
  text_vector <- data[[col_name]]
  row_ids <- data[[id_col]]
  patterns <- unique(na.omit(regex_table[[pattern_col]]))
  
  n_rows <- length(text_vector)
  
  # matched_patterns: Vector to store the winning pattern for each row. Initialize with NA.
  matched_patterns <- rep(NA_character_, n_rows)
  
  # is_unmatched: Logical vector tracking which rows still need to be checked.
  # TRUE = needs checking, FALSE = already found a match.
  is_unmatched <- rep(TRUE, n_rows)
  
  if (verbose) {
    message(sprintf("Matching %d patterns against %d text entries", 
                    length(patterns), n_rows))
  }
  
  # Loop over patterns using pbapply for the progress bar.
  # We ignore the return list of pblapply and use side-effects (<<-) to update vectors.
  dummy_output <- pbapply::pblapply(patterns, function(pat) {
    
    # Optimization: If all rows are matched, stop checking patterns.
    if (!any(is_unmatched)) return(NULL)
    
    # Get indices of rows that are still looking for a match
    indices_to_check <- which(is_unmatched)
    
    # Subset text to only check meaningful rows
    subset_text <- text_vector[indices_to_check]
    
    # Check for matches
    has_match <- stringi::stri_detect_regex(subset_text, pat, case_insensitive = TRUE)
    
    if (any(has_match)) {
      # Map back to the original row indices
      matched_indices <- indices_to_check[has_match]
      
      # Update the results vector using superassignment (<<-) to reach parent scope
      matched_patterns[matched_indices] <<- pat
      
      # Mark these rows as done so we don't check them again
      is_unmatched[matched_indices] <<- FALSE
    }
    return(NULL)
  })
  
  # --- Construct Result Data Frame ---
  
  # Identify which rows ended up with a match
  final_match_indices <- which(!is.na(matched_patterns))
  
  if (length(final_match_indices) == 0) {
    return(data.frame())
  }
  
  # Create a lightweight data frame of the results
  matches_df <- data.frame(
    id_temp = row_ids[final_match_indices],
    pattern = matched_patterns[final_match_indices],
    stringsAsFactors = FALSE
  )
  
  # Fix the ID column name to match the input
  names(matches_df)[1] <- id_col
  
  # Join with original data to retrieve all other columns
  # We use left_join to ensure we get the full row content associated with that ID
  result <- dplyr::left_join(matches_df, original_data, by = id_col)
  
  return(result)
}