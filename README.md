# regextable: Apply pattern-based text extraction and cleaning


<!-- README.md is generated from README.qmd. Please edit that file -->

### Installation

    devtools::install_github("judgelord/regextable")

``` r
library(regextable)
```

## Data

This package operates on a data frame containing text to search and a
corresponding regex lookup table containing patterns to match. Users
must supply both the text data and the regex table, allowing extract()
to work with any dataset or domain.

For example, you can provide a table of names, companies, or acronyms as
the regex table, and any data frame of text as input. Example datasets
`members` and `cr2007_03_01` from the legislators package are used here
only for illustration. Users can supply any data frame and any regex
table.

``` r
data("members")
head(members)
```

    #> # A tibble: 6 × 9
    #>   congress chamber   bioname                      pattern                                                                                          icpsr state_abbrev district_code first_name last_name
    #>      <dbl> <chr>     <chr>                        <chr>                                                                                            <dbl> <chr>                <dbl> <chr>      <chr>    
    #> 1      117 President TRUMP, Donald John           "donald trump|donald john trump|\\bd trump|donald j trump|don trump|don john trump|don j trump|… 99912 USA                      0 Donald     TRUMP    
    #> 2      117 President BIDEN, Joseph Robinette, Jr. "joseph biden|joseph robinette biden|\\bj biden|joseph r biden|joe biden|joe robinette biden|jo… 99913 USA                      0 Joseph     BIDEN    
    #> 3      117 House     ROGERS, Mike Dennis          "mike rogers|mike dennis rogers|\\bm rogers|mike d rogers|michael rogers|michael dennis rogers|… 20301 AL                       3 Mike       ROGERS   
    #> 4      117 House     SEWELL, Terri                "terri sewell|\\bt sewell|terri a sewell|\\bna sewell|(^|senator |representative )sewell\\b|sew… 21102 AL                       7 Terri      SEWELL   
    #> 5      117 House     BROOKS, Mo                   "mo brooks|\\bm brooks|\\bna brooks|(^|senator |representative )brooks\\b|brooks, mo|brooks mo|… 21193 AL                       5 Mo         BROOKS   
    #> 6      117 House     PALMER, Gary James           "gary palmer|gary james palmer|\\bg palmer|gary j palmer|\\bna palmer|(^|senator |representativ… 21500 AL                       6 Gary       PALMER

``` r
data("cr2007_03_01")
head(cr2007_03_01)
```

    #> # A tibble: 6 × 5
    #>   date       speaker                             header                                                                                                                                    url   url_txt
    #>   <date>     <chr>                               <chr>                                                                                                                                     <chr> <chr>  
    #> 1 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT; Congressional Record Vol. 153, No. 35                                     http… https:…
    #> 2 2007-03-01 HON. MARK UDALL;Mr. UDALL           INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH ANNIVERSARY OF THE INTERNATIONAL GEOPHYSICAL YEAR (IGY); Congressional Record Vol.… http… https:…
    #> 3 2007-03-01 HON. JAMES R. LANGEVIN;Mr. LANGEVIN BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional Record Vol. 153, No. 35                                                            http… https:…
    #> 4 2007-03-01 HON. JIM COSTA;Mr. COSTA            A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional Record Vol. 153, No. 35                                                           http… https:…
    #> 5 2007-03-01 HON. SAM GRAVES;Mr. GRAVES          RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT                                                                            http… https:…
    #> 6 2007-03-01 HON. SANFORD D. BISHOP;Mr. BISHOP   IN HONOR OF SYNOVUS BEING NAMED ONE OF THE BEST COMPANIES IN AMERICA; Congressional Record Vol. 153, No. 35                               http… https:…

## Text cleaning

Before searching text, `clean_text()` standardizes formatting to improve
matching. It removes excess punctuation and spacing, lowercases text,
and normalizes formatting.

``` r
text <- "  HELLO---WORLD  "
cleaned_text <- clean_text(text)
print(cleaned_text)
```

    #> [1] "hello---world"

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
- **clean_text**: (default TRUE) If TRUE, applies basic text cleaning
  before matching.
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
```

    #> Matching 14752 patterns against 154 text entries

    #> Number of matches found: 8

``` r
head(result)
```

    #> # A tibble: 6 × 7
    #>   date       speaker                              header                                                                                                      url                url_txt data_id pattern
    #>   <date>     <chr>                                <chr>                                                                                                       <chr>              <chr>     <int> <chr>  
    #> 1 2007-03-01 HON. EDOLPHUS TOWNS;Mr. TOWNS        NEW PUNJAB CHIEF MINISTER URGED TO WORK FOR SIKH SOVEREIGNTY; Congressional Record Vol. 153, No. 35         https://www.congr… https:…       7 "harry…
    #> 2 2007-03-01 HON. EDOLPHUS TOWNS;Mr. TOWNS        SIKH EDITOR WRITES TO PRESIDENT BUSH, URGES SUPPORT FOR SIKH FREEDOM; Congressional Record Vol. 153, No. 35 https://www.congr… https:…      23 "georg…
    #> 3 2007-03-01 HON. GABRIELLE GIFFORDS;Ms. GIFFORDS CROSS PARTY LINES TO PASS COMPREHENSIVE IMMIGRATION REFORM; Congressional Record Vol. 153, No. 35           https://www.congr… https:…      31 "olive…
    #> 4 2007-03-01 HON. GREGORY W. MEEKS;Mr. MEEKS      BLACK HISTORY MONTH; Congressional Record Vol. 153, No. 35                                                  https://www.congr… https:…      43 "diane…
    #> 5 2007-03-01 Mr. KUCINICH                         KUCINICH OPPOSED TO ATTACK ON IRAN; Congressional Record Vol. 153, No. 35                                   https://www.congr… https:…      80 "denni…
    #> 6 2007-03-01 Mr. PENCE                            PENCE EXCHANGE WITH AMBASSADOR RICHARD C. HOLBROOK; Congressional Record Vol. 153, No. 35                   https://www.congr… https:…      82 "grego…

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
```

    #> Matching 14752 patterns against 51 text entries

    #> Number of matches found: 4

``` r
head(result_advanced)
```

    #> # A tibble: 4 × 4
    #>   data_id pattern                                                                                                                                                                      date       header
    #>     <int> <chr>                                                                                                                                                                        <date>     <chr> 
    #> 1      80 "dennis kucinich|\\bd kucinich|dennis j kucinich|denny kucinich|denny j kucinich|(^|senator |representative )kucinich\\b|kucinich, denny|kucinich, dennis|kucinich dennis|k… 2007-03-01 KUCIN…
    #> 2      82 "gregory pence|\\bg pence|greg pence|(^|senator |representative )pence\\b|pence, greg|pence, gregory|pence gregory|pence, g\\b|representative pence\\b"                      2007-03-01 PENCE…
    #> 3      94 "richard white|richard alan white|\\br white|richard a white|rick white|rick alan white|rick a white|(^|senator |representative )white\\b|white, rick|white, richard|white … 2007-03-01 WHITE…
    #> 4     127 "roger peace|roger craft peace|\\br peace|roger c peace|\\bna peace|(^|senator |representative )peace\\b|peace, roger|peace roger|peace, r\\b|senator peace\\b|r c peace"    2007-03-01 PEACE…

### Future Development

- Add support for `typo_table` to correct known text errors before
  matching.
- Improve strict matching rules for patterns that may need more
  inclusive or more restrictive word boundaries.  
- Enable user-defined ID systems (e.g., corporations, campaigns) and
  control whether text is returned with matches.
