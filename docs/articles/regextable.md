# regextable

### Introduction

`regextable` extracts regex-based pattern matches from a data frame or
character vector using a pattern lookup table, returning the matched
pattern, the exact text match, an internal row identifier, and all
original columns from the input data unless specified, with optional
additional columns from the pattern table. Performance on large datasets
is improved by stopping the search for a row once a match is found.

Install and load the package:

``` r
devtools::install_github("judgelord/regextable")
```

``` r
library(regextable)
library(kableExtra)
```

## Data

For demonstration, we use two included datasets:

- `members`: A lookup table of regex patterns for member names.
- `cr2007_03_01`: A sample text dataset to search.

``` r
data("members")
kable(members)
```

| congress | chamber | bioname | pattern | icpsr | state_abbrev | district_code | first_name | last_name |
|---:|:---|:---|:---|---:|:---|---:|:---|:---|
| 110 | President | BUSH, George Walker | george bush&#124;george walker bush&#124;bush&#124;george w bush&#124;bush&#124;(^&#124;senator &#124;representative )bush&#124;bush, george&#124;bush george&#124;bush, g&#124;president bush&#124;g w bush | 99910 | USA | 0 | George | BUSH |
| 110 | House | BONNER, Jr., Josiah Robins (Jo) | josiah bonner&#124;josiah josiah robins bonner&#124;bonner&#124;josiah j bonner&#124;jo bonner&#124;jo josiah robins bonner&#124;jo j bonner&#124;(^&#124;senator &#124;representative )bonner&#124;bonner, jo&#124;bonner, josiah&#124;bonner josiah&#124;bonner, j&#124;representative bonner&#124;j j bonner | 20300 | AL | 1 | Josiah | BONNER |
| 110 | House | ROGERS, Mike Dennis | mike rogers&#124;mike dennis rogers&#124;rogers.{1,4}al&#124;mike d rogers&#124;michael rogers&#124;michael dennis rogers&#124;michael d rogers&#124;(^&#124;senator &#124;representative )rogers{1,4}al&#124;rogers, michael&#124;rogers, mike&#124;rogers mike&#124;representative rogers{1,4}al&#124;m d rogers | 20301 | AL | 3 | Mike | ROGERS |
| 110 | House | DAVIS, Artur | artur davis&#124;davis&#124;(^&#124;senator &#124;representative )davis{1,4}al&#124;davis, artur&#124;davis artur&#124;davis, a&#124;representative davis{1,4}al | 20302 | AL | 7 | Artur | DAVIS |
| 110 | House | CRAMER, Robert E. (Bud), Jr.  | robert cramer&#124;robert e cramer&#124;cramer&#124;bud cramer&#124;bud e cramer&#124;cramer&#124;(^&#124;senator &#124;representative )cramer&#124;cramer, bud&#124;cramer, robert&#124;cramer robert&#124;cramer, r&#124;cramer, b&#124;representative cramer&#124;r e cramer | 29100 | AL | 5 | Robert | CRAMER |

``` r

data("cr2007_03_01")
kable(cr2007_03_01)
```

| date | text | header | url | url_txt |
|:---|:---|:---|:---|:---|
| 2007-03-01 | HON. SAM GRAVES;Mr. GRAVES | RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT; Congressional Record Vol. 153, No. 35 | <https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-2> | <https://www.congress.gov/117/crec/2007/03/01/modified/CREC-2007-03-01-pt1-PgE431-2.htm> |
| 2007-03-01 | HON. MARK UDALL;Mr. UDALL | INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH ANNIVERSARY OF THE INTERNATIONAL GEOPHYSICAL YEAR (IGY); Congressional Record Vol. 153, No. 35 | <https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-3> | <https://www.congress.gov/117/crec/2007/03/01/modified/CREC-2007-03-01-pt1-PgE431-3.htm> |
| 2007-03-01 | HON. JAMES R. LANGEVIN;Mr. LANGEVIN | BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional Record Vol. 153, No. 35 | <https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-4> | <https://www.congress.gov/117/crec/2007/03/01/modified/CREC-2007-03-01-pt1-PgE431-4.htm> |
| 2007-03-01 | HON. JIM COSTA;Mr. COSTA | A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional Record Vol. 153, No. 35 | <https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-5> | <https://www.congress.gov/117/crec/2007/03/01/modified/CREC-2007-03-01-pt1-PgE431-5.htm> |
| 2007-03-01 | HON. SAM GRAVES;Mr. GRAVES | RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT | <https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-1> | <https://www.congress.gov/117/crec/2007/03/01/modified/CREC-2007-03-01-pt1-PgE431.htm> |

### Text Cleaning

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
cleans text by default, so the user does not need to call it manually.
Cleaning standardizes spacing, punctuation, and capitalization, which
helps regex pattern matching.

Example of
[`clean_text()`](https://judgelord.github.io/regextable/reference/clean_text.md):

``` r
text <- "  HELLO---WORLD  "
clean_text(text)
#> [1] "hello world"
```

## Basic Extraction

The simplest use of
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md):

``` r
result <- extract(
  data = cr2007_03_01,
  regex_table = members,
  return_cols = c("text"),
  regex_return_cols = c("icpsr")
)

kable(head(result))
```

| text | pattern | match | row_id | icpsr |
|:---|:---|:---|---:|---:|
| HON. SAM GRAVES;Mr. GRAVES | samuel graves&#124;graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s&#124;representative graves/td\> | sam graves | 1 | 20124 |
| HON. MARK UDALL;Mr. UDALL | mark udall&#124;udall&#124;mark e udall&#124;udall&#124;(^&#124;senator &#124;representative )udall{1,4}co&#124;udall, mark&#124;udall mark&#124;udall, m&#124;representative udall{1,4}co&#124;m e udall | mark udall | 2 | 29906 |
| HON. JAMES R. LANGEVIN;Mr. LANGEVIN | james langevin&#124;langevin&#124;james r langevin&#124;jim langevin&#124;jim r langevin&#124;(^&#124;senator &#124;representative )langevin&#124;langevin, jim&#124;langevin, james&#124;langevin james&#124;langevin, j&#124;representative langevin&#124;j r langevin | james r langevin | 3 | 20136 |
| HON. JIM COSTA;Mr. COSTA | jim costa&#124;costa&#124;james costa&#124;(^&#124;senator &#124;representative )costa&#124;costa, james&#124;costa, jim&#124;costa jim&#124;costa, j&#124;representative costa/td\> | jim costa | 4 | 20501 |
| HON. SAM GRAVES;Mr. GRAVES | samuel graves&#124;graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s&#124;representative graves/td\> | sam graves | 5 | 20124 |

Explanation: - `data`: the text dataset to search. - `col_name`: which
column contains the text. - `regex_table`: the lookup table of
patterns. - `return_cols`: columns from data to include in the result. -
`regex_return_cols`: additional columns from the pattern table to
attach. Each row in the output corresponds to a detected match, and
includes both the original text and the matching pattern. —

## Advanced Usage

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
can also filter data by date, remove acronyms (all-uppercase patterns
with 2+ characters), and select specific output columns. This is useful
for more controlled extraction.

Explanation: - `date_col`, date_start, date_end: filter rows by date. -
`remove_acronyms`: skip patterns like “NASA” or “USA”. You can combine
these filters with any subset of columns for flexible outputs. —

### How the Matching Works

Internally,
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
processes each row of text against the regex patterns in order:

1.  Start with all text rows.
2.  Check each regex pattern against unmatched rows.
3.  When a match is found, remove that row from further checks.
4.  Continue until all patterns have been applied.

This approach improves performance on large datasets because rows stop
being checked once a match is found.

### Summary

- `regextable` is a tool for extracting data from text.
- Use the included datasets to get started or supply your own lookup
  tables.
- [`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
  by default handles text cleaning and efficient matching.
- Optional parameters allow advanced control over filtering and output.
