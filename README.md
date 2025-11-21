<!-- README.md is generated from README.Rmd. Please edit that file -->

## regextable: Apply pattern-based text extraction and cleaning <img src="man/figures/logo.png" align="right" width="150"/>

### Installation

```r
devtools::install_github("judgelord/regextable")
library(regextable)
```

## extract()

### Description
Uses a regex lookup to extract pattern matches from a data frame or character vector. Returns a data frame containing the original columns plus a matched_pattern column for each detected pattern.

### Data
```r
data("cr2007_03_01")
data("members")
```

### Required Parameters
- **data**: A data frame or character vector containing the text to search.
- **col_name**: Column name in the data frame containing text to search through.
- **regex_table**: A regex lookup table with at least one pattern column.

### Optional Parameters
- **pattern_col**: (default "pattern") Name of the regex pattern column in regex_table.
- **return_cols**: (default NULL) Vector of columns to include in the output.
- **id_col**: (default NULL) Column in data used for filtering rows before matching.
- **id_filter**: (default NULL) Value(s) of IDs to restrict which rows are matched.
- **date_col**: (default NULL) Column in data containing dates for filtering.
- **date_start**: (default NULL) Start date for filtering rows.
- **date_end**: (default NULL) End date for filtering rows.
- **typo_table**: (default NULL) Table of typos to correct in data. (planned for future versions)
- **remove_acronyms**: (default FALSE) If TRUE, removes all-uppercase patterns from regex_table.
- **clean_text**: (default TRUE) If TRUE, applies basic text cleaning before matching.
- **do_clean_text**: (default TRUE) Clean text before matching.
- **verbose**: (default TRUE) If TRUE, displays progress messages.

### Returns
A data frame with one row per match, including specified or all original columns from 'data' plus a matched_pattern column.

### Overview
The `extract()` function searches a data frame or character vector for text patterns defined in a regex table.  
By default, it performs strict, whole-word matching and returns all columns from the input data for rows that match any pattern.  
Users can optionally specify which columns to return and which pattern column in the regex table to use.  
Additional optional arguments include ID filtering, start and end dates, typo correction, and text cleaning.  
This makes `extract()` flexible for extracting specific patterns while keeping the full dataset structure intact.


### Basic Example
```r
# Extract using default pattern column
result <- extract(
  data = cr2007_03_01.rda,
  col_name = "header",
  regex_table = members
)

head(result)
```
###Advanced Example
```r
result_advanced <- extract(
  data = cr,
  col_name = "text",
  regex_table = my_patterns,
  id_col = "id",
  id_filter = c(101, 102),
  date_col = "date",
  date_start = "2023-01-01",
  date_end = "2023-06-30",
  remove_acronyms = TRUE,
  return_cols = c("id", "text")
)

head(result_advanced)
```
               
### Future Development
- Add support for `typo_table` to correct known text errors before matching.
- Improve strict matching rules for patterns that may need more inclusive or more restrictive word boundaries.  
- Enable user-defined ID systems (e.g., corporations, campaigns) and control whether text is returned with matches. 
