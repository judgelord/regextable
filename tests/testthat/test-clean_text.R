library(testthat)
library(regextable)

test_that("clean_text works as expected", {
  
  # Input examples
  raw_text <- c(
    "  Hello,   World!  ",
    "R&D + Analysis — Test",
    "Multiple\nlines.and.periods..."
  )
  
  cleaned <- clean_text(raw_text)
  
  # Expected outputs
  expect_equal(cleaned[1], "hello, world")
  expect_equal(cleaned[2], "r&d analysis test")
  expect_equal(cleaned[3], "multiple lines and periods")
  
})
