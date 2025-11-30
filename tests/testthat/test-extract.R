library(testthat)
library(regextable)

test_that("extract basic matching works", {
  
  df <- data.frame(
    id   = 1:2,
    text = c("Alice works at ACME", "Bob is at XYZ Corp"),
    stringsAsFactors = FALSE
  )
  
  regex_table <- data.frame(pattern = c("ACME", "XYZ Corp"))
  
  result <- extract(df, col_name = "text", regex_table = regex_table, verbose = FALSE)
  
  expect_equal(nrow(result), 2)
  expect_setequal(result$pattern, c("ACME", "XYZ Corp"))
  expect_setequal(result$id, 1:2)
})


test_that("case-insensitive matching works", {
  
  df <- data.frame(
    id   = 1,
    text = "alice works at acme",
    stringsAsFactors = FALSE
  )
  
  regex_table <- data.frame(pattern = "ACME")
  
  result <- extract(df, col_name = "text", regex_table = regex_table, verbose = FALSE)
  
  expect_equal(result$pattern, "ACME")
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
    df,
    col_name  = "text",
    regex_table = regex_table,
    date_col  = "date",
    date_start = "2020-06-01",
    date_end   = "2021-12-31",
    verbose = FALSE
  )
  
  expect_equal(result$id, 2)
})


test_that("remove_acronyms works", {
  
  df <- data.frame(
    id   = 1:3,
    text = c("ACME", "xyz", "Other"),
    stringsAsFactors = FALSE
  )
  
  regex_table <- data.frame(pattern = c("ACME", "XyZ"))
  
  result <- extract(df,
                    col_name   = "text",
                    regex_table = regex_table,
                    remove_acronyms = TRUE,
                    verbose = FALSE)
  
  expect_false("ACME" %in% result$pattern)
})


test_that("return_cols correctly restricts output", {
  
  df <- data.frame(
    id    = 1,
    text  = "ACME",
    other = "foo",
    stringsAsFactors = FALSE
  )
  
  regex_table <- data.frame(pattern = "ACME")
  
  result <- extract(
    df,
    col_name     = "text",
    regex_table  = regex_table,
    return_cols  = c("other"),
    verbose = FALSE
  )
  
  # Extract builds: only requested return cols + pattern
  expect_equal(names(result), c("other", "pattern"))
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
