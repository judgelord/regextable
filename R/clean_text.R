#' @title Clean Text
#' @description Cleans a character vector (trims spaces, fixes punctuation, etc.).
#' @param text Character vector to clean.
#' @return Cleaned character vector.
#' @importFrom dplyr %>% 
#' @importFrom stringr str_to_lower str_remove_all str_replace_all str_replace str_squish
#' @export
clean_text <- function(text){

  FROM %>%
    stringr::str_to_lower() %>% #makes str lowercase for consistency
    stringr::str_remove_all("[+\u2014]") %>% #removes '+' and em-dash
    stringr::str_replace_all("[\n.]", " ") %>% #replaces new lines and periods to one space
    stringr::str_replace("\\s*(?:,\\s*)+", ", ") %>% #replaces sequences and white space with a single ", "
    stringr::str_squish() # replace spaces with a single space
}