
<!-- README.md is generated from README.Rmd. Please edit that file -->

<<<<<<< HEAD
## regextable: Apply pattern-based text extraction and cleaning <img src="man/figures/logo.png" align="right" width="150"/>
=======
## regextable: Apply pattern-based text cleaning and lookup
>>>>>>> 36f69c08618aaf3de40be67c81ba90b5acf97547

### Installation

```r
devtools::install_github("judgelord/regextable")
library(regextable)

## extract()

### Description
Uses a regex lookup to extract pattern matches from a data frame or character vector.

### Parameters
- **data**: A data frame or character vector containing the text to search.
- **col_name**: Column name in the data frame containing text to search through.
- **regex_table**: A regex lookup table with at least one pattern column.
- **pattern_col**: Name of the regex pattern column in `regex_table` (default `"pattern"`).
- **id_col**: Optional column in `data` used to filter rows before matching.
- **id_filter**: Optional value or vector of IDs to restrict which rows of `data` are matched.
- **date_col**: Optional column in `data` for date filtering.
- **date_start**: Optional start date for filtering `data`.
- **date_end**: Optional end date for filtering `data`.
- **typo_table**: Optional table to fix typos in `data`.
- **strict**: Logical; if TRUE, matches are treated as whole-word; if FALSE, partial matches allowed.
- **remove_acronyms**: Logical; if TRUE, removes all-uppercase patterns from `regex_table`.
- **clean_text**: Logical; if TRUE, applies basic text cleaning to the input before matching.
- **verbose**: Logical; whether to display basic progress messages.

### Returns
A data frame with one row per match and all original columns from `data`.

### Overview
The `extract()` function searches a data frame or character vector for text patterns defined in a regex table.  
By default, it performs strict, whole-word matching and returns all columns from the input data for rows that match any pattern.  
Users can optionally specify which columns to return and which pattern column in the regex table to use.  
Additional optional arguments include ID filtering, start and end dates, typo correction, and text cleaning.  
This makes `extract()` flexible for extracting specific patterns while keeping the full dataset structure intact.


### Example
```r
# Example usage
result <- extract(data = my_data, 
                  col_name = "text", 
                  regex_table = my_patterns)
                  
### Future Development
- Add support for `typo_table` to correct known text errors before matching.
- Improve strict matching rules for patterns that may need more inclusive or more restrictive word boundaries.  
- Enable user-defined ID systems (e.g., corporations, campaigns) and control whether text is returned with matches. 