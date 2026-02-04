## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  cache = FALSE,
  warning = FALSE,
  message = FALSE,
  tidy = FALSE,
  fig.align = 'center',
  fig.path = "man/figures/vignette-",
  R.options = list(width = 120)
)

# Format kable tables
kable <- function(x){
  if (knitr::is_latex_output()) {
    head(x, 5) |>
      knitr::kable(booktabs = TRUE, format = 'latex') |>
      kableExtra::kable_styling(latex_options = c("striped", "scale_down", "HOLD_position"))
  } else {
    head(x, 5) |>
      knitr::kable(escape = TRUE) |>
      kableExtra::kable_styling()
  }
}


## ----message=FALSE------------------------------------------------------------
library(regextable)
library(kableExtra)


## -----------------------------------------------------------------------------
data("members")
kable(members)

data("cr2007_03_01")
kable(cr2007_03_01)


## -----------------------------------------------------------------------------
text <- "  HELLO---WORLD  "
clean_text(text)


## -----------------------------------------------------------------------------
result <- regextable::extract(
  data = cr2007_03_01,
  regex_table = members,
  data_return_cols = c("text"),
  regex_return_cols = c("icpsr")
)

kable(head(result))


## ----eval = FALSE, include= FALSE---------------------------------------------
# result_advanced <- extract(
#   data = cr2007_03_01,
#   regex_table = members,
#   date_col = "date",
#   date_start = "2007-01-01",
#   date_end = "2007-12-31",
#   remove_acronyms = TRUE,
#   data_return_cols = c("text"),
#   regex_return_cols = c("icpsr")
# )
# 
# kable(head(result_advanced))


## ----eval=FALSE---------------------------------------------------------------
# library(parallel)
# clust <- makeCluster(2)
# result_parallel <- regextable::extract(
#   data = cr2007_03_01,
#   regex_table = members,
#   cl = clust,
#   data_return_cols = c("text"),
#   regex_return_cols = c("icpsr")
# )
# stopCluster(clust)
# head(result_parallel)

