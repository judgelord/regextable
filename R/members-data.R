#' @title Names of members of the US Congress
#' @description A dataset of the names of all members of each United States Congress, including presidents. The `pattern` column serves as a lookup table to match members of Congress to text supplied to [extractMemberName()].
#' @format A data frame with 49938 rows and 9 variables:
#' \describe{
#'   \item{\code{congress}}{double COLUMN_DESCRIPTION}
#'   \item{\code{chamber}}{character COLUMN_DESCRIPTION}
#'   \item{\code{bioname}}{character COLUMN_DESCRIPTION}
#'   \item{\code{pattern}}{character COLUMN_DESCRIPTION}
#'   \item{\code{icpsr}}{double COLUMN_DESCRIPTION}
#'   \item{\code{state_abbrev}}{character COLUMN_DESCRIPTION}
#'   \item{\code{district_code}}{double COLUMN_DESCRIPTION}
#'   \item{\code{first_name}}{character COLUMN_DESCRIPTION}
#'   \item{\code{last_name}}{character COLUMN_DESCRIPTION}
#'}
#' @details DETAILS
"members"
