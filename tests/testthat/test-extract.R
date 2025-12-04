library(testthat)
library(regextable)

test_that("extract basic matching works", {
  df <- data.frame(
    id   = 1:2,
    text = c("Alice works at ACME", "Bob is at XYZ Corp"),
    stringsAsFactors = FALSE
  )
  regex_table <- data.frame(pattern = c("XYZ Corp"))
  
  result <- extract(df, col_name = "text", regex_table = regex_table, verbose = FALSE)
  
  expect_equal(nrow(result), 1)
  expect_setequal(result$pattern, c("XYZ Corp"))
  expect_equal(result$id, 2)
  # Expect lowercase because clean_text runs by default
  expect_equal(result$match, "xyz corp")
})

test_that("case-insensitive matching works", {
  df <- data.frame(id = 1, text = "alice works at acme", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME")
  result <- extract(df, col_name = "text", regex_table = regex_table, verbose = FALSE)
  
  expect_equal(result$pattern, "ACME")
  expect_equal(result$match, "acme")
})

test_that("date filtering works", {
  df <- data.frame(
    id   = 1:3,
    text = c("ACME", "XYZ", "Other"),
    date = as.Date(c("2020-01-01", "2021-01-01", "2022-01-01")),
    stringsAsFactors = FALSE
  )
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  result <- extract(
    df, col_name  = "text", regex_table = regex_table,
    date_col  = "date", date_start = "2020-06-01", date_end   = "2021-12-31",
    verbose = FALSE
  )
  expect_equal(result$id, 2)
})

test_that("remove_acronyms works", {
  df <- data.frame(id = 1:3, text = c("ACME", "xyz", "Other"), stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("ACME", "XyZ"))
  result <- extract(df, col_name = "text", regex_table = regex_table, remove_acronyms = TRUE, verbose = FALSE)
  expect_false("ACME" %in% result$pattern)
})

test_that("return_cols correctly restricts output", {
  df <- data.frame(id = 1, text = "ACME", other = "foo", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME")
  result <- extract(df, col_name = "text", regex_table = regex_table, return_cols = c("other"), verbose = FALSE)
  
  expect_true(all(c("other", "pattern", "match", "row_id") %in% names(result)))
  expect_false("text" %in% names(result))
})

test_that("no matches returns empty tibble", {
  df <- data.frame(id = 1, text = "Nothing here")
  regex_table <- data.frame(pattern = "ACME")
  result <- extract(df, col_name = "text", regex_table = regex_table, verbose = FALSE)
  expect_equal(nrow(result), 0)
})

test_that("empty input returns empty tibble", {
  df <- data.frame(id = integer(0), text = character(0))
  regex_table <- data.frame(pattern = character(0))
  result <- extract(df, col_name = "text", regex_table = regex_table, verbose = FALSE)
  expect_equal(nrow(result), 0)
})

test_that("extract errors on missing text column", {
  df <- data.frame(a = 1)
  regex_table <- data.frame(pattern = "x")
  expect_error(extract(df, col_name = "text", regex_table = regex_table))
})

test_that("extract errors when col_name is not character column", {
  df <- data.frame(id = 1, text = 123)
  regex_table <- data.frame(pattern = "123")
  expect_error(extract(df, "text", regex_table))
})

test_that("extract errors when regex_table is missing pattern column", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(not_pattern = "ACME")
  expect_error(extract(df, "text", regex_table))
})

test_that("regex_return_cols are merged correctly", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(pattern = "ACME", category = "company", stringsAsFactors = FALSE)
  result <- extract(df, "text", regex_table, regex_return_cols = "category", verbose = FALSE)
  expect_equal(result$category, "company")
})

test_that("extract errors when date_col does not exist", {
  df <- data.frame(id = 1, text = "ACME")
  regex_table <- data.frame(pattern = "ACME")
  expect_error(extract(df, col_name = "text", regex_table = regex_table, date_col = "missing"))
})

test_that("extract handles NA text safely", {
  df <- data.frame(id = 1:3, text = c("ACME", NA, "XYZ"))
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  
  # This previously crashed because NA inputs propagated to array indices
  result <- extract(df, "text", regex_table, verbose = FALSE)
  
  expect_equal(nrow(result), 2)
  expect_setequal(result$pattern, c("ACME", "XYZ"))
})

test_that("multiple matches per row only returns first match (Shrinking Pool)", {
  df <- data.frame(id = 1, text = "ACME and XYZ Corp", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("ACME", "XYZ Corp"))
  
  result <- extract(df, "text", regex_table, verbose = FALSE)
  expect_equal(nrow(result), 1)
  expect_equal(result$pattern, "ACME") 
})

test_that("special regex characters in text are matched correctly", {
  df <- data.frame(id = 1, text = "Check (ACME).", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "\\(ACME\\)")
  
  result <- extract(df, "text", regex_table, verbose = FALSE)
  
  expect_equal(nrow(result), 1)
  # Expect lowercase match due to default cleaning
  expect_equal(result$match, "(acme)")
})

test_that("multiple regex_return_cols are merged correctly", {
  df <- data.frame(id = 1, text = "ACME", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME", category = "company", type = "org", stringsAsFactors = FALSE)
  result <- extract(df, "text", regex_table, regex_return_cols = c("category","type"), verbose = FALSE)
  expect_equal(result$category, "company")
  expect_equal(result$type, "org")
})

test_that("empty regex_table or all patterns removed returns empty tibble", {
  df <- data.frame(id = 1, text = "ACME", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = character(0))
  result <- extract(df, "text", regex_table, verbose = FALSE)
  expect_equal(nrow(result), 0)
  
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  result <- extract(df, "text", regex_table, remove_acronyms = TRUE, verbose = FALSE)
  expect_equal(nrow(result), 0)
})

test_that("row order is preserved", {
  df <- data.frame(id = 1:3, text = c("XYZ", "ACME", "Other"), stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = c("ACME", "XYZ"))
  result <- extract(df, "text", regex_table, verbose = FALSE)
  expect_equal(result$id, c(1,2))
})

test_that("verbose messages are printed correctly", {
  df <- data.frame(id = 1, text = "ACME", stringsAsFactors = FALSE)
  regex_table <- data.frame(pattern = "ACME")
  expect_message(extract(df, "text", regex_table, verbose = TRUE))
  expect_silent(extract(df, "text", regex_table, verbose = FALSE))
})

test_that("non-character col_name errors on factor/list columns", {
  df <- data.frame(text = factor(c("ACME","XYZ")))
  regex_table <- data.frame(pattern = "ACME")
  expect_error(extract(df, "text", regex_table))
  
  df <- data.frame(text = I(list("ACME","XYZ")))
  expect_error(extract(df, "text", regex_table))
})