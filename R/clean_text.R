# This function cleans up text.
# Based from legislators package but simplified to be more generic.
clean_text <- function(FROM){

  FROM %>%
    trimws() %>% #removes leading and trailing white space
    stringr::str_remove('\\+') %>%
    stringr::str_remove("\u2014") %>% #em dash
    stringr::str_replace_all("\n", " ") %>% # remove paragraph breaks
    stringr::str_replace_all(" , | ,|,", ", ") %>% # fix misplaced commas
    stringr::str_replace_all("\\.", " ") %>% #remove periods
    stringr::str_replace_all("\\s*,\\s*", ",") %>% #remove multiple spaces before and after commas
    stringr::str_replace_all(",{2,}", ",") %>% #removing commas that repeat
    stringr::str_replace_all(",",", ") %>% #sets space after each comma
    stringr::str_squish() # replace spaces with a single space
}
