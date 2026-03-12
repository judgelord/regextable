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

The corporations_regex table contains a sample of corporations, their
common aliases, ticker symbols, and reference sources used for matching
and standardization. The aliases column includes alternative names,
abbreviations, or common variants for each corporation to ensure
comprehensive matching.

``` r
corporations_regex <- read.csv("/Users/shirl/Downloads/corporations_regex.csv", stringsAsFactors = FALSE)
kable(head(corporations_regex))
```

| aliases | cik | FED_RSSD | ticker | naics | sources | pattern |
|:---|---:|:---|:---|---:|:---|:---|
| booz allen & hamilton&#124;booz allen hamilton&#124;booz allen hamilton | 13222 | NA |  | NA | cik | \b(?:booz allen & hamilton&#124;booz allen hamilton)\b |
| taft stettinius & hollister | 909789 | NA |  | NA | cik | \b(?:taft stettinius & hollister)\b |
| case&#124;case | 922321 | NA |  | NA | cik | \b(?:case)\b |
| young america | 1058951 | NA |  | NA | cik | \b(?:young america)\b |
| alliance | 1086796 | NA |  | NA | cik | \b(?:alliance)\b |

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
                   remove_acronyms = TRUE,
                   use_ner = TRUE)

kable(head(corp_df))
```

| row_id | organization | pattern | match |
|---:|:---|:---|:---|
| 3 | American Accountability Foundation | \b(?:american)\b | American |
| 4 | American Center for Law and Justice | \b(?:american)\b | American |
| 5 | American Compass | \b(?:american)\b | American |
| 5 | American Compass | \b(?:urban compass&#124;compass)\b | Compass |
| 7 | American Cornerstone Institute | \b(?:american)\b | American |
