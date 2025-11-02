#' @title Data Frame Cleaning Helpers
#' @description Functions to apply text cleaning to specific columns or all character columns.
#' @import dplyr
#' @import stringr
#' @export

#Clean a single column in a data frame
clean_column <- function(df, col_name) {
  df %>%
    mutate(
      {{col_name}} := clean_text(.data[[col_name]])  #apply basic cleaning
    )
}

# Clean all character columns in a data frame
clean_all_columns <- function(df) {
  df %>%
    mutate(across(where(is.character), ~clean_text(.x)))
}

# Clean a single column and apply regex table
clean_column_with_table <- function(df, col_name, table) {
  df[[col_name]] <- clean_text(df[[col_name]]) %>% apply_regextable(table)
}

# Clean all character columns and apply regex table
clean_all_columns_with_table <- function(df, table) {
  df[] <- lapply(df, function(col) {
    if (is.character(col)) {
      clean_text(col) %>% apply_regextable(table)
    } else {
      col
    }
  })
  df
}