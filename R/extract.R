#' @title Extract pattern matches from text
#' @description Uses a regex lookup table to extract pattern matches from supplied text.
#' @param data A data frame or character vector containing the text to search.
#' @param col_name Name of the variable in `data` containing text to search.
#' @param regex_table A regex lookup table with at least a `pattern` column.
#' @param verbose Logical; whether to display basic progress messages.
#' @return A data frame with one row per match, including data_id, pattern, and text.
#' @export

extract <- function(data,
                    col_name,
                    regex_table,
                    pattern_col = "pattern",
                    id_col = NULL,
                    date_start = NULL,
                    date_end = NULL,
                    strict = TRUE,
                    verbose = TRUE) {
  
  #Process data
  if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    if (missing(col_name)) col_name <- "text"
  } else if (is.data.frame(data)) {
    if (missing(col_name) || !col_name %in% names(data))
      stop("Please provide a valid column name for `col_name`.")
  } else stop("`data` must be a data frame or character vector.")
  
  data$data_id <- seq_len(nrow(data))
  
  #Process regex table
  if (!pattern_col %in% names(regex_table))
    stop("`pattern_col` not found in `regex_table`.")
  
  #Optional date filtering
  if (!is.null(date_start) || !is.null(date_end)) {
    if (!"date" %in% names(regex_table))
      stop("regex_table has no 'date' column for filtering")
    date_start <- if (!is.null(date_start)) as.Date(date_start) else -Inf
    date_end <- if (!is.null(date_end)) as.Date(date_end) else Inf
    regex_table <- regex_table[regex_table$date >= date_start &
                                 regex_table$date <= date_end, ]
  }
  
  #Optional strict/inclusive pattern selection
  #Could be handled here or with a helper function
  
  #Extract matches
  if (verbose) message("Extracting pattern matches...")
  
  matches <- lapply(seq_len(nrow(data)), function(i) {
    text_i <- data[[col_name]][i]
    hit_rows <- sapply(regex_table[[pattern_col]], function(p) 
      grepl(p, text_i, ignore.case = TRUE, perl = TRUE))
    hits <- regex_table[hit_rows, , drop = FALSE]
    if (nrow(hits) > 0) {
      out <- data.frame(
        data_id = i,
        text = text_i,
        pattern = hits[[pattern_col]],
        stringsAsFactors = FALSE
      )
      if (!is.null(id_col) && id_col %in% names(hits)) {
        out$id <- hits[[id_col]]
      }
      out
    } else NULL
  })
  
  out <- do.call(rbind, matches)
  if (is.null(out)) out <- data.frame()
  
  if (verbose) message("Done.")
  return(out)
}