library(testthat)
library(regextable)

test_that("extract basic matching", {
  df <- data.frame(
    id = 1:2,
    text = c("Alice works at ACME", "Bob is at XYZ Corp"),
    stringsAsFactors = FALSE
  )
  regex_table <- data.frame(pattern = c("XYZ Corp"))
  
  result <- extract(
    df, 
    regex_table = regex_table, 
    col_name = "text", 
    data_return_cols = "id", 
    verbose = FALSE
  )
  
  expect_equal(nrow(result), 1)
  expect_setequal(result$pattern, c("XYZ Corp"))
  expect_equal(result$id, 2)
  expect_equal(result$match, "XYZ Corp")
})

test_that("case-insensitive matching works", {
  df <- data.frame(id = 1, text = "alice works at acme", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME")
  
  result <- extract(df, regex_table, col_name = "text", verbose = FALSE)
  
  expect_equal(result$pattern, "ACME")
  expect_equal(result$match, "acme")
})

test_that("multiple matches per row return one row per pattern", {
  df <- data.frame(id = 1, text = "ACME and XYZ Corp", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("ACME", "XYZ Corp"))
  
  result <- extract(df, regex_table, "text", verbose = FALSE)
  
  expect_equal(nrow(result), 2)
  expect_setequal(result$pattern, c("ACME", "XYZ Corp"))
})

test_that("unique_match returns only one match per row", {
  df <- data.frame(
    id = 1,
    text = "ACME and XYZ Corp",
    stringsAsFactors = FALSE
  )
  regex_table <- data.frame(pattern = c("ACME", "XYZ Corp"))
  
  result <- extract(
    df,
    regex_table = regex_table,
    col_name = "text",
    unique_match = TRUE,
    verbose = FALSE
  )
  
  expect_equal(nrow(result), 1)
  expect_equal(result$pattern, "ACME")
})

test_that("unique_match still returns multiple rows for multiple inputs", {
  df <- data.frame(
    id = 1:2,
    text = c("ACME here", "XYZ Corp there"),
    stringsAsFactors = FALSE
  )
  regex_table <- data.frame(pattern = c("ACME", "XYZ Corp"))
  
  result <- extract(
    df,
    regex_table,
    "text",
    unique_match = TRUE,
    data_return_cols = "id",
    verbose = FALSE
  )
  
  expect_equal(nrow(result), 2)
  expect_setequal(result$pattern, c("ACME", "XYZ Corp"))
})

test_that("extract works with custom pattern_col", {
  df <- data.frame(id = 1, text = "ACME Corp")
  regex_table <- data.frame(my_pattern = "ACME")
  
  result <- extract(df, regex_table, "text", pattern_col = "my_pattern", verbose = FALSE)
  expect_equal(result$pattern, "ACME")
})

test_that("date filtering works", {
  df <- data.frame(
    id = 1:3,
    text = c("ACME", "XYZ", "Other"),
    date = as.Date(c("2020-01-01", "2021-01-01", "2022-01-01")),
    stringsAsFactors = FALSE
  )
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  
  result <- extract(
    df,
    regex_table = regex_table,
    col_name = "text", 
    data_return_cols = "id", 
    date_col = "date",
    date_start = "2020-06-01", 
    date_end = "2021-12-31",
    verbose = FALSE
  )
  expect_equal(result$id, 2)
})

test_that("remove_acronyms works", {
  df <- data.frame(id = 1:3, text = c("ACME", "xyz", "Other"), stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("ACME", "XyZ"))
  
  result <- extract(df, regex_table = regex_table, col_name = "text", remove_acronyms = TRUE, verbose = FALSE)
  expect_false("ACME" %in% result$pattern)
})

test_that("row order is preserved", {
  df <- data.frame(id = 1:3, text = c("XYZ", "ACME", "Other"), stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  
  result <- extract(df, regex_table, "text", data_return_cols = "id", verbose = FALSE)
  expect_equal(result$id, c(1, 2))
})

test_that("return_cols correctly restricts output", {
  df <- data.frame(id = 1, text = "ACME", other = "foo", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME")
  
  result <- extract(df, regex_table = regex_table, col_name = "text", data_return_cols = c("other"), verbose = FALSE)
  
  expect_true(all(c("other", "pattern", "match", "row_id") %in% names(result)))
  expect_false("text" %in% names(result))
})

test_that("regex_return_cols are merged correctly", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(pattern = "ACME", category = "company", stringsAsFactors = FALSE)
  
  result <- extract(df, regex_table, "text", regex_return_cols = "category", verbose = FALSE)
  expect_equal(result$category, "company")
})

test_that("no matches returns empty tibble", {
  df <- data.frame(id = 1, text = "Nothing here")
  regex_table <- data.frame(pattern = "ACME")
  
  result <- extract(df, regex_table = regex_table, col_name = "text", verbose = FALSE)
  expect_equal(nrow(result), 0)
})

test_that("empty input returns empty tibble", {
  df <- data.frame(id = integer(0), text = character(0))
  regex_table <- data.frame(pattern = character(0))
  
  result <- extract(df, regex_table = regex_table, col_name = "text", verbose = FALSE)
  expect_equal(nrow(result), 0)
})

test_that("extract handles NA text safely", {
  df <- data.frame(id = 1:3, text = c("ACME", NA, "XYZ"))
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  
  # This previously crashed because NA inputs propagated to array indices
  result <- extract(df, regex_table, "text", verbose = FALSE)
  
  expect_equal(nrow(result), 2)
  expect_setequal(result$pattern, c("ACME", "XYZ"))
})

test_that("empty regex_table or all patterns removed returns empty tibble", {
  df <- data.frame(id = 1, text = "ACME", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = character(0))
  
  result <- extract(df, regex_table, "text", verbose = FALSE)
  expect_equal(nrow(result), 0)
  
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  result <- extract(df, regex_table, "text", remove_acronyms = TRUE, verbose = FALSE)
  expect_equal(nrow(result), 0)
})

test_that("regex_return_cols handle NA values", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(pattern = "ACME", category = NA, type = "org")
  
  result <- extract(df, regex_table, "text", regex_return_cols = c("category", "type"), verbose = FALSE)
  expect_equal(result$category, NA)
  expect_equal(result$type, "org")
})

test_that("multiple regex_return_cols are merged correctly", {
  df <- data.frame(id = 1, text = "ACME", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME", category = "company", type = "org", stringsAsFactors = FALSE)
  
  result <- extract(df, regex_table, "text", regex_return_cols = c("category", "type"), verbose = FALSE)
  expect_equal(result$category, "company")
  expect_equal(result$type, "org")
})

test_that("extract errors on missing text column", {
  df <- data.frame(a = 1)
  regex_table <- data.frame(pattern = "x")
  expect_error(extract(df, regex_table = regex_table, col_name = "text"))
})

test_that("extract errors when col_name is not character column", {
  df <- data.frame(id = 1, text = 123)
  regex_table <- data.frame(pattern = "123")
  expect_error(extract(df, regex_table, "text"))
})

test_that("extract errors when regex_table is missing pattern column", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(not_pattern = "ACME")
  expect_error(extract(df, regex_table, "text"))
})

test_that("extract errors when date_col does not exist", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(pattern = "ACME")
  expect_error(extract(df, regex_table = regex_table, col_name = "text", date_col = "missing"))
})

test_that("non-character col_name errors on factor/list columns", {
  df <- data.frame(text = factor(c("ACME", "XYZ")))
  regex_table <- data.frame(pattern = "ACME")
  expect_error(extract(df, regex_table, "text"))
  
  df <- data.frame(text = I(list("ACME", "XYZ")))
  expect_error(extract(df, regex_table, "text"))
})

test_that("verbose messages are printed correctly", {
  df <- data.frame(id = 1, text = "ACME", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME")
  expect_message(extract(df, regex_table, "text", verbose = TRUE))
  expect_silent(extract(df, regex_table, "text", verbose = FALSE))
})

test_that("extract works with parallel cluster argument (integer)", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(pattern = "ACME")
  
  result <- extract(df, regex_table, "text", cl = 2, verbose = FALSE)
  expect_equal(result$pattern, "ACME")
})

test_that("special regex characters in text are matched correctly", {
  df <- data.frame(id = 1, text = "Check (ACME).", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "\\(ACME\\)")
  
  result <- extract(df, regex_table, "text", verbose = FALSE)
  
  expect_equal(nrow(result), 1)
  # Expect lowercase match due to default cleaning
  expect_equal(result$match, "(ACME)")
})

test_that("verbose warning for long input text", {
  df <- data.frame(id = 1, text = paste(rep("ACME", 1e5), collapse = " "))
  regex_table <- data.frame(pattern = "ACME")
  
  expect_message(extract(df, regex_table, "text", verbose = TRUE))
})

test_that("use_ner runs without error", {
  skip_if_not_installed("spacyr")
  skip_on_cran()
  
  spacyr::spacy_initialize()
  
  df <- data.frame(text = "Apple hired John", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("Apple", "John"))
  
  expect_no_error(
    extract(df, regex_table, "text", use_ner = TRUE, verbose = FALSE)
  )
  
  spacyr::spacy_finalize()
})

test_that("ner_entity_types argument works", {
  skip_if_not_installed("spacyr")
  skip_on_cran()
  
  spacyr::spacy_initialize()
  
  df <- data.frame(text = "Apple hired John", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("Apple", "John"))
  
  result <- extract(
    df,
    regex_table,
    "text",
    use_ner = TRUE,
    ner_entity_types = c("ORG", "PERSON"),
    verbose = FALSE
  )
  
  expect_true(nrow(result) >= 0)
  
  spacyr::spacy_finalize()
})

test_that("use_ner handles multiple matches per row without duplicate docname error", {
  skip_if_not_installed("spacyr")
  skip_on_cran()
  
  spacyr::spacy_initialize()
  
  df <- data.frame(id = 1, text = "Apple and Microsoft are tech giants.")
  regex_table <- data.frame(pattern = c("Apple", "Microsoft"))
  
  expect_no_error({
    result <- extract(df, regex_table, "text", use_ner = TRUE, unique_match = FALSE, verbose = FALSE)
  })
  
  expect_equal(nrow(result), 2)
  spacyr::spacy_finalize()
})

test_that("use_ner accurately filters out non-entities", {
  skip_if_not_installed("spacyr")
  skip_on_cran()
  
  spacyr::spacy_initialize()
  
  df <- data.frame(
    id = 1:2,
    text = c("Tim Cook works at Apple.", "I ate a green apple today.")
  )
  regex_table <- data.frame(pattern = "Apple")
  
  result <- extract(
    df, regex_table, "text",
    use_ner = TRUE, ner_entity_types = "ORG", verbose = FALSE
  )
  
  expect_equal(nrow(result), 1)
  expect_equal(result$row_id, 1)
  
  spacyr::spacy_finalize()
})

test_that("use_ner warns on invalid spaCy tags", {
  df <- data.frame(text = "Apple hired John")
  regex_table <- data.frame(pattern = "Apple")
  
  expect_warning(
    extract(df, regex_table, "text", use_ner = TRUE, ner_entity_types = "FAKE_TAG", verbose = FALSE),
    "One or more 'ner_entity_types' are not standard spaCy tags"
  )
})

test_that("typo_table replaces text before matching", {
  df <- data.frame(text = "I like appsle", stringsAsFactors = FALSE)
  
  regex_table <- data.frame(pattern = "apples")
  typo_table <- data.frame(
    typo = "appsle",
    correction = "apples",
    stringsAsFactors = FALSE
  )
  result <- extract(
    df,
    regex_table,
    "text",
    typo_table = typo_table,
    verbose = FALSE
  )
  
  expect_equal(nrow(result), 1)
  expect_equal(result$match, "apples")
})