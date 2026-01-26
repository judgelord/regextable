#' @title Clean Text
#' @description Cleans a character vector by converting text to lowercase,
#' removing selected punctuation (plus signs, em dashes, exclamation
#' points), normalizing commas, and removing whitespace.
#' @param text Character vector to clean.
#' @return Cleaned character vector.
#' @examples
#' clean_text(c("Hello  World!", "This is\tR"))
#' @importFrom dplyr %>%
#' @importFrom stringr str_to_lower str_remove_all str_replace_all str_replace str_squish
#' @export
clean_text <- function(text){
  text %>%
    stringr::str_to_lower() %>%
    stringr::str_remove_all("[+\u2014!?:;]") %>%
    stringr::str_replace_all("[\n\t.-]", " ") %>%
    stringr::str_replace("\\s*(?:,\\s*)+", ", ") %>%
    stringr::str_squish()
}
