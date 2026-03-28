# Extract Regex Pattern Matches from Text Data

Matches text against a table of regular expressions and returns
extracted matches with optional metadata.

## Usage

``` r
extract(
  data,
  col_name = "text",
  regex_table,
  pattern_col = "pattern",
  data_return_cols = NULL,
  regex_return_cols = NULL,
  date_col = NULL,
  date_start = NULL,
  date_end = NULL,
  remove_acronyms = FALSE,
  do_clean_text = TRUE,
  verbose = TRUE,
  unique_match = FALSE,
  cl = NULL,
  use_ner = FALSE,
  ner_entity_types = c("ORG")
)
```

## Arguments

- data:

  A data frame or character vector containing the text to search. If a
  character vector is provided, it is internally converted to a data
  frame and `col_name` is ignored.

- col_name:

  Character string specifying the column in `data` that contains text to
  search. Default is "text".

- regex_table:

  A data frame containing regular expression patterns and optional
  metadata columns.

- pattern_col:

  Character string specifying the column in `regex_table` that contains
  regex patterns. Default is "pattern".

- data_return_cols:

  Optional vector of column names to include from `data`. Default is
  `NULL` (only `row_id` is returned).

- regex_return_cols:

  Optional vector of column names to include from `regex_table`. Default
  is `NULL` (no metadata columns added).

- date_col:

  Optional column in `data` for date filtering. If provided, rows are
  filtered by `date_start` and `date_end` before pattern matching.

- date_start:

  Optional start date (Date object or string like "YYYY-MM-DD") for
  filtering `data` when `date_col` is specified.

- date_end:

  Optional end date (Date object or string like "YYYY-MM-DD") for
  filtering `data` when `date_col` is specified.

- remove_acronyms:

  Logical; if TRUE, removes patterns consisting only of uppercase
  letters (2 or more characters) from `regex_table`.

- do_clean_text:

  Logical; if TRUE, applies basic text cleaning to the input before
  matching.

- verbose:

  Logical; if TRUE, displays progress messages.

- unique_match:

  Logical; if TRUE, stops searching after the first match to find at
  most one match per row (evaluated in the order patterns appear in
  `regex_table`). If FALSE, returns all matches for all patterns.

- cl:

  A cluster object created by
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html),
  or an integer to indicate number of child processes (integer values
  are ignored on Windows). Passed to
  [`pbapply::pblapply()`](https://peter.solymos.org/pbapply/reference/pbapply.html).

- use_ner:

  Logical; if TRUE, uses the 'spacyr' package to validate that matches
  are actual Named Entities (e.g., organizations). Note: `spacyr` must
  be initialized (e.g., via
  [`spacyr::spacy_initialize()`](http://spacyr.quanteda.io/reference/spacy_initialize.md))
  before calling this function.

- ner_entity_types:

  Character vector; the types of Named Entities to keep if `use_ner` is
  TRUE. Default is "ORG".

## Value

A tibble with the following columns:

- `row_id`: Integer identifier corresponding to rows in the input data.

- Additional columns from `data` if `data_return_cols` is specified.

- Additional columns from `regex_table` if `regex_return_cols` is
  specified.

- `pattern`: The matched regular expression pattern(s).

- `match`: The extracted text from the data (original casing preserved).

## Details

Pattern matching is performed using R's regular expression engine and is
case-insensitive by default. For each input row, the function checks
patterns in `regex_table` and returns matches based on the
`unique_match` parameter.

## Examples

``` r
# Create sample data
data <- data.frame(
  id = 1:3,
  text = c("I love apples", "Bananas are great", "Oranges and apples"),
  stringsAsFactors = FALSE
)

# Create regex patterns
patterns <- data.frame(
  pattern = c("apples", "bananas", "oranges"),
  category = c("fruit", "fruit", "fruit")
)

# Extract all matches
extract(data, "text", patterns)
#> Scanning 3 patterns against 3 text entries...
#>   |                                                  | 0 % ~calculating    |+++++++++++++++++                                 | 33% ~00s            |++++++++++++++++++++++++++++++++++                | 67% ~00s            |++++++++++++++++++++++++++++++++++++++++++++++++++| 100% elapsed=00s  
#> Number of rows with matches: 4
#> # A tibble: 4 × 3
#>   row_id pattern match  
#>    <int> <chr>   <chr>  
#> 1      1 apples  apples 
#> 2      2 bananas Bananas
#> 3      3 apples  apples 
#> 4      3 oranges Oranges

# Extract one match per row
extract(data, "text", patterns, unique_match = TRUE)
#> Scanning: 3 patterns against 3 text entries...
#>   |                                                  | 0 % ~calculating    |+++++++++++++++++                                 | 33% ~00s            |++++++++++++++++++++++++++++++++++                | 67% ~00s            |++++++++++++++++++++++++++++++++++++++++++++++++++| 100% elapsed=00s  
#> Number of rows with matches: 3
#> # A tibble: 3 × 3
#>   row_id pattern match  
#>    <int> <chr>   <chr>  
#> 1      1 apples  apples 
#> 2      2 bananas Bananas
#> 3      3 apples  apples 
```
