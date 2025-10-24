# This function cleans up text.
# Based from legislators package but simplified to be more generic.
cleanFROMcolumn <- function(FROM){

  #gsub() appropriate for piping
  #Can use stringr::str_replace_all() but maybe regex rules are different,
  #e.g., https://stackoverflow.com/q/62471164/6348551
  psub <- function(x, pattern, replacement, ...) {
    gsub(pattern = pattern, replacement = replacement, x = x, ...)
  }

  # remove +
  FROM %>%
    trimws() %>% #removes leading and trailing white space
    stringr::str_remove('\\+') %>%
    stringr::str_remove("\u2014") %>% #em dash
    stringr::str_replace_all("\n", " ") %>% # remove paragraph breaks
    stringr::str_replace_all(" , | ,|,", ", ") %>% # fix misplaced commas
    stringr::str_replace_all("\\.", " ") %>% #remove periods
    stringr::str_replace_all(",{2,}", ",") %>% #removing commas that repeat
    stringr::str_replace_all("\\s*,\\s*", ", ") %>% #remove multiple spaces before and after commas
    stringr::str_squish() # replace spaces with a single space
}
