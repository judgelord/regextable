# Corporations Regextable

### Introduction

This vignette demonstrates how to extract mentions of corporations from
public datasets using a regular expression (regex) lookup table of
corporation names and their aliases. The approach parallels the core
[`regextable::extract()`](https://judgelord.github.io/regextable/reference/extract.md)
workflow but uses a specialized lookup table for corporations, including
aliases, tickers, and other metadata.

Install and load the package:

``` r
library(regextable)
library(kableExtra)
library(rvest)
library(purrr)
library(tibble)
library(stringr)
```

### Corporations Regex Table

The corporations_regex lookup table includes:

- `aliases`: alternative names or variants for a corporation
- `cik`: SEC Central Index Key
- `ticker`: stock ticker symbol, if applicable
- `sources`: reference for the alias (e.g., cik, sec)

``` r
corporations_regex <- read.csv("/Users/shirl/Downloads/corporations_crosswalk.csv", stringsAsFactors = FALSE)
kable(head(corporations_regex))
```

| aliases | cik | ticker | sources |
|:---|---:|:---|:---|
| DEFINED ASSET FUNDS MUNICIPAL INVT TR FD NEW YORK SER 33 | 3 |  | cik |
| CORPORATE INCOME FUND SEVENTY NINTH SHORT TERM SERIES | 13 |  | cik |
| DEFINED ASSET FUNDS MUNICIPAL INVT TR FD MON PYMT SER 155 | 14 |  | cik |
| DEFINED ASSET FUNDS MUNICIPAL INVT TR FD MON PYMT SER 156 | 17 |  | cik |
| NUVEEN TAX EXEMPT UNIT TRUST SERIES 169 NATIONAL TRUST 169 | 18 |  | cik |

### Data Corporations

The dataset `project_2025_coalition_and_contributors` contains
organizations and contributors involved in Project 2025. This dataset is
used alongside the corporations regex table to identify and standardize
corporation mentions.

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
[`regextable::extract()`](https://judgelord.github.io/regextable/reference/extract.md)
function matches organization names in the dataset against the
corporation regex table. This process standardizes names and removes
common acronym matches to reduce false positives.

``` r
corp_df <- extract(data = project_2025_coalition_and_contributors,
                   col_name = "organization",
                   regex_table = corporations_regex,
                   pattern_col = "aliases",
                   data_return_cols = "organization",
                   remove_acronyms = TRUE)

kable(head(corp_df))
```

| row_id | organization | pattern | match |
|---:|:---|:---|:---|
| 1 | Alabama Policy Institute | M&#124;C ACQUISITION CORP.&#124;F & M Bank-Pulaski | m |
| 1 | Alabama Policy Institute | I O MAGIC CORP/CA&#124;I O MAGIC CORP&#124;I OMAGIC CORP/CA&#124;I/OMAGIC CORP&#124;I/O MAGIC CORP&#124;I | i |
| 1 | Alabama Policy Institute | T/R SYSTEMS INC&#124;T | t |
| 1 | Alabama Policy Institute | E&#124;CLASS MB PARTNERS FUND I, LLC&#124;MARKEL-EAGLE PARTNERS FUND I, LLC | e |
| 1 | Alabama Policy Institute | M/A-COM TECHNOLOGY SOLUTIONS HOLDINGS, INC.&#124;MACOM TECHNOLOGY SOLUTIONS HOLDINGS, INC.&#124;M/ACOM TECHNOLOGY SOLUTIONS&#124;M | m |
