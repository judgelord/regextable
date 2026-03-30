

<!--DO NOT EDIT .md file, only README.qmd-->

# regextable <img src="man/figures/logo.png" align="right" width="125"/>

## Description

`regextable` extracts regular-expression-based pattern matches from a
vector of text using a lookup table of regular expressions. It requires
two inputs:

1.  `data`: A data frame containing a text column, or a character
    vector.
2.  `regex_table`: A lookup table (a data frame with a column of strings
    or regular expressions to search for, typically called `pattern`)

For each text entry, `regextable::extract` returns:

- the row number of the input `data`
- the matched `pattern`
- the exact substring extracted from the text
- Optionally, other metadata columns from `data` or `regex_table`

Users can choose to return *all* matches (resulting in multiple rows per
text entry) or limit the output to just the first match found.

## Installation

    devtools::install_github("judgelord/regextable")

``` r
library(regextable)
```

## Data

The examples below use an example regex lookup table of members of
Congress, `members`, and example text data from the Congressional
Record, `cr2007_03_01`, from the
[`legislators`](https://judgelord.github.io/legislators/) package, which
are also included in this package, subset to `congress == 107`, for
illustration.

``` r
data("members")
head(members)
#> # A tibble: 6 × 11
#>   chamber   congress bioname             pattern icpsr state state_abbrev district_code bioguide_id first_name last_name
#>   <chr>        <dbl> <chr>               <chr>   <dbl> <int> <chr>                <dbl> <chr>       <chr>      <chr>    
#> 1 President      107 BUSH, George Walker "georg… 99910    NA USA                      0 <NA>        George     BUSH     
#> 2 House          107 CALLAHAN, Herbert … "herbe… 15090     1 AL                       1 C000052     Herbert    CALLAHAN 
#> 3 House          107 CRAMER, Robert E. … "rober… 29100     1 AL                       5 C000868     Robert     CRAMER   
#> 4 House          107 EVERETT, Robert Te… "rober… 29300     1 AL                       2 E000268     Robert     EVERETT  
#> 5 House          107 BACHUS, Spencer T.… "spenc… 29301     1 AL                       6 B000013     Spencer    BACHUS   
#> 6 House          107 HILLIARD, Earl Fre… "earl … 29302     1 AL                       7 H000621     Earl       HILLIARD

data("cr2007_03_01")
head(cr2007_03_01)
#> # A tibble: 6 × 4
#>   date       text                                header                                                            url  
#>   <date>     <chr>                               <chr>                                                             <chr>
#> 1 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT; … http…
#> 2 2007-03-01 HON. MARK UDALL;Mr. UDALL           INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH ANNIVERSAR… http…
#> 3 2007-03-01 HON. JAMES R. LANGEVIN;Mr. LANGEVIN BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional Record Vo… http…
#> 4 2007-03-01 HON. JIM COSTA;Mr. COSTA            A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional Record V… http…
#> 5 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT    http…
#> 6 2007-03-01 HON. SANFORD D. BISHOP;Mr. BISHOP   IN HONOR OF SYNOVUS BEING NAMED ONE OF THE BEST COMPANIES IN AME… http…
```

## Text cleaning

Before matching, by default, `clean_text()` is applied to standardize
messy text. It converts text to lowercase, removes specific punctuation
(`+`, `—`, `!`, `?`, `:`, `;`), replaces line breaks, tabs, periods, and
dashes with spaces, and normalizes commas and excess whitespace. Text
cleaning is applied only internally during matching and does not modify
the original input data. Users can disable this behavior by setting
`do_clean_text = FALSE`.

``` r
text <- "  HELLO---WORLD  "
cleaned_text <- clean_text(text)
print(cleaned_text)
#> [1] "hello world"
```

## Extract Regex-Based Matches from Text

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
  containing text to search through. *(Note: If `data` is a character
  vector, it is internally converted to a data frame and this argument
  is ignored).*
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
- **`unique_match`** (default `FALSE`) If `TRUE`, stops searching after
  first match to find at most one match per row.
- **`cl`**: (default `NULL`) A cluster object or integer specifying
  child processes for parallel evaluation (ignored on Windows).
- **`use_ner`**: (default `FALSE`) If TRUE, uses the ‘spacyr’ package to
  validate that matches are actual Named Entities (e.g., organizations).
  Requires ‘spacyr’ to be installed and initialized. Note: If ‘spacyr’
  is missing or fails to initialize, the function will perform standard
  regex matching and issue a warning.
- **`ner_entity_types`**: (default c(“ORG”)) Character vector; the types
  of spaCy Named Entities to keep if use_ner is TRUE (e.g., “ORG”,
  “PERSON”, “GPE”, “LAW”).

### Returns

A data frame with one row per match, including:

- `row_id`: the internal row number of the text in the input data
- `pattern`: the regex pattern matched
- `match`: the substring matched in the text
- Additional columns from the input `data` (if `data_return_cols`
  specified)
- Additional columns from the regex `table` (if `regex_return_cols`
  specified)

### Basic Usage

A simple usage of `extract()` with only the required arguments and
returned columns specified. This finds all matches in the text column
using the provided regex table.

``` r
# Extract patterns using only required arguments
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
#> 4      5 HON. SAM GRAVES;Mr. GRAVES          20124 "samuel graves|\\bs graves|sam graves|(^|senator |representati… SAM …
#> 5      6 HON. SANFORD D. BISHOP;Mr. BISHOP   29339 "sanford bishop|sanford dixon bishop|\\bs bishop|sanford d bis… sanf…
#> 6      7 HON. EDOLPHUS TOWNS;Mr. TOWNS       15072 "edolphus towns|\\be towns|ed towns|(^|senator |representative… EDOL…
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
#> 4      5 HON. SAM GRAVES;Mr. GRAVES          20124 "samuel graves|\\bs graves|sam graves|(^|senator |representati… SAM …
#> 5      6 HON. SANFORD D. BISHOP;Mr. BISHOP   29339 "sanford bishop|sanford dixon bishop|\\bs bishop|sanford d bis… sanf…
#> 6      7 HON. EDOLPHUS TOWNS;Mr. TOWNS       15072 "edolphus towns|\\be towns|ed towns|(^|senator |representative… EDOL…
```

### Future Development

- Add support for `typo_table` to correct known text errors before
  matching.
- Improve strict matching rules for patterns that may need more
  inclusive or more restrictive word boundaries.
- Enable user-defined ID systems (e.g., corporations, campaigns) and
  control whether text is returned with matches.
- Allow users to plug in their own regex_table without requiring a
  wrapper function.
- For additional data, direct users to download tables from the package
  creator’s repository.
