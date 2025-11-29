library(testthat)
library(regextable)  # your package

test_that("extract returns correct matches", {
  
  # Example input
  df <- data.frame(
    id = 1:2,
    text = c("Alice works at ACME", "Bob is at XYZ Corp"),
    stringsAsFactors = FALSE
  )
  
  regex_table <- data.frame(
    pattern = c("ACME", "XYZ Corp"),
    stringsAsFactors = FALSE
  )
  
  result <- extract(df, col_name = "text", regex_table = regex_table)
  
  # Check number of rows
  expect_equal(nrow(result), 2)
  
  # Check the patterns returned
  expect_true(all(result$pattern %in% c("ACME", "XYZ Corp")))
  
  # Check ids match
  expect_equal(result$id, 1:2)
})