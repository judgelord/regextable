library(dplyr)
library(stringr)
#Applies clean_text to all character columns
clean_all_columns <- function(df){
  df %>%
    mutate(across(where(is.character), ~clean_text(.x)))
}