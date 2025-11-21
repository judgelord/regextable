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
#' @param clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
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
                    verbose = TRUE) {
  
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
  
  # Validate regex_table
  if (!pattern_col %in% names(regex_table)) {
    stop("`pattern_col` must be a column in `regex_table`")
  }
  
  # Set up progress bar
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb))
  
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
      return(NULL)
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
      return(NULL)
    }
  }
  
  # Remove acronyms if requested
  if (remove_acronyms) {
    # Remove patterns that are all uppercase (acronyms)
    is_acronym <- grepl("^[A-Z]{2,}$", regex_table[[pattern_col]])
    regex_table <- regex_table[!is_acronym, ]
    if (nrow(regex_table) == 0) {
      if (verbose) message("No patterns remaining after removing acronyms")
      return(NULL)
    }
  }
  
  # Apply typo correction if specified
  if (!is.null(typo_table)) {
    if (verbose) message("Applying typo correction...")
    data[[col_name]] <- correct_typos(data[[col_name]], typo_table)
  }
  
  # Store original text separately - don't modify the original data structure
  original_text <- data[[col_name]]
  
  # Clean text if requested (only for matching, we'll keep original in output)
  if (clean_text) {
    data_for_matching <- data
    data_for_matching[[col_name]] <- clean_text(data[[col_name]])
  } else {
    data_for_matching <- data
  }
  
  # Process the data
  result <- extract_matches_per_group(
    data = data_for_matching,
    col_name = col_name,
    regex_table = regex_table,
    pattern_col = pattern_col,
    id_col = id_col,
    verbose = verbose
  )
  
  # Restore original text in the output
  if (!is.null(result) && nrow(result) > 0) {
    # Replace the cleaned text with original text
    result[[col_name]] <- original_text[match(result[[id_col]], data[[id_col]])]
    
    # Reorder columns to match original data structure
    existing_cols <- names(result)
    
    # Start with ID column
    final_cols <- id_col
    
    # Add original data columns in their original order (that exist in result)
    for (col in original_col_order) {
      if (col %in% existing_cols && !col %in% final_cols) {
        final_cols <- c(final_cols, col)
      }
    }
    
    # Add any remaining columns from regex matching
    remaining_cols <- setdiff(existing_cols, final_cols)
    final_cols <- c(final_cols, remaining_cols)
    
    # Reorder the result
    result <- result[final_cols]
  }
  
  # Select return columns if specified
  if (!is.null(return_cols) && !is.null(result)) {
    available_cols <- return_cols[return_cols %in% names(result)]
    if (length(available_cols) > 0) {
      # Keep ID column and specified return columns
      result <- result[c(id_col, available_cols)]
    }
  }
  
  return(result)
}

#' @title Extract matches for a specific group
#' @description Internal function to extract matches for each text entry
#' @keywords internal
extract_matches_per_group <- function(data,
                                      col_name,
                                      regex_table,
                                      pattern_col,
                                      id_col,
                                      verbose = FALSE) {
  
  if (nrow(data) == 0 || nrow(regex_table) == 0) {
    return(NULL)
  }
  
  text <- data[[col_name]]
  patterns <- unique(na.omit(regex_table[[pattern_col]]))
  
  if (verbose) {
    message(sprintf("Matching %d patterns against %d text entries", 
                    length(patterns), length(text)))
  }
  
  # Find ALL matches first
  matches_list <- pbapply::pblapply(patterns, function(pattern) {
    matched_rows <- which(stringi::stri_detect_regex(text, pattern, case_insensitive = TRUE))
    if (length(matched_rows) > 0) {
      # For each match, get the matching rows from regex_table
      matching_regex_rows <- regex_table[regex_table[[pattern_col]] == pattern, ]
      
      # Create a row for each combination of data row and regex row
      expanded_matches <- data.frame(
        data_id = data[[id_col]][matched_rows],
        pattern = pattern,
        stringsAsFactors = FALSE
      )
      
      # Add all columns from regex_table EXCEPT the pattern column to avoid duplicates
      regex_cols_to_add <- setdiff(names(matching_regex_rows), pattern_col)
      
      if (length(regex_cols_to_add) > 0) {
        # Create a data frame with the regex columns, preserving original names
        regex_data <- matching_regex_rows[rep(1, nrow(expanded_matches)), regex_cols_to_add, drop = FALSE]
        
        # Use cbind to ensure column names are preserved
        result <- cbind(expanded_matches, regex_data)
        rownames(result) <- NULL  # Clean up row names
        
        return(result)
      } else {
        return(expanded_matches)
      }
    } else {
      return(NULL)
    }
  })
  
  all_matches <- dplyr::bind_rows(matches_list)
  
  if (nrow(all_matches) == 0) {
    return(NULL)
  }
  
  # Take the first match for each data_id (original behavior)
  best_matches <- all_matches %>%
    dplyr::group_by(.data$data_id) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup()
  
  # Join with original data to get all columns
  result <- dplyr::left_join(best_matches, 
                             data, 
                             by = setNames(id_col, "data_id"))
  
  return(result)
}

#' @title Correct typos in text
#' @description Internal function to correct typos using a typo table
#' @keywords internal
correct_typos <- function(text, typo_table) {
  # Basic implementation - replace typos with corrections
  # Assumes typo_table has columns "typo" and "correction"
  if (!all(c("typo", "correction") %in% names(typo_table))) {
    stop("typo_table must have 'typo' and 'correction' columns")
  }
  
  for (i in seq_len(nrow(typo_table))) {
    text <- gsub(typo_table$typo[i], typo_table$correction[i], text, ignore.case = TRUE)
  }
  
  return(text)
}