process_congress <- function(congress, col_name, data, members) {
  if (is.null(congress)) {
    chk::err("`congress` must be supplied")
  }

  if (chk::vld_string(congress)) {
    if (!congress %in% names(data)) {
      chk::err("the value supplied to `congress` is not the name of a variable in `data`")
    }
    if (congress == col_name) {
      chk::err("the value supplied to `congress` connot be the same as `col_name`")
    }
    congress <- data[[congress]]
  }
  else if (chk::vld_whole_numeric(congress)) {
    if (length(congress) == 1) {
      if (anyNA(congress) || congress < 1 || congress > max(members$congress)) {
        chk::wrn("the value supplied to `congress` is not present in `members`. No strings will be matched.")
      }
      congress <- rep(congress, nrow(data))
    }
    else if (length(congress) == nrow(data)) {
      if (anyNA(congress) || any(congress < 1 | congress > max(members$congress))) {
        chk::wrn("not all values supplied to `congress` are present in `members`")
      }
    }
    else {
      chk::err("if supplied as a number, `congress` must have length 1 or equal to the number of rows of `data`")
    }
  }
  else {
    chk::err("`congress` must be a vector containing the congresses for each row of `data` or the name of the variable in `data` containing congress")
  }

  return(congress)
}

process_chamber <- function(chamber, col_name, data, members) {
  if (is.null(chamber)) {
    return(NULL)
  }
  if (!chk::vld_character(chamber)) {
    chk::err("`chamber` must be a vector containing the congresses for each row of `data` or the name of the variable in `data` containing congress")
  }

  if (length(chamber) == 1) {
    if (tolower(chamber) %in% tolower(members$chamber)) {
      chamber <- rep(chamber, nrow(data))
    }
    else if (chamber %in% names(data)) {
      if (chamber == col_name) {
        chk::err("the value supplied to `chamber` connot be the same as `col_name`")
      }
      chamber <- data[[chamber]]
      if (!chk::vld_character_or_factor(chamber)) {
        chk::err("the variable names by `chamber` must be a character vector")
      }
      chamber <- as.character(chamber)
      unique_chambers_in_members <- unique(tolower(members$chamber))
      if (!all(unique(tolower(chamber)) %in% unique_chambers_in_members)) {
        chk::wrn("not all values in the variable named by `chamber` are present in `members`")
        is.na(chamber)[!tolower(chamber) %in% unique_chambers_in_members] <- TRUE
      }
    }
    else {
      chk::err("if supplied as a string, `chamber` must be the name of the variable in `data` containing chambers or a value of chamber to be used for all rows in `data`")
    }
  }
  else if (length(chamber) == nrow(data)) {
    unique_chambers_in_members <- unique(tolower(members$chamber))
    if (!all(unique(tolower(chamber)) %in% unique_chambers_in_members)) {
      chk::wrn("not all values supplied to `chamber` are present in `members`")
      is.na(chamber)[!tolower(chamber) %in% unique_chambers_in_members] <- TRUE
    }
  }
  else {
    chk::err("`chamber` must have length 1 or equal to the number of rows of `data`")
  }

  stringr::str_to_title(chamber)
}

# Returns abbreviated state name (2-letter)
process_state_abbrev <- function(state, col_name, data) {
  if (is.null(state)) {
    return(NULL)
  }
  if (!chk::vld_character(state)) {
    chk::err("`state` must be a vector containing the state abbreviations for each row of `data` or the name of the variable in `data` containing state abbreviations")
  }

  if (length(state) == 1) {
    if (toupper(state) %in% state_abbreviations) {
      state <- rep(toupper(state), nrow(data))
    }
    else if (tolower(state) %in% tolower(state_names)) {
      state <- rep(state_name_to_abbrev(state), nrow(data))
    }
    else if (state %in% names(data)) {
      if (state == col_name) {
        chk::err("the value supplied to `state` connot be the same as `col_name`")
      }
      state <- data[[state]]
      if (!chk::vld_character_or_factor(state)) {
        chk::err("`state` must be a character vector")
      }
      if (is.factor(state)) {
        state <- as.character(state)
      }

      states_not_abbrev <- which(!is.na(state) & !toupper(state) %in% state_abbreviations)
      if (length(states_not_abbrev) > 0) {
        state[states_not_abbrev] <- state_name_to_abbrev(state[states_not_abbrev])
      }

      if (anyNA(state[states_not_abbrev])) {
        chk::wrn("not all values in the variable named by `state` are valid states")
      }
    }
    else {
      chk::err("if supplied as a string, `state` must be the name of the variable in `data` containing state names or abbreviations, or a state to be used for all rows in `data`")
    }
  }
  else if (length(state) == nrow(data)) {
    states_not_abbrev <- which(!is.na(state) & !toupper(state) %in% state_abbreviations)
    if (length(states_not_abbrev) > 0) {
      state[states_not_abbrev] <- state_name_to_abbrev(state[states_not_abbrev])
    }

    if (anyNA(state[states_not_abbrev])) {
      chk::wrn("not all values in `state` are valid states")
    }
  }
  else {
    chk::err("`state` must have length 1 or equal to the number of rows of `data`")
  }

  state
}

state_name_to_abbrev <- function(state) {
  unname(state_abbreviations[match(tolower(state), tolower(state_names))])
}

check_members <- function(members = NULL) {
  if (is.null(members)) {
    chk::err("`members` must be supplied")
  }
  if (!is.data.frame(members)) {
    chk::err("`members` must be a data frame")
  }
  correct_types <- c(congress = "numeric",
                     chamber = "character",
                     bioname = "character",
                     pattern = "character",
                     icpsr = "numeric",
                     state_abbrev = "character",
                     district_code = "numeric",
                     first_name = "character",
                     last_name = "character"
  )

  if (!all(names(correct_types) %in% names(members))) {
    chk::err("`members` does not have the required column names. ll columns in the `members` dataset that accompany `legislators` are required. See help(\"members\", package = \"legislators\") for a list")
  }

  bad_types <- which(vapply(members[names(correct_types)], mode, character(1L)) != correct_types)
  if (length(bad_types) > 0) {
    types <- unique(correct_types[bad_types])
    mes <- paste(vapply(types, function(t) {
      chk::message_chk(
      sprintf("The following variable%%s in `members` should be %s: %s",
              t, paste(names(correct_types)[bad_types][correct_types[bad_types] == t], collapse = ", ")),
      n = sum(correct_types[bad_types] == t), tidy = FALSE)
    }, character(1L)), collapse = "\n  ")
    chk::err(mes, tidy = FALSE)
  }

  cols_w_na <- which(vapply(members, anyNA, logical(1L)))
  if (length(cols_w_na) > 0) {
    chk::wrn(sprintf("The following variable%%s in `members` contain NA values: %s",
                     paste(names(members)[cols_w_na], collapse = ", ")),
             n = length(cols_w_na), tidy = FALSE)
  }

  if (!all(members$state_abbrev %in% state_abbreviations)) {
    bad_states <- setdiff(unique(members$state_abbrev),
                          state_abbreviations)
    chk::wrn(sprintf("The following value%%s in the `state_abbrev` column of `members` %%r not %s: %s",
                     ngettext(length(bad_states), "a valid state", "valid states"),
                     paste(bad_states, collapse = ", ")),
             n = length(bad_states), tidy = FALSE)
  }
}
