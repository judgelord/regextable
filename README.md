# regextable: pattern-based text extraction and cleaning


<!--DO NOT EDIT .md file, only README.qmd-->

# regextable <img src="man/figures/logo.png" align="right" widht="150"/>

## Description

`regextable` extracts regular-expression-based pattern matches from a
vector of text using a lookup table of regular expressions. It requires
two inputs:

1.  `data`: A vector of text to search (typically a data frame with a
    `text` column)
2.  `regex_table`: A lookup table (a data frame with a column of strings
    or regular expressions to search for, typically called `pattern`)

For each matching substring, `regextable::extract` returns

- the row number of `data`  
- the `pattern`
- the matched substring
- Optionally, other columns in `data` or `regex_table`

## Installation

    devtools::install_github("judgelord/regextable")

``` r
library(regextable)
```

## Data

The examples below use the example regex lookup table `members` and
example data `cr2007_03_01` from the `legislators` package, which are
also included in this package for illustration.

``` r
data("members")
head(members)
#> # A tibble: 6 × 9
#>   congress chamber   bioname                         pattern       icpsr state_abbrev district_code first_name last_name
#>      <dbl> <chr>     <chr>                           <chr>         <dbl> <chr>                <dbl> <chr>      <chr>    
#> 1      110 President BUSH, George Walker             "george bush… 99910 USA                      0 George     BUSH     
#> 2      110 House     BONNER, Jr., Josiah Robins (Jo) "josiah bonn… 20300 AL                       1 Josiah     BONNER   
#> 3      110 House     ROGERS, Mike Dennis             "mike rogers… 20301 AL                       3 Mike       ROGERS   
#> 4      110 House     DAVIS, Artur                    "artur davis… 20302 AL                       7 Artur      DAVIS    
#> 5      110 House     CRAMER, Robert E. (Bud), Jr.    "robert cram… 29100 AL                       5 Robert     CRAMER   
#> 6      110 House     EVERETT, Robert Terry           "robert ever… 29300 AL                       2 Robert     EVERETT

data("cr2007_03_01")
head(cr2007_03_01)
#> # A tibble: 6 × 5
#>   date       text                                header                                                    url   url_txt
#>   <date>     <chr>                               <chr>                                                     <chr> <chr>  
#> 1 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE… http… https:…
#> 2 2007-03-01 HON. MARK UDALL;Mr. UDALL           INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH AN… http… https:…
#> 3 2007-03-01 HON. JAMES R. LANGEVIN;Mr. LANGEVIN BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional R… http… https:…
#> 4 2007-03-01 HON. JIM COSTA;Mr. COSTA            A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional … http… https:…
#> 5 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE… http… https:…
#> 6 2007-03-01 HON. SANFORD D. BISHOP;Mr. BISHOP   IN HONOR OF SYNOVUS BEING NAMED ONE OF THE BEST COMPANIE… http… https:…
```

## Text cleaning

Before matching, by default, `clean_text()` is applied to standardize
text for better matching in messy text. It converts text to lowercase,
removes excess punctuation, replaces line breaks and dashes with spaces,
and collapses multiple spaces into a single space. Text cleaning is
applied only during matching and does not modify the original input
data. Users can disable this behavior by setting
`do_clean_text = FALSE`.

``` r
text <- "  HELLO---WORLD  "
cleaned_text <- clean_text(text)
print(cleaned_text)
#> [1] "hello world"
```

## Extract regex-based matches from text

### Description

`extract()` performs regex-based matching on a text column using a
pattern lookup table. All patterns that match each row are returned,
along with the corresponding pattern and optional metadata from the
pattern table. If multiple patterns match the same text, multiple rows
are returned, one per match.

### Required Parameters

- **`data`**: A data frame or character vector containing the text to
  search.
- **`regex_table`**: A regex lookup table with at least one pattern
  column.

### Optional Parameters

- **`col_name`**: (default `"text"`) Column name in the data frame
  containing text to search through.
- **`pattern_col`**: (default `"pattern"`) Name of the regex pattern
  column in `regex_table`.
- **`data_return_cols`**: (default `NULL`) Vector of additional columns
  from `data` to include in the output.
- **`regex_return_cols`**: (default `NULL`) Vector of additional columns
  from `regex_table` to include in the output.
- **`date_col`**: (default `NULL`) Column in `data` containing dates for
  filtering.
- **`date_start`**: (default `NULL`) Start date for filtering rows.
- **`date_end`**: (default `NULL`) End date for filtering rows.
- **`remove_acronyms`**: (default `FALSE`) If `TRUE`, removes
  all-uppercase patterns from `regex_table`.
- **`do_clean_text`**: (default `TRUE`) If `TRUE`, cleans text before
  matching.
- **`verbose`**: (default `TRUE`) If `TRUE`, displays progress messages.
- **`cl`**: (default `NULL`) A cluster object or integer specifying
  child processes for parallel evaluation (ignored on Windows).

### Returns

A data frame with one row per match, including:

- `row_id`: the internal row number of the text in the input data

- Optional columns from the input data (if data_return_cols specified)

- Optional columns from the regex table (if regex_return_cols specified)

- `pattern`: the regex pattern matched

- # `match`: the substring matched in the text

- `pattern`, the first regex pattern matched in each row

- `row_id`, the row number of the text

- Additional columns from `data` specified in `data_return_cols`

- Additional columns from `regex_table` specified in `regex_return_cols`

### Basic Usage

The simplest use of `extract()` with only the required arguments and
returned columns specified. This finds all matches in the text column
using the provided regex table.

``` r
#Extract patterns using only required arguments
result <- extract(
  data = cr2007_03_01,
  regex_table = members,
  data_return_cols = c("text"),
  regex_return_cols = c("icpsr") 
)

head(result)
#> # A tibble: 6 × 5
#>   row_id text                                icpsr pattern                                                         match
#>    <int> <chr>                               <dbl> <chr>                                                           <chr>
#> 1      1 HON. SAM GRAVES;Mr. GRAVES          20124 "samuel graves|\\bs graves|sam graves|(^|senator |representati… SAM …
#> 2      2 HON. MARK UDALL;Mr. UDALL           29906 "mark udall|\\bm udall|mark e udall|\\bna udall|(^|senator |re… MARK…
#> 3      3 HON. JAMES R. LANGEVIN;Mr. LANGEVIN 20136 "james langevin|\\bj langevin|james r langevin|jim langevin|ji… jame…
#> 4      4 HON. JIM COSTA;Mr. COSTA            20501 "jim costa|\\bj costa|james costa|(^|senator |representative )… JIM …
#> 5      5 HON. SAM GRAVES;Mr. GRAVES          20124 "samuel graves|\\bs graves|sam graves|(^|senator |representati… SAM …
#> 6      6 HON. SANFORD D. BISHOP;Mr. BISHOP   29339 "sanford bishop|sanford dixon bishop|\\bs bishop|sanford d bis… sanf…
```

### Advanced Usage

Shows how to use optional arguments for more control, such as filtering
by date ranges and removing acronyms. This is useful when you want to
narrow matches, disable text cleaning, control returned columns, or
suppress messages.

``` r
# Advanced usage with optional filters
result_advanced <- extract(
  data = cr2007_03_01,
  regex_table = members,
  date_col = "date",               
  date_start = "2007-01-01",
  date_end = "2007-12-31",
  remove_acronyms = TRUE,
  data_return_cols = c("text"),
  regex_return_cols = c("icpsr")
)

head(result_advanced)
#> # A tibble: 6 × 5
#>   row_id text                                icpsr pattern                                                         match
#>    <int> <chr>                               <dbl> <chr>                                                           <chr>
#> 1      1 HON. SAM GRAVES;Mr. GRAVES          20124 "samuel graves|\\bs graves|sam graves|(^|senator |representati… SAM …
#> 2      2 HON. MARK UDALL;Mr. UDALL           29906 "mark udall|\\bm udall|mark e udall|\\bna udall|(^|senator |re… MARK…
#> 3      3 HON. JAMES R. LANGEVIN;Mr. LANGEVIN 20136 "james langevin|\\bj langevin|james r langevin|jim langevin|ji… jame…
#> 4      4 HON. JIM COSTA;Mr. COSTA            20501 "jim costa|\\bj costa|james costa|(^|senator |representative )… JIM …
#> 5      5 HON. SAM GRAVES;Mr. GRAVES          20124 "samuel graves|\\bs graves|sam graves|(^|senator |representati… SAM …
#> 6      6 HON. SANFORD D. BISHOP;Mr. BISHOP   29339 "sanford bishop|sanford dixon bishop|\\bs bishop|sanford d bis… sanf…
```

### Future Development

- Add support for `typo_table` to correct known text errors before
  matching.
- Improve strict matching rules for patterns that may need more
  inclusive or more restrictive word boundaries.
- Enable user-defined ID systems (e.g., corporations, campaigns) and
  control whether text is returned with matches.
