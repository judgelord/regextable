# regextable

### Introduction

`regextable` extracts regex-based pattern matches from a data frame or
character vector using a pattern lookup table. For each input row, all
matching patterns are returned, along with the matched substring, an
internal row identifier, and additional columns specified in
`data_return_cols` and `regex_return_cols`. Optional metadata from the
pattern table can also be included. Multiple rows may be returned for a
single text if it matches multiple patterns.

The function also supports additional parameters such as
`do_clean_text`, `unique_match`, `verbose`, and `cl`. These can be used
to control text cleaning, limit matches per row, show progress messages,
or speed up processing on large datasets.

Install and load the package:

``` r
library(regextable)
library(kableExtra)
```

### Data

For demonstration, we use two included datasets:

- `members`: A lookup table of regex patterns for member names.
- `cr2007_03_01`: A sample text dataset to search.

``` r
data("members")
kable(members)
```

| congress | chamber | bioname | pattern | icpsr | state_abbrev | district_code | first_name | last_name |
|---:|:---|:---|:---|---:|:---|---:|:---|:---|
| 110 | President | BUSH, George Walker | george bush&#124;george walker bush&#124;\bg bush&#124;george w bush&#124;\bna bush&#124;(^&#124;senator &#124;representative )bush\b&#124;bush, george&#124;bush george&#124;bush, g\b&#124;president bush\b&#124;g w bush | 99910 | USA | 0 | George | BUSH |
| 110 | House | BONNER, Jr., Josiah Robins (Jo) | josiah bonner&#124;josiah josiah robins bonner&#124;\bj bonner&#124;josiah j bonner&#124;jo bonner&#124;jo josiah robins bonner&#124;jo j bonner&#124;(^&#124;senator &#124;representative )bonner\b&#124;bonner, jo&#124;bonner, josiah&#124;bonner josiah&#124;bonner, j\b&#124;representative bonner\b&#124;j j bonner | 20300 | AL | 1 | Josiah | BONNER |
| 110 | House | ROGERS, Mike Dennis | mike rogers&#124;mike dennis rogers&#124;\bm rogers.{1,4}al&#124;mike d rogers&#124;michael rogers&#124;michael dennis rogers&#124;michael d rogers&#124;(^&#124;senator &#124;representative )rogers\b.{1,4}al&#124;rogers, michael&#124;rogers, mike&#124;rogers mike&#124;representative rogers\b.{1,4}al&#124;m d rogers | 20301 | AL | 3 | Mike | ROGERS |
| 110 | House | DAVIS, Artur | artur davis&#124;\ba davis&#124;(^&#124;senator &#124;representative )davis\b.{1,4}al&#124;davis, artur&#124;davis artur&#124;davis, a\b&#124;representative davis\b.{1,4}al | 20302 | AL | 7 | Artur | DAVIS |
| 110 | House | CRAMER, Robert E. (Bud), Jr. | robert cramer&#124;robert e cramer&#124;\br cramer&#124;bud cramer&#124;bud e cramer&#124;\bb cramer&#124;(^&#124;senator &#124;representative )cramer\b&#124;cramer, bud&#124;cramer, robert&#124;cramer robert&#124;cramer, r\b&#124;cramer, b\b&#124;representative cramer\b&#124;r e cramer | 29100 | AL | 5 | Robert | CRAMER |

``` r

data("cr2007_03_01")
kable(cr2007_03_01)
```

| date | text | header | url |
|:---|:---|:---|:---|
| 2007-03-01 | HON. SAM GRAVES;Mr. GRAVES | RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-2 |
| 2007-03-01 | HON. MARK UDALL;Mr. UDALL | INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH ANNIVERSARY OF THE INTERNATIONAL GEOPHYSICAL YEAR (IGY); Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-3 |
| 2007-03-01 | HON. JAMES R. LANGEVIN;Mr. LANGEVIN | BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-4 |
| 2007-03-01 | HON. JIM COSTA;Mr. COSTA | A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-5 |
| 2007-03-01 | HON. SAM GRAVES;Mr. GRAVES | RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-1 |

### Text Cleaning

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
cleans text by default, but can be disabled by setting the parameter
`do_clean_text` to false. Cleaning standardizes spacing, punctuation,
and capitalization, which helps regex pattern matching.

Example of
[`clean_text()`](https://judgelord.github.io/regextable/reference/clean_text.md):

``` r
text <- "  HELLO---WORLD  "
clean_text(text)
#> [1] "hello world"
```

### Basic Extraction

The simplest use of
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md):

``` r
result <- regextable::extract(
  data = cr2007_03_01,
  regex_table = members,
  data_return_cols = c("text"),
  regex_return_cols = c("icpsr")
)

kable(head(result))
```

| row_id | text | icpsr | pattern | match |
|---:|:---|---:|:---|:---|
| 1 | HON. SAM GRAVES;Mr. GRAVES | 20124 | samuel graves&#124;\bs graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves\b&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s\b&#124;representative graves\b | SAM GRAVES |
| 2 | HON. MARK UDALL;Mr. UDALL | 29906 | mark udall&#124;\bm udall&#124;mark e udall&#124;\bna udall&#124;(^&#124;senator &#124;representative )udall\b.{1,4}co&#124;udall, mark&#124;udall mark&#124;udall, m\b&#124;representative udall\b.{1,4}co&#124;m e udall | MARK UDALL |
| 3 | HON. JAMES R. LANGEVIN;Mr. LANGEVIN | 20136 | james langevin&#124;\bj langevin&#124;james r langevin&#124;jim langevin&#124;jim r langevin&#124;(^&#124;senator &#124;representative )langevin\b&#124;langevin, jim&#124;langevin, james&#124;langevin james&#124;langevin, j\b&#124;representative langevin\b&#124;j r langevin | james r langevin |
| 4 | HON. JIM COSTA;Mr. COSTA | 20501 | jim costa&#124;\bj costa&#124;james costa&#124;(^&#124;senator &#124;representative )costa\b&#124;costa, james&#124;costa, jim&#124;costa jim&#124;costa, j\b&#124;representative costa\b | JIM COSTA |
| 5 | HON. SAM GRAVES;Mr. GRAVES | 20124 | samuel graves&#124;\bs graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves\b&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s\b&#124;representative graves\b | SAM GRAVES |

Explanation: - `data`: the text dataset to search. - `col_name`: which
column contains the text. - `regex_table`: the lookup table of
patterns. - `data_return_cols`: additional columns from `data` to
include in the result. - `regex_return_cols`: additional columns from
the pattern table to attach. Each row in the output corresponds to a
detected match, and includes both the original text and the matching
pattern. —

### Advanced Usage

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
can also filter data by date, remove acronyms (all-uppercase patterns
with 2+ characters), and select specific output columns. This is useful
for more controlled extraction.

Explanation: - `date_col`, `date_start`, `date_end`: filter rows by
date. - `remove_acronyms`: skip patterns like “NASA” or “USA”. You can
combine these filters with any subset of columns for flexible outputs. —

### Parallel Matching

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
supports parallel processing via the `cl` parameter:

``` r
library(parallel)
clust <- makeCluster(2)
result_parallel <- regextable::extract(
  data = cr2007_03_01,
  regex_table = members,
  cl = clust,
  data_return_cols = c("text"),
  regex_return_cols = c("icpsr")
)
stopCluster(clust)
kable(head(result_parallel))
```

### Summary

- `regextable` is a tool for extracting data from text.
- Use the included datasets to get started or supply your own lookup
  tables.
- [`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
  by default handles text cleaning and efficient matching.
- Optional parameters allow advanced control over filtering and output.
