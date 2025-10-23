#' @title Fix common typos
#' @description `fix_typos()` standardizes a character vector for use in [extractMemberName()] by applying some heuristic processing, setting all text to lowercase and, optionally, removing common typos if a list of such is supplied.
#' @param x a character vector containing the names of congress members.
#' @param typos a matrix or data frame containing common typos and their corrections. Should be a 2-column matrix where the first column contains regular expressions corresponding to typos and the second column contain the values that should replace them. These are passed to the `pattern` and `replacement` arguments of [stringr::str_replace_all()]. By default, the [typos] dataset that accompanies the package is used. If `NULL`, no typos will be fixed.
#' @param fix_ocr `logical`; whether to fix OCR errors.
#' @param verbose `logical`; whether to display information about the process of fixing typos, including a progress bar.
#' @return A character vector with typos replaced by their corrections.
#' @details DETAILS #Explain processing
#' @examples
#' @seealso [extractMemberName()], [stringr::str_replace_all()]

#' @export
fix_typos <- function(x, typos = legislators::typos, fix_ocr = TRUE, verbose = TRUE) {
  chk::chk_flag(fix_ocr)
  chk::chk_flag(verbose)

  x <- cleanFROMcolumn(x)

  if (fix_ocr) {
    x <- ocr.errors(x)
  }

  x <- x %>%
    # lower case
    tolower() %>%
    stringr::str_replace("senator senator", "senator") %>%
    stringr::str_replace("represenative representative", "representative") %>%

    # na's pasted in
    stringr::str_replace("na politano", "napolitano") %>%
    stringr::str_remove("^na ") %>%
    stringr::str_remove("^na ") %>%
    stringr::str_replace("han na\\b", "hanna") %>%
    stringr::str_remove_all("\\bna\\b") %>%
    stringr::str_squish() %>%

    # misplaced commas
    stringr::str_replace(" ,", ", ") %>%
    stringr::str_squish() %>%

    # explicit NA
    tidyr::replace_na("")

  if (!is.null(typos)) {

    check_typos(typos)
    typos <- as.data.frame(typos)

    if (verbose) {
      chk::msg("Fixing typos...")
      pb <- pbapply::startpb(0, nrow(typos))
    }

    for (i in seq_len(nrow(typos))) {
      x <- stringr::str_replace_all(x, typos[[1]][i],
                                    paste(typos[[2]][i], ""))
      if (verbose) pbapply::setpb(pb, i)
    }

    #FIXME problem created by correcting typos
    x <- x %>%
      stringr::str_replace(" ,", ", ") %>%
      stringr::str_squish()

    if (verbose) pbapply::closepb(pb)
  }
  x
}

check_typos <- function(typos) {
  if (!is.data.frame(typos) && !(is.matrix(typos) && is.character(typos))) {
    chk::err("`typos` must be a data frame or character matrix")
  }
  if (ncol(typos) != 2) {
    chk::err("`typos` must have two columns")
  }
  typos <- as.data.frame(typos)
  if (!is.character(typos[[1]]) || !is.character(typos[[2]])) {
    chk::err("both columns in `typos` must be character")
  }
  if (any(stringr::str_detect(typos[[2]], "\\$|\\||\\*|\\[|\\]|\\;"))) {
    chk::wrn("regex expressions found in the second column of `typos`; the first column should contain the typos and the second column should contain the correct text")
  }
}
