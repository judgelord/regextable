# regextable: Apply pattern-based text extraction and cleaning


## regextable: Apply pattern-based text extraction and cleaning

### Installation

    devtools::install_github("judgelord/regextable")

``` r
library(regextable)
```

## Data

This package operates on two inputs:

1.  A data frame containing the text to search.
2.  A regex lookup table containing patterns to match.

Because users supply both the data and the patterns, `extract()` works
across any domain (legislators, corporations, biology, etc.).

The examples below use the `members` and `cr2007_03_01` datasets
included in this package for illustration.

``` r
data("members")
head(members)
#> # A tibble: 6 × 9
#>   congress chamber   bioname                      pattern          icpsr state_abbrev district_code first_name last_name
#>      <dbl> <chr>     <chr>                        <chr>            <dbl> <chr>                <dbl> <chr>      <chr>    
#> 1      117 President TRUMP, Donald John           "donald trump|d… 99912 USA                      0 Donald     TRUMP    
#> 2      117 President BIDEN, Joseph Robinette, Jr. "joseph biden|j… 99913 USA                      0 Joseph     BIDEN    
#> 3      117 House     ROGERS, Mike Dennis          "mike rogers|mi… 20301 AL                       3 Mike       ROGERS   
#> 4      117 House     SEWELL, Terri                "terri sewell|\… 21102 AL                       7 Terri      SEWELL   
#> 5      117 House     BROOKS, Mo                   "mo brooks|\\bm… 21193 AL                       5 Mo         BROOKS   
#> 6      117 House     PALMER, Gary James           "gary palmer|ga… 21500 AL                       6 Gary       PALMER

data("cr2007_03_01")
head(cr2007_03_01)
#> # A tibble: 6 × 5
#>   date       speaker                             header                                                    url   url_txt
#>   <date>     <chr>                               <chr>                                                     <chr> <chr>  
#> 1 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE… http… https:…
#> 2 2007-03-01 HON. MARK UDALL;Mr. UDALL           INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH AN… http… https:…
#> 3 2007-03-01 HON. JAMES R. LANGEVIN;Mr. LANGEVIN BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional R… http… https:…
#> 4 2007-03-01 HON. JIM COSTA;Mr. COSTA            A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional … http… https:…
#> 5 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE… http… https:…
#> 6 2007-03-01 HON. SANFORD D. BISHOP;Mr. BISHOP   IN HONOR OF SYNOVUS BEING NAMED ONE OF THE BEST COMPANIE… http… https:…
```

## Text cleaning

Before searching text, `clean_text()` standardizes formatting to improve
matching. It removes excess punctuation and spacing, lowercases text,
and normalizes formatting.

``` r
text <- "  HELLO---WORLD  "
cleaned_text <- clean_text(text)
print(cleaned_text)
#> [1] "hello---world"
```

## Extract regex-based matches from text

### Description

`extract()` performs regex-based matching on a text column using a
lookup table. It returns a data frame with one row per detected pattern
match and includes all original columns (or a subset if `return_cols` is
specified).

### Required Parameters

- **data**: A data frame or character vector containing the text to
  search.
- **col_name**: Column name in the data frame containing text to search
  through.
- **regex_table**: A regex lookup table with at least one pattern
  column.

### Optional Parameters

- **pattern_col**: (default “pattern”) Name of the regex pattern column
  in regex_table.
- **return_cols**: (default NULL) Vector of columns from ‘data’ to
  include in the output.
- **regex_return_cols** (default NULL) Vector of columns from ‘regex\_’
  to include in the output.
- **date_col**: (default NULL) Column in data containing dates for
  filtering.
- **date_start**: (default NULL) Start date for filtering rows.
- **date_end**: (default NULL) End date for filtering rows.
- **typo_table**: (default NULL) Table of typos to correct in data.
  (planned for future versions)
- **remove_acronyms**: (default FALSE) If TRUE, removes all-uppercase
  patterns from regex_table.
- **do_clean_text**: (default TRUE) Clean text before matching.
- **verbose**: (default TRUE) If TRUE, displays progress messages.

### Returns

A data frame with one row per match, including: - All original columns
from `data` (or `return_cols` if specified) - `pattern`, the first regex
pattern matched in each row

### Basic Usage

The simplest use of `extract()` with only the required arguments. This
finds all matches in the text column using the provided regex table.

``` r
#Extract patterns using only required arguments
result <- extract(
  data = cr2007_03_01,
  col_name = "speaker",
  regex_table = members,
  return_cols = c("speaker", "pattern"),
  regex_return_cols = c("icpsr") 
)

head(result)
#> # A tibble: 6 × 3
#>   speaker                    pattern                                                                               icpsr
#>   <chr>                      <chr>                                                                                 <dbl>
#> 1 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 2 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 3 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 4 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 5 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 6 HON. MARK UDALL;Mr. UDALL  "mark udall|\\bm udall|mark e udall|\\bna udall|(^|senator |representative )udall\\b… 29906
```

### Advanced Usage

Shows how to use optional arguments for more control, such as filtering
by date ranges and removing acronyms. Useful when you want to narrow the
matches, not clean the text, specifying returned columns, or choose to
display messages.

``` r
# Advanced usage with optional filters
result_advanced <- extract(
  data = cr2007_03_01,
  col_name = "speaker",
  regex_table = members,
  date_col = "date",               
  date_start = "2007-01-01",
  date_end = "2007-12-31",
  remove_acronyms = TRUE,
  return_cols = c("speaker", "pattern"),
  regex_return_cols = c("icpsr")
)

head(result_advanced)
#> # A tibble: 6 × 3
#>   speaker                    pattern                                                                               icpsr
#>   <chr>                      <chr>                                                                                 <dbl>
#> 1 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 2 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 3 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 4 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 5 HON. SAM GRAVES;Mr. GRAVES "samuel graves|\\bs graves|sam graves|(^|senator |representative )graves\\b.{1,4}mo|… 20124
#> 6 HON. MARK UDALL;Mr. UDALL  "mark udall|\\bm udall|mark e udall|\\bna udall|(^|senator |representative )udall\\b… 29906
```

### Future Development

- Add support for `typo_table` to correct known text errors before
  matching.
- Improve strict matching rules for patterns that may need more
  inclusive or more restrictive word boundaries.  
- Enable user-defined ID systems (e.g., corporations, campaigns) and
  control whether text is returned with matches.
