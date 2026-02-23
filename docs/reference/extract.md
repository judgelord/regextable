# Extract pattern matches from text

Uses a regex lookup table to extract pattern matches.

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
  cl = NULL
)
```

## Arguments

- data:

  A data frame or character vector containing the text to search.

- col_name:

  Column name in data frame containing text to search through.

- regex_table:

  A regex lookup table with a pattern column.

- pattern_col:

  Name of the regex pattern column in regex_table.

- data_return_cols:

  Optional vector of column names to include from 'data'.

- regex_return_cols:

  Optional vector of column names to include from 'regex_table'.

- date_col:

  Optional column in 'data' for date filtering.

- date_start:

  Optional start date for filtering 'data'.

- date_end:

  Optional end date for filtering 'data'.

- remove_acronyms:

  Logical; if TRUE, removes all-uppercase patterns from regex_table.

- do_clean_text:

  Logical; if TRUE, applies basic text cleaning to the input before
  matching.

- verbose:

  Logical; if TRUE, displays progress messages.

- unique_match:

  Logical; if TRUE, stops searching after first match to find at most
  one match per row. If FALSE, returns all matches for all patterns.

- cl:

  A cluster object created by
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html),
  or an integer to indicate number of child-processes (integer values
  are ignored on Windows) for parallel evaluations. Passed to
  [`pbapply::pblapply()`](https://peter.solymos.org/pbapply/reference/pbapply.html).

## Value

A tibble (data frame) with columns:

- `row_id` Integer row identifier corresponding to the input data

- Additional columns from `data` if `data_return_cols` specified

- Additional columns from `regex_table` if `regex_return_cols` specified

- `pattern` The matched regex pattern(s)

- `match` The specific text extracted from the data (original casing
  preserved)

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
