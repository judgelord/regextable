# Corporations Regextable

### Introduction

This vignette demonstrates how to extract mentions of corporations using
a regex lookup table of corporation names, aliases, tickers, and other
metadata. The
[`regextable::extract()`](https://judgelord.github.io/regextable/reference/extract.md)
workflow allows consistent identification of corporation names across
datasets, even when multiple aliases or variants are used.

Install and load the package:

``` r
library(regextable)
library(kableExtra)
library(rvest)
library(pbapply)
library(purrr)
library(tibble)
library(stringr)
```

### Regex Table of Corporations

The corporations_regex table contains corporations, their common
aliases, ticker symbols, and reference sources used for matching and
standardization. The aliases column includes alternative names,
abbreviations, or common variants for each corporation to ensure
comprehensive matching.

``` r
corporations_regex <- read.csv("/Users/shirl/Downloads/corporations_crosswalk.csv", stringsAsFactors = FALSE)

# Clean aliases and create pattern

corporations_regex$aliases <- tolower(corporations_regex$aliases)
suffixes <- c(
  "\\binc\\b", "\\bcorp\\b", "\\bcorporation\\b",
  "\\bllc\\b", "\\blp\\b", "\\bltd\\b", "\\bincorporated\\b"
)
suffix_pattern <- paste0("(?:", paste(suffixes, collapse = "|"), ")")
corporations_regex$aliases <- gsub(
  paste0("[,.]?\\s*", suffix_pattern, "[.]?"),
  "",
  corporations_regex$aliases,
  perl = TRUE
)
corporations_regex$aliases <- gsub("[[:punct:]]+$", "", corporations_regex$aliases)
corporations_regex$aliases <- gsub("\\s+", " ", corporations_regex$aliases)
corporations_regex$aliases <- trimws(corporations_regex$aliases)
pbapply::pboptions(type = "none")
corporations_regex$pattern <- pbapply::pbsapply(corporations_regex$aliases, function(x){
  parts <- unlist(strsplit(x, "\\|"))
  parts <- trimws(parts)
  parts <- parts[nchar(parts) > 1]
  parts <- unique(parts)
  parts <- parts[order(nchar(parts), decreasing = TRUE)]
  paste(parts, collapse="|")
})
corporations_regex <- corporations_regex[nchar(corporations_regex$pattern) > 1, ]
corporations_regex$pattern <- paste0("\\b(?:", corporations_regex$pattern, ")\\b")

kable(head(corporations_regex))
```

| aliases | cik | FED_RSSD | ticker | naics | sources | pattern |
|:---|---:|---:|:---|---:|:---|:---|
| defined asset funds municipal invt tr fd new york ser 33 | 3 | NA |  | NA | cik | \b(?:defined asset funds municipal invt tr fd new york ser 33)\b |
| corporate income fund seventy ninth short term series | 13 | NA |  | NA | cik | \b(?:corporate income fund seventy ninth short term series)\b |
| defined asset funds municipal invt tr fd mon pymt ser 155 | 14 | NA |  | NA | cik | \b(?:defined asset funds municipal invt tr fd mon pymt ser 155)\b |
| defined asset funds municipal invt tr fd mon pymt ser 156 | 17 | NA |  | NA | cik | \b(?:defined asset funds municipal invt tr fd mon pymt ser 156)\b |
| nuveen tax exempt unit trust series 169 national trust 169 | 18 | NA |  | NA | cik | \b(?:nuveen tax exempt unit trust series 169 national trust 169)\b |

### Data Corporations

The following dataset contains organizations and contributors involved
in Project 2025. It is used to demonstrate matching and standardizing
corporation names using the regex table.

``` r
project_2025_url <- "https://raw.githubusercontent.com/judgelord/corporations/main/data/project_2025_coalition_and_contributors.rda"
tmp <- tempfile(fileext = ".rda")
download.file(project_2025_url, tmp, mode = "wb")
load(tmp)
kable(head(project_2025_coalition_and_contributors))
```

| type | organization | individual | role |
|:---|:---|:---|:---|
| Organization | Alabama Policy Institute |  | Advisory Board Member |
| Organization | Alliance Defending Freedom |  | Advisory Board Member |
| Organization | American Accountability Foundation |  | Advisory Board Member |
| Organization | American Center for Law and Justice |  | Advisory Board Member |
| Organization | American Compass |  | Advisory Board Member |

### Extracting Aliases from Corporation Crosswalk

The
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
function searches the `organization` column of the dataset using the
`aliases` patterns in the regex table. It returns the standardized
corporation names while optionally removing acronym-only matches to
reduce false positives.

``` r
corp_df <- extract(data = project_2025_coalition_and_contributors,
                   col_name = "organization",
                   regex_table = corporations_regex,
                   data_return_cols = "organization",
                   remove_acronyms = TRUE)

kable(head(corp_df))
```

| row_id | organization | pattern | match |
|---:|:---|:---|:---|
| 2 | Alliance Defending Freedom | \b(?:alliance)\b | Alliance |
| 3 | American Accountability Foundation | \b(?:american)\b | American |
| 4 | American Center for Law and Justice | \b(?:american)\b | American |
| 5 | American Compass | \b(?:american)\b | American |
| 5 | American Compass | \b(?:urban compass&#124;compass)\b | Compass |
