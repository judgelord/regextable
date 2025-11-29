library(testthat)
library(regextable)

test_that("clean_text works as expected", {
  
  # Input examples
  raw_text <- c(
    "  Hello,   World!  ",
    "R&D + Analysis — Test",
    "Multiple\nlines.and.periods...",
    "already clean",
    "",
    "Multiple!!!! consecutive???? punctuation,,,,,, ",
    "Hello\nWorld  ",
    "hyphen- and Em—dash"
  )
  
  cleaned <- clean_text(raw_text)
  
  # Expected outputs
  expect_equal(cleaned[1], "hello, world")
  expect_equal(cleaned[2], "r&d analysis test")
  expect_equal(cleaned[3], "multiple lines and periods")
  expect_equal(cleaned[4], "already clean")
  expect_equal(cleaned[5], "")
  expect_equal(cleaned[6], "multiple consecutive punctuation,")
  expect_equal(cleaned[7], "hello world")
  expect_equal(cleaned[8], "hyphen and emdash")
  
})
