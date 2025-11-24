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
- **return_cols**: (default NULL) Vector of columns to include in the
  output.
- **id_col**: (default NULL) Column in data used for filtering rows
  before matching.
- **id_filter**: (default NULL) Value(s) of IDs to restrict which rows
  are matched.
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
from `data` (or `return_cols` if specified) - `pattern` — the first
regex pattern matched in each row

### Basic Usage

The simplest use of `extract()` with only the required arguments. This
finds all matches in the text column using the provided regex table.

``` r
#Extract patterns using only required arguments
result <- extract(
  data = cr2007_03_01,
  col_name = "header",
  regex_table = members
)

head(result)
#> # A tibble: 6 × 7
#>   date       speaker                              header                                   url   url_txt data_id pattern
#>   <date>     <chr>                                <chr>                                    <chr> <chr>     <int> <chr>  
#> 1 2007-03-01 HON. EDOLPHUS TOWNS;Mr. TOWNS        NEW PUNJAB CHIEF MINISTER URGED TO WORK… http… https:…       7 "harry…
#> 2 2007-03-01 HON. EDOLPHUS TOWNS;Mr. TOWNS        SIKH EDITOR WRITES TO PRESIDENT BUSH, U… http… https:…      23 "georg…
#> 3 2007-03-01 HON. GABRIELLE GIFFORDS;Ms. GIFFORDS CROSS PARTY LINES TO PASS COMPREHENSIVE… http… https:…      31 "olive…
#> 4 2007-03-01 HON. GREGORY W. MEEKS;Mr. MEEKS      BLACK HISTORY MONTH; Congressional Reco… http… https:…      43 "diane…
#> 5 2007-03-01 Mr. KUCINICH                         KUCINICH OPPOSED TO ATTACK ON IRAN; Con… http… https:…      80 "denni…
#> 6 2007-03-01 Mr. PENCE                            PENCE EXCHANGE WITH AMBASSADOR RICHARD … http… https:…      82 "grego…
```

### Advanced Usage

Shows how to use optional arguments for more control, such as filtering
by IDs, date ranges, and removing acronyms. Useful when you want to
narrow the matches, not clean the text, or choose to display messages.

``` r
# Advanced usage with optional filters
result_advanced <- extract(
  data = cr2007_03_01,
  col_name = "header",
  regex_table = members,
  id_filter = 80:130,         
  date_col = "date",               
  date_start = "2007-01-01",
  date_end = "2007-12-31",
  remove_acronyms = TRUE,
  return_cols = c("date", "header", "pattern")
)

head(result_advanced)
#> # A tibble: 4 × 4
#>   data_id pattern                                                                                      date       header
#>     <int> <chr>                                                                                        <date>     <chr> 
#> 1      80 "dennis kucinich|\\bd kucinich|dennis j kucinich|denny kucinich|denny j kucinich|(^|senator… 2007-03-01 KUCIN…
#> 2      82 "gregory pence|\\bg pence|greg pence|(^|senator |representative )pence\\b|pence, greg|pence… 2007-03-01 PENCE…
#> 3      94 "richard white|richard alan white|\\br white|richard a white|rick white|rick alan white|ric… 2007-03-01 WHITE…
#> 4     127 "roger peace|roger craft peace|\\br peace|roger c peace|\\bna peace|(^|senator |representat… 2007-03-01 PEACE…
```

### Future Development

- Add support for `typo_table` to correct known text errors before
  matching.
- Improve strict matching rules for patterns that may need more
  inclusive or more restrictive word boundaries.  
- Enable user-defined ID systems (e.g., corporations, campaigns) and
  control whether text is returned with matches.
