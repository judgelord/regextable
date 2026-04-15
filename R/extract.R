#' @title Extract Regex Pattern Matches from Text Data
#' @description Matches text against a table of regular expressions and returns extracted matches with optional metadata.
#'
#' @details
#' Pattern matching is performed using R's regular expression engine and is
#' case-insensitive by default. For each input row, the function checks patterns
#' in `regex_table` and returns matches based on the `unique_match` parameter.
#'
#' @param data A data frame or character vector containing the text to search. If a character vector is provided, it is internally converted to a data frame and `col_name` is ignored.
#' @param regex_table A data frame containing regular expression patterns and optional metadata columns.
#' @param col_name Character string specifying the column in `data` that contains text to search. Default is "text".
#' @param pattern_col Character string specifying the column in `regex_table` that contains regex patterns. Default is "pattern".
#' @param typo_table Optional data frame with text replacements for corrections. Replacements are applied sequentially to the text using regex (with word boundaries) before pattern matching.
#' @param typo_from_col Optional column in `typo_table` with text to replace. Default is "typo".
#' @param typo_to_col Optional column in `typo_table` with replacement text. Default is "correction".
#' @param date_col Optional column in `data` for date filtering. If provided, rows are filtered by `date_start` and `date_end` before pattern matching.
#' @param date_start Optional start date (Date object or string like "YYYY-MM-DD") for filtering `data` when `date_col` is specified.
#' @param date_end Optional end date (Date object or string like "YYYY-MM-DD") for filtering `data` when `date_col` is specified.
#' @param data_return_cols Optional vector of column names to include from `data`. Default is `NULL` (only `row_id` is returned).
#' @param regex_return_cols Optional vector of column names to include from `regex_table`. Default is `NULL` (no metadata columns added).
#' @param remove_acronyms Logical; if TRUE, removes patterns consisting only of uppercase letters (2 or more characters) from `regex_table`.
#' @param do_clean_text Logical; if TRUE, applies basic text cleaning to the input before matching.
#' @param unique_match Logical; if TRUE, stops searching after the first match to
#'   find at most one match per row (evaluated in the order patterns appear in `regex_table`).
#'   If FALSE, returns all matches for all patterns.
#' @param use_ner Logical; if TRUE, uses the 'spacyr' package to validate that
#'   matches are actual Named Entities (e.g., organizations). Note: `spacyr`
#'   must be initialized (e.g., via `spacyr::spacy_initialize()`) before calling
#'   this function.
#' @param ner_timing Character string; either "after" or "before". If "after" (default),
#'   regex matches are found first, then validated with NER. If "before", NER extracts
#'   entities first, and regex searches only within those entities.
#' @param ner_entity_types Character vector; the types of Named Entities to keep if `use_ner` is TRUE. Default is "ORG".
#' @param verbose Logical; if TRUE, displays progress messages.
#' @param cl A cluster object created by `parallel::makeCluster()`, or an integer
#'   to indicate number of child processes (integer values are ignored on Windows).
#'   Passed to [pbapply::pblapply()].
#'
#' @return A tibble with the following columns:
#' \itemize{
#'   \item \code{row_id}: Integer identifier corresponding to rows in the input data.
#'   \item Additional columns from \code{data} if \code{data_return_cols} is specified.
#'   \item Additional columns from \code{regex_table} if \code{regex_return_cols} is specified.
#'   \item \code{pattern}: The matched regular expression pattern(s).
#'   \item \code{match}: The extracted text from the data (original casing preserved).
#' }
#' @examples
#' # Create sample data
#' data <- data.frame(
#'   id = 1:3,
#'   text = c("I love apples", "Bananas are great", "Oranges and apples"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Create regex patterns
#' patterns <- data.frame(
#'   pattern = c("apples", "bananas", "oranges"),
#'   category = c("fruit", "fruit", "fruit")
#' )
#'
#' # Extract all matches
#' extract(data, patterns)
#'
#' # Extract one match per row
#' extract(data, patterns, unique_match = TRUE)
#' @importFrom chk chk_data chk_subset chk_character chk_flag
#' @importFrom pbapply pblapply pboptions
#' @importFrom stringi stri_detect_regex stri_extract_first_regex stri_replace_first_regex
#' @importFrom dplyr %>% as_tibble group_by summarise across all_of distinct ungroup bind_rows
#' @importFrom stats na.omit
#' @export
extract <- function(data,
                    regex_table,
                    col_name = "text",
                    pattern_col = "pattern",
                    typo_table = NULL,
                    typo_from_col = "typo",
                    typo_to_col = "correction",
                    date_col = NULL,
                    date_start = NULL,
                    date_end = NULL,
                    data_return_cols = NULL,
                    regex_return_cols = NULL,
                    remove_acronyms = FALSE,
                    do_clean_text = TRUE,
                    unique_match = FALSE,
                    use_ner = FALSE,
                    ner_timing = "after",
                    ner_entity_types = c("ORG"),
                    verbose = TRUE,
                    cl = NULL) {
  # Validate input and data
  if (is.character(data) && is.null(dim(data))) {
    data <- data.frame(text = data, stringsAsFactors = FALSE)
    col_name <- "text"
  }

  chk::chk_data(data)
  chk::chk_data(regex_table)
  chk::chk_subset(col_name, names(data))
  chk::chk_subset(pattern_col, names(regex_table))

  if (!is.null(regex_return_cols)) {
    chk::chk_subset(regex_return_cols, names(regex_table))
  }

  chk::chk_character(data[[col_name]], x_name = paste0("column '", col_name, "'"))
  chk::chk_flag(verbose)
  chk::chk_flag(use_ner)
  chk::chk_character(ner_entity_types)
  ner_timing <- match.arg(ner_timing, c("after", "before"))

  if (use_ner) {
    if (!requireNamespace("spacyr", quietly = TRUE)) {
      warning("The 'spacyr' package is not installed. Setting use_ner to FALSE.")
      use_ner <- FALSE
    }
    valid_spacy_tags <- c(
      "CARDINAL", "DATE", "EVENT", "FAC", "GPE", "LANGUAGE", "LAW",
      "LOC", "MONEY", "NORP", "ORDINAL", "ORG", "PERCENT", "PERSON",
      "PRODUCT", "QUANTITY", "TIME", "WORK_OF_ART"
    )
    if (!all(ner_entity_types %in% valid_spacy_tags)) {
      warning("One or more 'ner_entity_types' are not standard spaCy tags.
              If you are not using a custom model, check for typos.")
    }
  }

  opb <- pbapply::pboptions(type = if (verbose) "timer" else "none")
  on.exit(pbapply::pboptions(opb), add = TRUE)

  if (nrow(data) == 0 || nrow(regex_table) == 0) {
    if (verbose) message("Input data or regex_table is empty")
    return(dplyr::tibble())
  }

  data <- dplyr::mutate(data, row_id = dplyr::row_number())

  # Date filtering
  if (!is.null(date_col)) {
    chk::chk_subset(date_col, names(data))

    if (!inherits(data[[date_col]], "Date")) {
      data[[date_col]] <- as.Date(data[[date_col]])
    }

    if (!is.null(date_start)) {
      data <- data[data[[date_col]] >= as.Date(date_start), ]
    }
    if (!is.null(date_end)) {
      data <- data[data[[date_col]] <= as.Date(date_end), ]
    }

    if (nrow(data) == 0) {
      if (verbose) message("No data remaining after date filter")
      return(dplyr::tibble())
    }
  }

  # Prepare patterns
  patterns <- unique(stats::na.omit(regex_table[[pattern_col]]))

  if (remove_acronyms) {
    patterns <- patterns[!grepl("^[A-Z]{2,}$", patterns)]
  }

  if (length(patterns) == 0) {
    if (verbose) message("No patterns provided (or all removed via filters).")
    return(dplyr::tibble())
  }

  # Pre-extraction warning
  if (verbose) {
    total_chars <- sum(nchar(data[[col_name]]))
    n_patterns <- nrow(regex_table)
    n_rows <- nrow(data)

    if (!is.null(data_return_cols) && col_name %in% data_return_cols && total_chars > 1e6) {
      message(
        "Input text is large (", total_chars, " characters). \nReturning the original column for each match ",
        "may produce a very large output. Consider limiting data_return_cols or splitting the text."
      )
    }
    if (n_patterns * n_rows > 1e6) {
      message(
        "Number of rows (", n_rows, ") * number of patterns (", n_patterns, ") is high. ",
        "\nThis may be slow or memory-intensive. Consider further parsing the text"
      )
    }
  }

  text_raw <- data[[col_name]]
  text_search <- text_raw

  if (do_clean_text) {
    text_search <- clean_text(text_search)
  }

  if (!is.null(typo_table)) {
    chk::chk_data(typo_table)
    chk::chk_subset(c(typo_from_col, typo_to_col), names(typo_table))
    chk::chk_character(typo_table[[typo_from_col]])
    chk::chk_character(typo_table[[typo_to_col]])

    escaped_typos <- gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", typo_table[[typo_from_col]])
    typo_patterns <- paste0("\\b", escaped_typos, "\\b")

    typo_regex_opts <- stringi::stri_opts_regex(case_insensitive = TRUE)

    for (i in seq_len(nrow(typo_table))) {
      text_search <- stringi::stri_replace_all_regex(
        text_search,
        typo_patterns[i],
        typo_table[[typo_to_col]][i],
        opts_regex = typo_regex_opts
      )
    }

    text_search <- stringi::stri_trim_both(
      stringi::stri_replace_all_regex(text_search, "\\s+", " ")
    )
  }

  # Entity Extraction Before Matching
  if (use_ner && ner_timing == "before") {
    if (verbose) message("Extracting Named Entities (NER) before matching...")

    names(text_raw) <- as.character(data$row_id)

    entities <- tryCatch(
      {
        spacyr::spacy_extract_entity(text_raw)
      },
      error = function(e) {
        warning(paste("NER extraction failed. The exact error was:", e$message, call. = FALSE))
        return(NULL)
      }
    )

    if (!is.null(entities)) {
      valid_entities <- entities[entities$ent_type %in% ner_entity_types, ]
      if (nrow(valid_entities) == 0) {
        if (verbose) message("No entities found matching ner_entity_types. Returning empty.")
        return(dplyr::tibble())
      }

      ent_df <- data.frame(
        doc_id = valid_entities$doc_id,
        text = valid_entities$text,
        stringsAsFactors = FALSE
      )
      ent_collapsed <- stats::aggregate(text ~ doc_id, data = ent_df, FUN = paste, collapse = "  ")
      new_text_search <- rep("", length(text_search))
      idx <- match(ent_collapsed$doc_id, as.character(data$row_id))
      new_text_search[idx] <- ent_collapsed$text
      text_search <- new_text_search
      text_raw <- new_text_search
    } else {
      if (verbose) message("Skipping NER due to error.")
    }
  }

  if (unique_match) {
    # Stop searching after first match
    matches_found <- extract_matches_one_internal(
      text_search = text_search,
      text_raw = text_raw,
      row_ids = data$row_id,
      patterns = patterns,
      id_col_name = "row_id",
      verbose = verbose,
      cl = cl
    )
  } else {
    matches_found <- extract_matches_all_internal(
      text_search = text_search,
      text_raw = text_raw,
      row_ids = data$row_id,
      patterns = patterns,
      id_col_name = "row_id",
      verbose = verbose,
      cl = cl
    )
  }

  if (nrow(matches_found) == 0) {
    if (verbose) message("Number of rows with matches: 0")
    return(dplyr::tibble())
  }

  # After Match Entity Extraction
  if (use_ner && ner_timing == "after") {
    if (verbose) message("Validating matches using Named Entity Recognition (NER)...")

    unique_row_ids <- unique(matches_found$row_id)
    matched_texts <- text_raw[unique_row_ids]
    names(matched_texts) <- as.character(unique_row_ids)

    entities <- tryCatch(
      {
        spacyr::spacy_extract_entity(matched_texts)
      },
      error = function(e) {
        warning(paste("NER extraction failed. The exact error was:", e$message, call. = FALSE))
        return(NULL)
      }
    )

    if (!is.null(entities)) {
      valid_entities <- entities[entities$ent_type %in% ner_entity_types, ]

      if (nrow(valid_entities) == 0) {
        matches_found <- matches_found[0, ]
      } else {
        ent_list <- split(valid_entities$text, valid_entities$doc_id)
        valid_rows <- sapply(seq_len(nrow(matches_found)), function(i) {
          r_id <- as.character(matches_found$row_id[i])
          m_text <- trimws(tolower(matches_found$match[i]))
          doc_ents <- ent_list[[r_id]]

          if (is.null(doc_ents)) {
            return(FALSE)
          }
          any(grepl(m_text, tolower(doc_ents), fixed = TRUE))
        })

        matches_found <- matches_found[valid_rows, ]
      }
      if (verbose) message(sprintf("NER Validation complete. %d validated matches retained.", nrow(matches_found)))
    } else {
      if (verbose) message("Skipping NER validation and returning raw regex matches.")
    }

    if (nrow(matches_found) == 0) {
      if (verbose) message("Number of rows with matches after NER validation: 0")
      return(dplyr::tibble())
    }
  }

  # Join regex metadata
  if (!is.null(regex_return_cols)) {
    meta_data <- regex_table |>
      dplyr::select(dplyr::all_of(c(pattern_col, regex_return_cols))) |>
      dplyr::distinct()

    matches_found <- dplyr::left_join(
      matches_found,
      meta_data,
      by = c("pattern" = pattern_col)
    )
  }

  data_cols_to_join <- "row_id"
  if (!is.null(data_return_cols)) {
    data_cols_to_join <- c("row_id", data_return_cols[data_return_cols %in% names(data)])
  }

  result <- dplyr::left_join(
    matches_found,
    data[, data_cols_to_join, drop = FALSE],
    by = "row_id"
  )

  # Column selection and ordering
  if (!is.null(data_return_cols)) {
    valid_data_cols <- data_return_cols[data_return_cols %in% names(result)]
  } else {
    valid_data_cols <- character(0)
  }
  if (!is.null(regex_return_cols)) {
    valid_regex_cols <- regex_return_cols[regex_return_cols %in% names(result)]
  } else {
    valid_regex_cols <- character(0)
  }
  cols_to_keep <- c("row_id", valid_data_cols, valid_regex_cols, "pattern", "match")
  result <- result[, cols_to_keep, drop = FALSE]

  if (verbose) message("Number of rows with matches: ", nrow(result))

  dplyr::as_tibble(result)
}

#' @title Extract All matches per pattern
#' @description Internal function to extract all matches using dual-text approach.
#' @keywords internal
extract_matches_all_internal <- function(text_search,
                                         text_raw,
                                         row_ids,
                                         patterns,
                                         id_col_name,
                                         verbose = FALSE,
                                         cl = NULL) {
  if (verbose) {
    message(sprintf(
      "Scanning %d patterns against %d text entries...",
      length(patterns),
      length(text_search)
    ))
  }

  regex_opts <- stringi::stri_opts_regex(case_insensitive = TRUE)

  results_list <- pbapply::pblapply(patterns, function(pat) {
    has_match <- tryCatch(
      stringi::stri_detect_regex(text_search, pat, opts_regex = regex_opts),
      error = function(e) rep(FALSE, length(text_search))
    )

    if (!any(has_match)) {
      return(NULL)
    }

    indices <- which(has_match)

    # Extract first match from original (raw) text
    actual_text <- tryCatch(
      stringi::stri_extract_first_regex(
        text_raw[indices],
        pat,
        opts_regex = regex_opts
      ),
      error = function(e) rep(NA_character_, length(indices))
    )

    # Fallback: extract from cleaned text if raw extraction fails
    na_idx <- is.na(actual_text)
    if (any(na_idx)) {
      actual_text[na_idx] <- stringi::stri_extract_first_regex(
        text_search[indices][na_idx],
        pat,
        opts_regex = regex_opts
      )
    }

    list(
      row_id = row_ids[indices],
      pattern = rep.int(pat, length(indices)),
      match = actual_text
    )
  }, cl = cl)

  df <- dplyr::bind_rows(results_list)

  if (nrow(df) == 0) {
    return(dplyr::tibble())
  }

  names(df)[names(df) == "row_id"] <- id_col_name
  df <- df[order(df$row_id), ]
  df
}

#' @title Extract One match per row
#' @description Internal function to extract at most one match per row.
#' @keywords internal
extract_matches_one_internal <- function(text_search,
                                         text_raw,
                                         row_ids,
                                         patterns,
                                         id_col_name,
                                         verbose = FALSE,
                                         cl = NULL) {
  if (verbose) {
    message(sprintf(
      "Scanning: %d patterns against %d text entries...",
      length(patterns),
      length(text_search)
    ))
  }

  n_rows <- length(text_search)

  # Initialize storage for results
  matched_patterns <- rep(NA_character_, n_rows)
  exact_matches <- rep(NA_character_, n_rows)
  unmatched_indices <- seq_len(n_rows)

  regex_opts <- stringi::stri_opts_regex(case_insensitive = TRUE)

  # Set up progress bar
  if (verbose) {
    pb <- pbapply::startpb(min = 0, max = length(patterns))
    on.exit(pbapply::closepb(pb), add = TRUE)
  }

  # Process patterns in order with progress bar
  for (i in seq_along(patterns)) {
    pat <- patterns[i]

    if (verbose) {
      pbapply::setpb(pb, i)
    }

    if (length(unmatched_indices) == 0) break

    # Get text for unmatched rows
    current_text_search <- text_search[unmatched_indices]
    current_text_raw <- text_raw[unmatched_indices]

    # Check for matches
    has_match <- tryCatch(
      stringi::stri_detect_regex(current_text_search, pat, opts_regex = regex_opts),
      error = function(e) rep(FALSE, length(current_text_search))
    )

    if (any(has_match)) {
      match_idx_local <- which(has_match)
      match_idx_global <- unmatched_indices[match_idx_local]

      actual_text <- tryCatch(
        stringi::stri_extract_first_regex(
          current_text_raw[match_idx_local],
          pat,
          opts_regex = regex_opts
        ),
        error = function(e) rep(NA_character_, length(match_idx_local))
      )

      na_idx <- is.na(actual_text)
      if (any(na_idx)) {
        actual_text[na_idx] <- stringi::stri_extract_first_regex(
          current_text_search[match_idx_local][na_idx],
          pat,
          opts_regex = regex_opts
        )
      }

      matched_patterns[match_idx_global] <- pat
      exact_matches[match_idx_global] <- actual_text

      # Remove matched rows from further consideration
      unmatched_indices <- unmatched_indices[-match_idx_local]
    }
  }

  # Create result data frame
  result_indices <- which(!is.na(matched_patterns))

  if (length(result_indices) == 0) {
    return(dplyr::tibble())
  }

  df <- dplyr::tibble(
    row_id = row_ids[result_indices],
    pattern = matched_patterns[result_indices],
    match = exact_matches[result_indices]
  )

  names(df)[names(df) == "row_id"] <- id_col_name
  df <- df[order(df$row_id), ]

  df
}
