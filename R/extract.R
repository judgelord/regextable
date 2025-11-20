#' @title Extract pattern matches from text
#' @description Uses a regex lookup to extract pattern matches from text efficiently.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with pattern and metadata columns.
#' @param pattern_col Name of the regex pattern column in regex_table.
#' @param id_col Optional column in `data` to use as identifier in output.
#' @param group_cols Optional vector of column names to group the matching by (like congress/chamber/state in original).
#' @param return_cols Optional vector of column names from regex_table to include in output.
#' @param priority_col Optional column name to use for match priority (e.g., "congress" - higher values = higher priority).
#' @param clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param verbose Logical; if TRUE, displays progress messages.
#' @param cl Optional cluster for parallel processing.
#' @return A data frame with one row per text entry containing the best match.
#' @export
extract <- function(data,
                    col_name,
                    regex_table,
                    pattern_col = "pattern",
                    id_col = NULL,
                    group_cols = NULL,
                    return_cols = NULL,
                    priority_col = NULL,
                    clean_text = TRUE,
                    verbose = TRUE,
                    cl = NULL) {
  
  # Process data and col_name (same as before)
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
  
  # Store original text separately - don't modify the original data structure
  original_text <- data[[col_name]]
  
  # Clean text if requested (only for matching, we'll keep original in output)
  if (clean_text) {
    data_for_matching <- data
    data_for_matching[[col_name]] <- clean_text(data[[col_name]])
  } else {
    data_for_matching <- data
  }
  
  # Process group columns
  if (!is.null(group_cols)) {
    valid_groups <- group_cols[group_cols %in% names(data) & group_cols %in% names(regex_table)]
    if (length(valid_groups) == 0) {
      group_cols <- NULL
    } else {
      group_cols <- valid_groups
    }
  }
  
  # If no group columns, process all data at once
  if (is.null(group_cols)) {
    result <- extract_matches_per_group(
      data = data_for_matching,
      col_name = col_name,
      regex_table = regex_table,
      pattern_col = pattern_col,
      id_col = id_col,
      priority_col = priority_col,
      group_values = NULL,
      verbose = verbose,
      cl = cl
    )
  } else {
    # Process by groups
    unique_groups <- unique(data_for_matching[group_cols])
    
    if (verbose) {
      message(sprintf("Processing %d unique group combinations", nrow(unique_groups)))
    }
    
    result_list <- pbapply::pblapply(seq_len(nrow(unique_groups)), function(i) {
      group_vals <- unique_groups[i, , drop = FALSE]
      
      # Filter data for this group
      group_data <- data_for_matching
      for (col in group_cols) {
        group_data <- group_data[group_data[[col]] == group_vals[[col]], ]
      }
      
      if (nrow(group_data) == 0) return(NULL)
      
      # Filter regex_table for this group  
      group_regex <- regex_table
      for (col in group_cols) {
        group_regex <- group_regex[group_regex[[col]] == group_vals[[col]], ]
      }
      
      if (nrow(group_regex) == 0) return(NULL)
      
      extract_matches_per_group(
        data = group_data,
        col_name = col_name,
        regex_table = group_regex,
        pattern_col = pattern_col,
        id_col = id_col,
        priority_col = priority_col,
        group_values = group_vals,
        verbose = FALSE
      )
    }, cl = cl)
    
    result <- dplyr::bind_rows(result_list)
  }
  
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

#' @title Extract matches for a specific group (with priority)
#' @description Internal function to extract the BEST match for each text entry
#' @keywords internal
extract_matches_per_group <- function(data,
                                      col_name,
                                      regex_table,
                                      pattern_col,
                                      id_col,
                                      priority_col = NULL,
                                      group_values = NULL,
                                      verbose = FALSE,
                                      cl = NULL) {
  
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
  }, cl = cl)
  
  all_matches <- dplyr::bind_rows(matches_list)
  
  if (nrow(all_matches) == 0) {
    return(NULL)
  }
  
  # Select the BEST match for each data_id
  if (!is.null(priority_col) && priority_col %in% names(all_matches)) {
    # Use priority column (e.g., higher congress = more recent = better match)
    best_matches <- all_matches %>%
      dplyr::group_by(.data$data_id) %>%
      dplyr::arrange(dplyr::desc(.data[[priority_col]])) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup()
  } else {
    # No priority column, just take the first match (original behavior)
    best_matches <- all_matches %>%
      dplyr::group_by(.data$data_id) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup()
  }
  
  # Join with original data to get all columns
  result <- dplyr::left_join(best_matches, 
                             data, 
                             by = setNames(id_col, "data_id"))
  
  # Add group values if provided
  if (!is.null(group_values)) {
    for (col in names(group_values)) {
      result[[col]] <- group_values[[col]]
    }
  }
  
  return(result)
}