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
                    verbose = TRUE) {
  
  # --- Process data and col_name ---
  if (is.data.frame(data)) {
    if (ncol(data) > 1) {
      if (missing(col_name)) stop("`col_name` must be specified.")
      if (!col_name %in% names(data))
        stop("The value supplied to `col_name` must be a column in `data`.")
      if (!is.character(data[[col_name]]))
        stop("The column named in `col_name` must be a character vector.")
    } else {
      if (!is.character(data[[1]]))
        stop("`data` does not contain a character vector to extract patterns from.")
      if (missing(col_name)) col_name <- names(data)
    }
  } else if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    if (missing(col_name)) col_name <- "text"
  } else {
    stop("`data` must be a data frame or a character vector.")
  }
  
  # --- Process regex table ---
  if (!"pattern" %in% names(regex_table))
    stop("`regex_table` must have a 'pattern' column.")
  
  data$data_id <- seq_len(nrow(data))
  
  # --- Extract matches ---
  if (verbose) message("Extracting pattern matches...")
  
  matches <- lapply(seq_len(nrow(data)), function(i) {
    text_i <- data[[col_name]][i]
    hits <- regex_table$pattern[sapply(regex_table$pattern, function(p)
      grepl(p, text_i, ignore.case = TRUE, perl = TRUE))]
    if (length(hits) > 0) {
      data.frame(
        data_id = i,
        pattern = hits,
        text = text_i,
        stringsAsFactors = FALSE
      )
    } else NULL
  })
  
  out <- do.call(rbind, matches)
  if (is.null(out)) out <- data.frame()
  
  if (verbose) message("Done.")
  return(out)
}