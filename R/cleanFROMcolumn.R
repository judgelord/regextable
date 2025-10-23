# This function cleans up text.
# SUCH CODE SHOULD BE CONSOLIDATED HERE
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
    stringr::str_remove('\\+') %>%
    stringr::str_remove("\u2014") %>% #em dash

    # remove paragraph breaks
    stringr::str_replace_all("\n", " ") %>%

    # fix misplaced commas
    #FROM <- gsub("(\\w+) ,(\\w+)|(\\w+) , (\\w+)", "\\1, \\2", FROM)
    stringr::str_replace_all(" , | ,|,", ", ") %>%

    # remove
    stringr::str_remove(generational_suffixes) %>%

    # replace with comma
    stringr::str_replace(post_nominal_letters, replacement = ",") %>%

    # remove periods
    stringr::str_replace_all("\\.", " ") %>%

    #removing commas that repeat
    stringr::str_replace_all(",{2,}", ",") %>%

    #remove multiple spaces before and after commas
    stringr::str_replace_all("\\s*,\\s*", ", ") %>% 

    # replace spaces with a single space
    stringr::str_squish()
}
