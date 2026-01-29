#' @title Extract pattern matches from text
#' @description Uses a regex lookup table to extract **all** pattern matches.
#' 
#' @details
#' Pattern matching is performed using R's regular expression engine and is
#' case-insensitive by default. For each input row, the function checks every
#' pattern in `regex_table` and returns the first match of each pattern.
#'
#' The output contains one row per pattern match per input row. If multiple
#' patterns match the same text, multiple rows will be returned for that text.
#'
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with a pattern column.
#' @param pattern_col Name of the regex pattern column in regex_table.
#' @param return_cols Optional vector of column names to include from 'data'.
#' @param regex_return_cols Optional vector of column names to include from 'regex_table'.
#' @param date_col Optional column in 'data' for date filtering.
#' @param date_start Optional start date for filtering 'data'.
#' @param date_end Optional end date for filtering 'data'.
#' @param remove_acronyms Logical; if TRUE, removes all-uppercase patterns from regex_table.
#' @param do_clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param verbose Logical; if TRUE, displays progress messages.
#' @param cl A cluster object created by `parallel::makeCluster()`, or an integer to indicate number of child-processes (integer values are ignored on Windows) for parallel evaluations. Passed to [pbapply::pblapply()].
#' 
#' @return A tibble (data frame) with the following columns:
#' \itemize{
#'   \item All original columns from `data` (or subset specified by `return_cols`)
#'   \item `pattern` The matched regex pattern(s)
#'   \item `match` The specific text extracted from the data (original casing preserved)
#'   \item `row_id` Integer row identifier corresponding to the input data
#'   \item Additional columns from `regex_table` if `regex_return_cols` specified
#' }
#' @examples
#' @examples
#' Create sample data
#' data <- data.frame(
#'   id = 1:3,
#'   text = c("I love apples", "Bananas are great", "Oranges and apples"),
#'   stringsAsFactors = FALSE
#' )
#' 
#' Create regex patterns
#' patterns <- data.frame(
#'   pattern = c("apples", "bananas", "oranges"),
#'   category = c("fruit", "fruit", "fruit")
#' )
#' 
#' # Extract matches
#' extract(data, "text", patterns)
#' @importFrom chk chk_data chk_subset chk_character chk_flag
#' @importFrom pbapply pblapply pboptions
#' @importFrom stringi stri_detect_regex stri_extract_first_regex
#' @importFrom dplyr %>% as_tibble group_by summarise across all_of distinct ungroup bind_rows
#' @importFrom stats na.omit
#' @export
extract <- function(data,
                    col_name = "text",
                    regex_table,
                    pattern_col = "pattern",
                    return_cols = NULL,
                    regex_return_cols = NULL,
                    date_col = NULL,
                    date_start = NULL,
                    date_end = NULL,
                    remove_acronyms = FALSE,
                    do_clean_text = TRUE,
                    verbose = TRUE,
                    cl = NULL) {
  
  # Validate input and data
  if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    col_name <- "text"
  }
  
  chk::chk_data(data)
  chk::chk_data(regex_table)
  chk::chk_subset(col_name, names(data))
  chk::chk_subset(pattern_col, names(regex_table))
  
  if (!is.null(regex_return_cols)) {
    chk::chk_subset(regex_return_cols, names(regex_table))
  }
  
  chk::chk_character(data[[col_name]], x_name = paste0("column '", col_name, "'"))
  chk::chk_flag(verbose)
  
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb), add = TRUE)
  
  if (nrow(data) == 0 || nrow(regex_table) == 0) {
    if (verbose) message("Input data or regex_table is empty")
    return(dplyr::tibble())
  }
  
  original_col_order <- names(data)
  data <- dplyr::mutate(data, row_id = dplyr::row_number())
  
  # Date filtering
  if (!is.null(date_col)) {
    chk::chk_subset(date_col, names(data))
    
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
      return(dplyr::tibble())
    }
  }
  
  # Prepare patterns
  patterns <- unique(stats::na.omit(regex_table[[pattern_col]]))
  
  if (remove_acronyms) {
    patterns <- patterns[!grepl("^[A-Z]{2,}$", patterns)]
  }
  
  if (length(patterns) == 0) {
    if (verbose) message("No patterns provided (or all removed via filters).")
    return(dplyr::tibble())
  }
  
  # Text prep
  text_raw <- data[[col_name]]
  text_search <- text_raw
  
  if (do_clean_text && exists("clean_text", mode = "function")) {
    text_search <- clean_text(text_search)
  }
  
  # Run text matching
  matches_found <- extract_matches_all_internal(
    text_search = text_search,
    text_raw = text_raw,
    row_ids = data$row_id,
    patterns = patterns,
    id_col_name = "row_id",
    verbose = verbose,
    cl = cl
  )
  
  if (nrow(matches_found) == 0) {
    if (verbose) message("Number of rows with matches: 0")
    return(dplyr::tibble())
  }
  
  # Join regex metadata
  if (!is.null(regex_return_cols)) {
    meta_data <- regex_table |>
      dplyr::select(dplyr::all_of(c(pattern_col, regex_return_cols))) |>
      dplyr::distinct()
    
    matches_found <- dplyr::left_join(
      matches_found,
      meta_data,
      by = c("pattern" = pattern_col)
    )
  }
  
  result <- dplyr::left_join(
    matches_found,
    data,
    by = "row_id"
  )
  
  # Column selection and ordering
  if (!is.null(return_cols)) {
    valid_cols <- return_cols[return_cols %in% names(result)]
    cols_to_keep <- unique(c(valid_cols, "pattern", "match", "row_id", regex_return_cols))
    result <- result[, cols_to_keep, drop = FALSE]
  } else {
    final_cols <- c(original_col_order, "pattern", "match", "row_id", regex_return_cols)
    final_cols <- final_cols[final_cols %in% names(result)]
    result <- result[, final_cols, drop = FALSE]
  }
  
  result <- result[order(result$row_id), ]
  
  if (verbose) message("Number of rows with matches: ", nrow(result))
  
  dplyr::as_tibble(result)
}

#' @title Extract All matches per pattern
#' @description Internal function to extract matches using dual-text approach.
#' @keywords internal
extract_matches_all_internal <- function(text_search,
                                         text_raw,
                                         row_ids,
                                         patterns,
                                         id_col_name,
                                         verbose = FALSE,
                                         cl = NULL) {
  
  if (verbose) {
    message(sprintf(
      "Scanning %d patterns against %d text entries (first occurrence per pattern)...",
      length(patterns),
      length(text_search)
    ))
  }
  
  regex_opts <- stringi::stri_opts_regex(case_insensitive = TRUE)
  
  results_list <- pbapply::pblapply(patterns, function(pat) {
    
    has_match <- tryCatch(
      stringi::stri_detect_regex(text_search, pat, opts_regex = regex_opts),
      error = function(e) rep(FALSE, length(text_search))
    )
    
    if (!any(has_match)) return(NULL)
    
    indices <- which(has_match)
    
    # Extract first match from original (raw) text
    actual_text <- tryCatch(
      stringi::stri_extract_first_regex(
        text_raw[indices],
        pat,
        opts_regex = regex_opts
      ),
      error = function(e) rep(NA_character_, length(indices))
    )
    
    # Fallback: extract from cleaned text if raw extraction fails
    na_idx <- is.na(actual_text)
    if (any(na_idx)) {
      actual_text[na_idx] <- stringi::stri_extract_first_regex(
        text_search[indices][na_idx],
        pat,
        opts_regex = regex_opts
      )
    }
    
    list(
      row_id = row_ids[indices],
      pattern = rep.int(pat, length(indices)),
      match = actual_text
    )
    
  }, cl = cl)
  
  df <- dplyr::bind_rows(results_list)
  
  if (nrow(df) == 0) {
    return(dplyr::tibble())
  }
  
  names(df)[names(df) == "row_id"] <- id_col_name
  df
}