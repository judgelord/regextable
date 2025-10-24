library(dplyr)
library(stringr)

#Cleans text to specific columns in the data frame.
clean_column <- function(df, col_name){
  df %>%
    mutate(
      {{col_name}} := clean_text(.data[[col_name]]) #applies clean_text function to column
    )
}