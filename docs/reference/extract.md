# Extract pattern matches from text

Uses a regex lookup table to extract at most one pattern match.

## Usage

``` r
extract(
  data,
  col_name = "text",
  regex_table,
  pattern_col = "pattern",
  return_cols = NULL,
  regex_return_cols = NULL,
  date_col = NULL,
  date_start = NULL,
  date_end = NULL,
  remove_acronyms = FALSE,
  do_clean_text = TRUE,
  verbose = TRUE
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

- return_cols:

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

## Value

A tibble (data frame) with the following columns:

- All original columns from `data` (or subset specified by
  `return_cols`)

- `pattern` The matched regex pattern

- `match` The specific text extracted from the data

- `row_id` Integer row identifier corresponding to the input data

- Additional columns from `regex_table` if `regex_return_cols` specified

## Details

Pattern matching is performed using R's regular expression engine and is
case-insensitive by default. When multiple patterns match the same text,
the first match is determined by the order of rows in `regex_table`.

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

# Extract matches
extract(data, "text", patterns)
#> Matching 3 patterns against 3 text entries
#>   |                                                  | 0 % ~calculating    |+++++++++++++++++                                 | 33% ~00s            |++++++++++++++++++++++++++++++++++                | 67% ~00s            |++++++++++++++++++++++++++++++++++++++++++++++++++| 100% elapsed=00s  
#> Number of matches found: 3
#> # A tibble: 3 × 5
#>      id text               pattern match   row_id
#>   <int> <chr>              <chr>   <chr>    <int>
#> 1     1 I love apples      apples  apples       1
#> 2     2 Bananas are great  bananas bananas      2
#> 3     3 Oranges and apples apples  apples       3
```
