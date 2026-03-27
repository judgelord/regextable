#' @title Clean Text
#' @description Cleans a character vector by converting to lowercase, 
#' removing or replacing specific punctuation, normalizing commas, 
#' and squishing excess whitespace.
#' @param text Character vector to clean.
#' @return A cleaned character vector.
#' @examples
#' clean_text(c("Hello  World!?", "This--is\tR.\nTesting: 1, 2, , 3;"))
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
