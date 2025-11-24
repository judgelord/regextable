#' @title Extract pattern matches from text
#' @description Uses a regex lookup to extract pattern matches from a data frame. 
#' Can optionally group by a category column (like 'extractMemberName' does with Congress).
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with a pattern column.
#' @param pattern_col Name of the regex pattern column in regex_table.
#' @param category_col Optional. Name of a column in `regex_table` to group patterns by (e.g., "congress", "year"). 
#' If this column is ALSO present in `data`, the function will split both for maximum speed.
#' If it is ONLY in `regex_table`, it will iterate through pattern groups against the full data.
#' @param return_cols Optional vector of column names to include in the output.
#' @param id_col Optional column in `data` used to filter rows before matching.
#' @param id_filter Optional value or vector of IDs to restrict which rows of `data` are matched.
#' @param date_col Optional column in 'data' for date filtering.
#' @param date_start Optional start date for filtering 'data'.
#' @param date_end Optional end date for filtering 'data'.
#' @param typo_table Optional table to fix typos in 'data'. 
#' @param remove_acronyms Logical; if TRUE, removes all-uppercase patterns from regex_table.
#' @param do_clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param verbose Logical; if TRUE, displays progress messages.
#' @return A data frame with one row per match. Returns original text column plus `pattern`.
#' @export
extract2 <- function(data,
                    col_name,
                    regex_table,
                    pattern_col = "pattern",
                    category_col = NULL, # <--- MODIFIED ARGUMENT
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
  
  # --- 1. DATA PREPARATION ---
  
  # Handle data input types
  if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data)) stop("Please provide a valid column name for `col_name`.")
    if (!is.character(data[[col_name]])) stop("the variable named in `col_name` must be a character vector")
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
    return(data.frame()) 
  }
  
  # Handle Regex Table
  if (!pattern_col %in% names(regex_table)) stop("`pattern_col` must be a column in `regex_table`")
  
  # Progress bar setup
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb))
  
  # Add ID if missing
  if (is.null(id_col)) {
    data$data_id <- seq_len(nrow(data))
    id_col <- "data_id"
    original_col_order <- c(original_col_order, "data_id")
  } else if (!id_col %in% names(data)) {
    stop("`id_col` must be a column in `data`")
  }
  
  # Filters (ID and Date)
  if (!is.null(id_filter)) {
    data <- data[data[[id_col]] %in% id_filter, ]
    if (nrow(data) == 0) return(data.frame())
  }
  
  if (!is.null(date_col)) {
    if (!date_col %in% names(data)) stop("`date_col` must be a column in `data`")
    if (!inherits(data[[date_col]], "Date")) data[[date_col]] <- as.Date(data[[date_col]])
    if (!is.null(date_start)) data <- data[data[[date_col]] >= as.Date(date_start), ]
    if (!is.null(date_end)) data <- data[data[[date_col]] <= as.Date(date_end), ]
    if (nrow(data) == 0) return(data.frame())
  }
  
  # Acronym Removal
  if (remove_acronyms) {
    is_acronym <- grepl("^[A-Z]{2,}$", regex_table[[pattern_col]])
    regex_table <- regex_table[!is_acronym, ]
    if (nrow(regex_table) == 0) return(data.frame())
  }
  
  # --- 2. TEXT CLEANING ---
  
  original_text <- data[[col_name]]
  
  if (do_clean_text) {
    if (verbose) message("Cleaning text...")
    data_for_matching <- data
    # Optimized cleaner inline or called from external function
    data_for_matching[[col_name]] <- data[[col_name]] %>%
      stringr::str_to_lower() %>%
      stringr::str_replace_all("[\n.+\u2014]", " ") %>% 
      stringr::str_replace_all("\\s*(?:,\\s*)+", ", ") %>%
      stringr::str_squish()
  } else {
    data_for_matching <- data
  }
  
  # --- 3. MATCHING LOGIC ---
  
  if (!is.null(category_col)) {
    
    # --- CATEGORY MODE ---
    # Check if the column exists in regex_table (REQUIRED)
    if (!category_col %in% names(regex_table)) {
      stop(paste("`category_col`", category_col, "must be present in `regex_table`."))
    }
    
    # Check if the column exists in data (OPTIONAL but Recommended)
    has_cat_in_data <- category_col %in% names(data)
    
    if (verbose) {
      if (has_cat_in_data) {
        message(sprintf("Splitting both Data and Regex by '%s' (Fastest Mode)", category_col))
      } else {
        message(sprintf("Splitting Regex by '%s', matching against FULL Data (Iterative Mode)", category_col))
      }
    }
    
    cats <- unique(na.omit(regex_table[[category_col]]))
    
    result_list <- pbapply::pblapply(cats, function(cat) {
      
      # 1. Slice the Patterns (Always)
      sub_regex <- regex_table[regex_table[[category_col]] == cat, ]
      
      # 2. Slice the Data (Only if column exists)
      if (has_cat_in_data) {
        sub_data <- data_for_matching[data_for_matching[[category_col]] == cat, ]
      } else {
        sub_data <- data_for_matching # Use full data if no category column in data
      }
      
      # 3. Run Match
      if (nrow(sub_data) > 0 && nrow(sub_regex) > 0) {
        extract_matches_per_group(
          data = sub_data,
          original_data = sub_data,
          col_name = col_name,
          regex_table = sub_regex,
          pattern_col = pattern_col,
          id_col = id_col,
          verbose = FALSE
        )
      } else {
        return(NULL)
      }
    })
    
    result <- dplyr::bind_rows(result_list)
    
  } else {
    
    # --- STANDARD MODE (No Category) ---
    if (verbose) message("No category column provided. Processing full dataset...")
    result <- extract_matches_per_group(
      data = data_for_matching,
      original_data = data,
      col_name = col_name,
      regex_table = regex_table,
      pattern_col = pattern_col,
      id_col = id_col,
      verbose = verbose
    )
  }
  
  # --- 4. RESULT RECONSTRUCTION ---
  
  if (!is.null(result) && nrow(result) > 0) {
    
    # Restore original text using ID match
    # We map back to the GLOBAL original_text
    result[[col_name]] <- original_text[match(result[[id_col]], data[[id_col]])]
    
    # Reorder columns
    existing_cols <- names(result)
    final_cols <- original_col_order[original_col_order %in% existing_cols]
    final_cols <- c(final_cols, setdiff(existing_cols, final_cols))
    result <- result[final_cols]
    
    # Filter return columns if requested
    if (!is.null(return_cols)) {
      available_cols <- return_cols[return_cols %in% names(result)]
      if (length(available_cols) > 0) {
        result <- result[c(id_col, available_cols)]
      }
    }
  }
  
  if (verbose) message("Done. Matches found: ", if(is.null(result)) 0 else nrow(result))
  return(result)
}

#' @title Extract matches for a specific group (Optimized Batched)
#' @description Internal function using Batched Regex to prevent RAM crashes.
#' @keywords internal
extract_matches_per_group <- function(data,
                                      original_data,
                                      col_name,
                                      regex_table,
                                      pattern_col,
                                      id_col,
                                      verbose = FALSE) {
  
  if (nrow(data) == 0 || nrow(regex_table) == 0) return(data.frame())
  
  text <- data[[col_name]]
  patterns <- unique(na.omit(regex_table[[pattern_col]]))
  
  # Sort: Longest patterns first
  patterns <- patterns[order(-nchar(patterns))]
  
  if (verbose) message(sprintf("Matching %d patterns against %d text entries...", length(patterns), length(text)))
  
  # Batch patterns in groups of 50 to prevent regex overload
  chunk_size <- 50
  pattern_chunks <- split(patterns, ceiling(seq_along(patterns)/chunk_size))
  
  results_list <- list()
  
  for(i in seq_along(pattern_chunks)) {
    chunk <- pattern_chunks[[i]]
    combined_regex <- paste(chunk, collapse = "|")
    
    found <- stringi::stri_extract_first_regex(text, combined_regex, case_insensitive = TRUE)
    idx <- which(!is.na(found))
    
    if(length(idx) > 0) {
      results_list[[i]] <- data.frame(
        id_temp = data[[id_col]][idx],
        pattern = found[idx],
        stringsAsFactors = FALSE
      )
    }
  }
  
  if(length(results_list) == 0) return(data.frame())
  
  all_matches <- dplyr::bind_rows(results_list)
  names(all_matches)[1] <- id_col
  
  # Get best match per ID
  best_matches <- all_matches %>%
    dplyr::group_by(.data[[id_col]]) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup()
  
  # Join back to the data passed to this function
  result <- dplyr::left_join(best_matches, original_data, by = id_col)
  
  return(result)
}