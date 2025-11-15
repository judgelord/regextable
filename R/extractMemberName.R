#' @title Extract congress member names from text
#' @description `extractMemberName()` uses a regular expressions lookup to extract names of congress members from supplied text.
#' @param data a data frame with a variable (specified in `col_name`) containing the text from which members of congress are to be extracted. Can also be a character vector containing the text, which will be converted to a data frame.
#' @param col_name `character`; when `data` is a data frame, the name of the variable containing congress members' names. When `data` is a character vector, the name given to the variable containing the original text in the output (if unspecified, `"speaker"` will be used).
#' @param members a regex table containing variations of congress member names. By default, the [members] dataset accompanying the package is used. This table must have the following columns:
#' @param typos a dataset from which to extract typos. By default, the [typos] dataset accompanying the package is used. This table must have the following columns:
#' @param congress the name of a variable in `data` containing the congress for each row, or a vector of congress numbers for each row. If a single value is supplied, it will be applied to all rows. The argument is required.
#' @param chamber the name of a variable in `data` containing the chamber for each row, or a character vector containing the chamber for each row. If a single value is supplied, it will be applied to all rows. Allowable values include the values in `members`, which, by default, are `"Senate"`, `"House"`, and `"President"`. `NA` values are allowed and will not be incorporated into the match. This argument is optional. See Details.
#' @param state the name of a variable in `data` containing the state for each row, or a character vector containing the state for each row. If a single value is supplied, it will be applied to all rows. Allowable values include the two-letter abbreviations for each state (e.g., `"MA"`) as well as `"USA"` for rows corresponding to presidents, or the full names of the states (e.g., `"Massachusetts"`). `NA` values are allowed and will not be incorporated into the match. This argument is optional. See Details.
#' @param fix_ocr `logical`; whether to fix OCR errors. Passed to [fix_typos()].
#' @param verbose `logical`; whether to display information about the process of extracting names, including progress bars.
#' @param cl a cluster object created by `parallel::makeCluster()`, or an integer to indicate number of child-processes (integer values are ignored on Windows) for parallel evaluations. Passed to [pbapply::pblapply()].
#'
#' @return A tibble (data frame) with a row for each match containing the following variables:
#'   \item{data_id}{the row number in `data` corresponding to the given match}
#'   \item{icpsr}{the ICPSR ID associated with the matched member}
#'   \item{bioname}{the ICSPR-assigned name of the matched member}
#'   \item{speaker}{the original value used to find matches after processing}
#'   \item{congress}{the congress associated with the matched member}
#'   \item{chamber}{the chamber associated with the matched member}
#'   \item{state_abbrev}{the state (abbreviated) associated with the matched member}
#'   \item{district_code}{the district code associated with the matched member}
#'
#' In addition, all other variable in `data`, including that named in `col_name`, will be included in the output.
#'
#' @details `extractMemberName()` processes the variable named in `col_name` containing the text from which congress members' names are to be extracted. First, it passes the variable to [fix_typos()] to apply some heuristic processing, and, if `typos` is supplied, it fixes any found typos. Finally, it performs a regular expressions lookup to match congress members listed in `members` to the text. For each member in `members`, a regular expression match is performed to determine whether the text in the given row contains that member. This is done one congress at a time.
#'
#' When `chamber` or `state` are specified, the lookup for each member is restricted to the chamber or state of the member in `members`, respectively, which can increase speed and avoid duplicates (e.g., members of a given congress who appear in more than one chamber). These arguments are optional; when not supplied, only the variable named in `col_name` and congress are used to identify members. It is possible for a single row in `data` to contain multiple members belonging to different states or chambers. In these cases, `chambers` or `state` can be set to `NA` for those rows to avoid using them in their lookup.
#'
#'
#' @examples
#'
#' @seealso
#'
#' @export
extractMemberName <- function(data,
                              col_name,
                              members = legislators::members,
                              typos = legislators::typos,
                              congress,
                              chamber = NULL,
                              state = NULL,
                              fix_ocr = TRUE,
                              verbose = TRUE,
                              cl = NULL) {

  #Process data and col_name
  if (is.data.frame(data)) {
    if (ncol(data) > 1) {
      chk::chk_not_missing(col_name)
      chk::chk_string(col_name)
      if (!col_name %in% names(data)) {
        chk::err("the value supplied to `col_name` must be the name of a variable in `data`")
      }
      if (!is.character(data[[col_name]])) {
        chk::err("the variable named in `col_name` must be a character vector")
      }
    }
    else {
      if (!is.character(data[[1]])) {
        chk::err("`data` does not contain a character vector to extract names from")
      }
      if (missing(col_name)) {
        col_name <- names(data)
      }
      else {
        chk::chk_string(col_name)
        if (!col_name %in% names(data)) {
          chk::err("the value supplied to `col_name` must be the name of a variable in `data`")
        }
      }
    }
  }
  else if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(data)
    if (!missing(col_name)) {
      chk::chk_string(col_name)
      names(data) <- col_name
    }
    else {
      names(data) <- "speaker"
      col_name <- names(data)
    }
  }
  else {
    chk::err("`data` must be a data frame or a character vector")
  }

  #Process `verbose`
  chk::chk_flag(verbose)
  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb))

  #Process members
  check_members(members)

  overlapping_names <- intersect(setdiff(c("data_id", names(members)),
                                         c("congress", "state_abbrev", "chamber")),
                                 names(data))
  if (length(overlapping_names) > 0) {
    chk::wrn(sprintf("The following variable%%s in `data` %%r present in `members` and will be overwritten:\n\n  %s",
                     paste(overlapping_names, collapse = ", ")), n = length(overlapping_names), tidy = FALSE)
    data[overlapping_names] <- NULL
  }

  if (missing(congress) || is.null(congress)) {
    chk::err("`congress` must be specified")
  }
  congress <- process_congress(congress, col_name, data, members)

  chamber <- process_chamber(chamber, col_name, data, members)

  if (!is.null(chamber)) {
    chamber_present <- which(!is.na(chamber))
    data[[col_name]][chamber_present] <- paste(chamber[chamber_present],
                                               data[[col_name]][chamber_present]) %>%
      stringr::str_replace("House", "Represenative") %>%
      stringr::str_replace("Senate", "Senator")
  }

  state_abbrev <- process_state_abbrev(state, col_name, data)

  if (!is.null(state_abbrev)) {
    #add state_abbrev to string if not NA
    state_abbrev_present <- which(!is.na(state_abbrev))
    data[[col_name]][state_abbrev_present] <- paste(data[[col_name]][state_abbrev_present],
                                                    "-",
                                                    state_abbrev[state_abbrev_present])
  }

  # Add Letter ID if missing
  data$data_id <- seq_len(nrow(data))

  # joining with members requires these variables are not there
  data$last_name <- NULL
  data$first_name <- NULL
  data$pattern <- NULL

  # Fix typos, OCR errors, other processing of data[[col_name]]
  data[[col_name]] <- fix_typos(data[[col_name]], typos, fix_ocr, verbose)

  # loop over congresses in data; returned datasets may be larger than original
  data <- dplyr::bind_rows(lapply(unique(congress), extractNamesPerCongress,
                                  data = data, members = members, col_name = col_name,
                                  congress = congress, chamber = chamber,
                                  state_abbrev = state_abbrev, verbose = verbose,
                                  cl = cl))

  data <- dplyr::distinct(data)

  data <- data[c("data_id", "icpsr", "bioname", "last_name", "first_name", "congress",
                 "chamber", "state_abbrev", "district_code",
                 setdiff(names(data), c("data_id", names(members))))]

  return(data)
}


