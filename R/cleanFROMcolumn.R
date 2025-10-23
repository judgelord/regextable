# This function cleans up text from which member names will be extracted.
# SUCH CODE SHOULD BE CONSOLIDATED HERE
# It is used in extractMemberNames etc. to preprocess text.
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

    # remove common names in quotes
    psub(sprintf('\\"(%s)\\"', common_names),
         "", ignore.case = TRUE)  %>%

    # remove common names in parentheses
    psub(sprintf('\\((%s)\\)', common_names),
         "", ignore.case = TRUE) %>%

    # remove paragraph breaks
    stringr::str_replace_all("\n", " ") %>%

    # remove extra white space inside strings
    stringr::str_squish() %>%

    # fix misplaced commas
    #FROM <- gsub("(\\w+) ,(\\w+)|(\\w+) , (\\w+)", "\\1, \\2", FROM)
    stringr::str_replace_all(" , | ,|,", ", ") %>%

    # remove extra white space inside strings again
    stringr::str_squish() %>%

    # remove
    stringr::str_remove(generational_suffixes) %>%

    # replace with comma
    stringr::str_replace(post_nominal_letters, replacement = ",") %>%

    # remove paragraph breaks
    stringr::str_replace_all("\n", " ") %>%

    # remove extra white space inside strings again
    stringr::str_squish() %>%

    # Delete titles that appear after a commma
    # FROM %<>% str_replace(", (SEN|Sen)(-|\\b)", ", ")
    #FROM <- gsub(", (REP|Rep)(-|\\b)", ", ", FROM)

    # Replace titles at the beginning of a string or not after a comma
    stringr::str_replace("\\b(SEN|Sen)( |- | - |\\. |\\.)|^S( |- | - |\\. |\\.)",
                "Senator ") %>%

    stringr::str_replace("\\b(REP|Rep)( |- | - |\\. |\\.)|^R( |- | - |\\. |\\.)|Congressman|Congresswoman",
                "Representative ") %>%

    # trim down extra spaces
    stringr::str_squish() %>%

    # remove periods
    stringr::str_replace_all("\\.", " ") %>%
    stringr::str_squish() %>%

    #removing double commas
    stringr::str_replace(",+ |, ,", ", ") %>%
    stringr::str_replace(",+ |, ,", ", ") %>%
    stringr::str_replace_all(",,", ",") %>%

    #removing spaces before commas
    stringr::str_replace(" ,", ", ") %>%

    # replace spaces with a single space
    stringr::str_squish()
}
