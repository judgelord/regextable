# A function to map over congresses
# one congress at a time
extractNamesPerCongress <- function(congress_i, data, members, col_name, congress, chamber,
                                    state_abbrev, verbose = TRUE, cl = NULL){

  # subset to one congress
  # Note: Use %in% rather than == in case of NAs
  in_congress_i <- congress %in% congress_i
  data <- data[in_congress_i,]
  data$congress <- congress_i

  if (verbose && is.finite(congress_i)) {
    chk::msg(
      (stringr::str_c("searching data for members of the ", congress_i, "th congress, n = ",
                      nrow(data), " (", length(unique(data[[col_name]])), " distinct strings)"#,
                      # broken by dplyr 1.0.0, reverted in and works with 1.0.1
                      #" Most common string: \"", count(data, string) %>% top_n(1, n) %>% .[1,1], "\""
      )
      ))
  }

  members <- members[members$congress %in% congress_i,]

  if (!is.null(chamber)) {
    data$chamber <- chamber[in_congress_i]
    same_chamber <- function(d, y) {
      is.na(d$chamber) | d$chamber == y
    }
  }
  else {
    data$chamber <- NULL
    same_chamber <- function(d, y) {
      rep(TRUE, nrow(d))
    }
  }

  if (!is.null(state_abbrev)) {
    data$state_abbrev <- state_abbrev[in_congress_i]
    same_state <- function(d, y) {
      is.na(d$state_abbrev) | d$state_abbrev == y
    }
  }
  else {
    data$state_abbrev <- NULL
    same_state <- function(d, y) {
      rep(TRUE, nrow(d))
    }
  }

  # search only if that congress exists in data

  # if congress not in members file
  # if (!congress_i %in% members$congress && "DATE" %in% names(data)) {
  #
  #   string <- sym(col_name)
  #   ## Message for when errors are probably non-observations (short strings or NA)
  #   nonobs <- "but empty string, so probably non-observations"
  #
  #   base::message(red(paste(
  #     paste0("Bad dates in ", congress_i, "th congress?"),
  #     paste(data %>%
  #             mutate('{{string}}' = ifelse(
  #               nchar({{string}} < 3) |
  #                 string %in% c("na", "na na", "(b)(6)", "") |
  #                 is.na(string),
  #               nonobs,
  #               {{string}}) ) %>%
  #             group_by({{string}}) %>%
  #             mutate(DATE = paste0(unique(DATE), collapse = ", "),
  #                    row = paste0(unique(data_id), collapse = ";") %>% str_trunc(4+(10*7)+3) ) %>% # "row [first 10 row numbers]..."
  #             count(DATE, row, {{string}}, wt = NULL) %>%
  #             arrange(row) %>%
  #             arrange(-n) %>%
  #             ungroup() %>%
  #             transmute(strings = paste0("row ", row, ", DATE = ", DATE, " \"", string, "\"")) %>%
  #             .$strings,
  #           collapse = "\n"),
  #     sep = "\n")))
  #
  #   data <- data %>%
  #     mutate(pattern = "Date out of range",
  #            first_name = NA,
  #            last_name = NA)
  # }

  # Create arbitrary non-overlapping variable name by
  # appending ".." to longest existing name
  member_row_match_col <- paste0("..", names(data)[which.max(nchar(names(data)))])

  # For each pattern in members, find matches in data[[col_name]]
  member_matches <- pbapply::pblapply(seq_len(nrow(members)), function(i) {
    possible_matches <- which(same_chamber(data, members$chamber[i]))
    if (length(possible_matches) == 0) return(NULL)
    possible_matches <- possible_matches[same_state(data[possible_matches,], members$state_abbrev[i])]
    if (length(possible_matches) == 0) return(NULL)
    possible_matches[stringr::str_detect(data[[col_name]][possible_matches], members$pattern[i])]
  }, cl = cl)

  # For each row in data, find which member_matches were matched to that row
  match_list <- function(i, l) {
    s <- rep(seq_along(l), lengths(l))
    ll <- unlist(l)
    lapply(i, function(i_) s[ll == i_])
  }
  data[[member_row_match_col]] <- match_list(seq_len(nrow(data)), member_matches)

  data <- tidyr::unnest(data, {{member_row_match_col}}, keep_empty = TRUE)

  #Merge found units in members
  data <- dplyr::bind_cols(data[!names(data) %in% names(members)],
                           members[data[[member_row_match_col]],])

  data[[member_row_match_col]] <- NULL

  return(data)
}
