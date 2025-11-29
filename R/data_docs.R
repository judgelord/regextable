#' members dataset
#'
#' Lookup table of member names and metadata for regex matching.
#'
#' @format A tibble with 9 columns:
#' \describe{
#'   \item{congress}{Congress number (numeric)}
#'   \item{chamber}{Chamber (House/President/Senate)}
#'   \item{bioname}{Full bio name of the member}
#'   \item{pattern}{Regex pattern to match this member's name}
#'   \item{icpsr}{Numeric ICPSR identifier}
#'   \item{state_abbrev}{Two-letter state abbreviation}
#'   \item{district_code}{District number (0 for President)}
#'   \item{first_name}{First name of the member}
#'   \item{last_name}{Last name of the member}
#' }
#' @source Generated for the `regextable` package.
"members"

#' cr2007_03_01 dataset
#'
#' Sample text dataset used for demonstration of `regextable`.
#'
#' @format A tibble with 5 columns:
#' \describe{
#'   \item{date}{Date of the record (YYYY-MM-DD)}
#'   \item{speaker}{Speaker name in the text}
#'   \item{header}{Header or title of the speech}
#'   \item{url}{Original URL of the source text}
#'   \item{url_txt}{Full text content from the source}
#' }
#' @source Generated for the `regextable` package.
"cr2007_03_01"
