#' @title Extract pattern matches from text
#' @description Uses a regex lookup to extract pattern matches from a data frame. Typo correction planned for future versions.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Column name in data frame containing text to search through.
#' @param regex_table A regex lookup table with at least one pattern column.
#' @param pattern_col Name of the regex pattern column in regex_table (default "pattern").
#' @param id_col Optional column in `data` used to filter rows before matching.
#' @param id_filter Optional value or vector of IDs to restrict which rows of `data` are matched.
#' @param date_col Optional column in 'data' for date filtering.
#' @param date_start Optional start date for filtering 'data'.
#' @param date_end Optional end date for filtering 'data'.
#' @param typo_table Optional table to fix typos in 'data'. # planned for later versions
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
                    id_filter = NULL,
                    date_col = NULL,
                    date_start = NULL,
                    date_end = NULL,
                    typo_table = NULL,
                    remove_acronyms = FALSE,
                    clean_text = TRUE,
                    verbose = TRUE) {
  
  # Input validation
  if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    if (missing(col_name)) {
      col_name <- "text"
    } 
  } 
  else if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data)){
      stop("Please provide a valid column name for `col_name`.")
    }
  } 
  else {
    stop("`data` must be a data frame or character vector.")
  }
  if (!pattern_col %in% names(regex_table) || all(is.na(regex_table[pattern_col]))) {
    stop("Please provide a valid pattern column name for 'pattern_col'")
  }

  original_col <- col_name
  
  # Text cleaning
  if (clean_text) {
    data[[original_col]] <- clean_text(data[[original_col]])
  }
  
  # TODO: implement typo_table correction in future versions
  #if (!is.null(typo_table)) {
  #  data[[original_col]] <- apply_typos(data[[original_col]], typo_table, verbose)
  #}
  
  # Optional: filter data by ID
  if (!is.null(id_filter)) {
    if (is.null(id_col) || !id_col %in% names(data)) {
      stop("If 'id_filter' is used, a valid 'id_col' in 'data' must be specified")
    }
    else {
      data <- data[data[[id_col]] %in% id_filter, , drop=FALSE]
    }
  }
  
  # Optional: filter data by date
  if (!is.null(date_start) || !is.null(date_end)) {
    if (is.null(date_col) || !date_col %in% names(data)) {
      stop("Please provide a valid `date_col` in 'data' for filtering.")
    }
    else {
      date_start <- if (!is.null(date_start)) as.Date(date_start) else -Inf
      date_end <- if (!is.null(date_end)) as.Date(date_end) else Inf
      data[[date_col]] <- as.Date(data[[date_col]])
      data <- data[data[[date_col]] >= date_start & data[[date_col]] <= date_end, , drop = FALSE]
    }
  }
  
  # Get a vector of patterns from regex_table
  patterns <- regex_table[[pattern_col]]
  patterns <- trimws(patterns)
  patterns <- stringr::str_squish(patterns)
  
  # Remove patterns that are all-caps acronyms (2+ letters) if requested
  if (remove_acronyms) {
    is_acronym <- grepl("^[A-Z]{2,}$", patterns)
    patterns <- patterns[!is_acronym]
    if (length(patterns)==0) {
      if (verbose) {
        message("No patterns after removing acronyms.")
      }
      return(create_empty_output())
    }
  }
  
  if (verbose) {
    message("Extracting pattern matches...")
  }
  
  # Vectorized detection
  text_vector <- data[[original_col]]
  combined_pattern <- paste(patterns, collapse = "|")
  
  has_match <- stringi::stri_detect_regex(text_vector, combined_pattern, case_insensitive = TRUE)
  
  if (sum(has_match) == 0) {
    if (verbose) {
      message("No matches found.")
    }
    return(create_empty_output(data))
  }
  
  # Get matching rows
  matched_data <- data[has_match, , drop = FALSE]
  matched_data$matched_pattern <- stringi::stri_extract_first_regex(matched_data[[original_col]], combined_pattern)
  if (verbose) {
    message("Done. Found ", nrow(matched_data), " matches.")
  }
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