# Extract Regex Pattern Matches from Text Data

Matches text against a table of regular expressions and returns
extracted matches with optional metadata.

## Usage

``` r
extract(
  data,
  regex_table,
  col_name = "text",
  pattern_col = "pattern",
  typo_table = NULL,
  typo_from_col = "typo",
  typo_to_col = "correction",
  date_col = NULL,
  date_start = NULL,
  date_end = NULL,
  data_return_cols = NULL,
  regex_return_cols = NULL,
  remove_acronyms = FALSE,
  do_clean_text = TRUE,
  unique_match = FALSE,
  use_ner = FALSE,
  ner_timing = "after",
  ner_entity_types = c("ORG"),
  verbose = TRUE,
  cl = NULL
)
```

## Arguments

- data:

  A data frame or character vector containing the text to search. If a
  character vector is provided, it is internally converted to a data
  frame and `col_name` is ignored.

- regex_table:

  A data frame containing regular expression patterns and optional
  metadata columns.

- col_name:

  Character string specifying the column in `data` that contains text to
  search. Default is "text".

- pattern_col:

  Character string specifying the column in `regex_table` that contains
  regex patterns. Default is "pattern".

- typo_table:

  Optional data frame with text replacements for corrections.
  Replacements are applied sequentially to the text using regex (with
  word boundaries) before pattern matching.

- typo_from_col:

  Optional column in `typo_table` with text to replace. Default is
  "typo".

- typo_to_col:

  Optional column in `typo_table` with replacement text. Default is
  "correction".

- date_col:

  Optional column in `data` for date filtering. If provided, rows are
  filtered by `date_start` and `date_end` before pattern matching.

- date_start:

  Optional start date (Date object or string like "YYYY-MM-DD") for
  filtering `data` when `date_col` is specified.

- date_end:

  Optional end date (Date object or string like "YYYY-MM-DD") for
  filtering `data` when `date_col` is specified.

- data_return_cols:

  Optional vector of column names to include from `data`. Default is
  `NULL` (only `row_id` is returned).

- regex_return_cols:

  Optional vector of column names to include from `regex_table`. Default
  is `NULL` (no metadata columns added).

- remove_acronyms:

  Logical; if TRUE, removes patterns consisting only of uppercase
  letters (2 or more characters) from `regex_table`.

- do_clean_text:

  Logical; if TRUE, applies basic text cleaning to the input before
  matching.

- unique_match:

  Logical; if TRUE, stops searching after the first match to find at
  most one match per row (evaluated in the order patterns appear in
  `regex_table`). If FALSE, returns all matches for all patterns.

- use_ner:

  Logical; if TRUE, uses the 'spacyr' package to validate that matches
  are actual Named Entities (e.g., organizations). Note: `spacyr` must
  be initialized (e.g., via
  [`spacyr::spacy_initialize()`](http://spacyr.quanteda.io/reference/spacy_initialize.md))
  before calling this function.

- ner_timing:

  Character string; either "after" or "before". If "after" (default),
  regex matches are found first, then validated with NER. If "before",
  NER extracts entities first, and regex searches only within those
  entities.

- ner_entity_types:

  Character vector; the types of Named Entities to keep if `use_ner` is
  TRUE. Default is "ORG".

- verbose:

  Logical; if TRUE, displays progress messages.

- cl:

  A cluster object created by
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html),
  or an integer to indicate number of child processes (integer values
  are ignored on Windows). Passed to
  [`pbapply::pblapply()`](https://peter.solymos.org/pbapply/reference/pbapply.html).

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
extract(data, patterns)
#> Error in extract(data, patterns): argument "regex_table" is missing, with no default

# Extract one match per row
extract(data, patterns, unique_match = TRUE)
#> Error in extract(data, patterns, unique_match = TRUE): argument "regex_table" is missing, with no default
```
