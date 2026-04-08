# regextable

### Introduction

The `regextable` package extracts regex-based pattern matches from a
data frame or character vector using a pattern lookup table. For each
input row, all matching patterns are returned, along with the matched
substring, an internal row identifier, and additional columns specified
in `data_return_cols` and `regex_return_cols`. Optional metadata from
the pattern table can also be included. Multiple rows may be returned
for a single text if it matches multiple patterns.

The function also supports additional parameters such as `typo_table`,
`do_clean_text`, `unique_match`, `verbose`, `cl`, and optional Named
Entity Recognition validation via `use_ner`. These can be used to
control text cleaning, optimize performance, show progress messages, or
speed up processing on large datasets.

Install and load the package:

``` r
library(regextable)
library(kableExtra)
```

### Example Data

For demonstration, two included datasets are used: - `members`: A lookup
table of regex patterns for members of Congress. - `cr2007_03_01`: A
sample text dataset from the Congressional Record.

``` r
data("members")
kable(head(members))
```

| chamber | congress | bioname | pattern | icpsr | state | state_abbrev | district_code | bioguide_id | first_name | last_name |
|:---|---:|:---|:---|---:|---:|:---|---:|:---|:---|:---|
| President | 107 | BUSH, George Walker | george bush&#124;george walker bush&#124;\bg bush&#124;george w bush&#124;\bna bush&#124;(^&#124;senator &#124;representative )bush\b&#124;bush, george&#124;bush george&#124;bush, g\b&#124;president bush\b&#124;g w bush | 99910 | NA | USA | 0 | NA | George | BUSH |
| House | 107 | CALLAHAN, Herbert Leon (Sonny) | herbert callahan&#124;herbert leon callahan&#124;\bh callahan&#124;herbert l callahan&#124;sonny callahan&#124;sonny leon callahan&#124;sonny l callahan&#124;\bs callahan&#124;(^&#124;senator &#124;representative )callahan\b&#124;callahan, sonny&#124;callahan, herbert&#124;callahan herbert&#124;callahan, h\b&#124;callahan, s\b&#124;representative callahan\b&#124;h l callahan | 15090 | 1 | AL | 1 | C000052 | Herbert | CALLAHAN |
| House | 107 | CRAMER, Robert E. (Bud), Jr. | robert cramer&#124;robert e cramer&#124;\br cramer&#124;bud cramer&#124;bud e cramer&#124;\bb cramer&#124;(^&#124;senator &#124;representative )cramer\b&#124;cramer, bud&#124;cramer, robert&#124;cramer robert&#124;cramer, r\b&#124;cramer, b\b&#124;representative cramer\b&#124;r e cramer | 29100 | 1 | AL | 5 | C000868 | Robert | CRAMER |
| House | 107 | EVERETT, Robert Terry | robert everett&#124;robert terry everett&#124;\br everett&#124;robert t everett&#124;terry everett&#124;terry terry everett&#124;terry t everett&#124;\bt everett&#124;(^&#124;senator &#124;representative )everett\b.{1,4}al&#124;everett, terry&#124;everett, robert&#124;everett robert&#124;everett, r\b&#124;everett, t\b&#124;representative everett\b.{1,4}al&#124;r t everett | 29300 | 1 | AL | 2 | E000268 | Robert | EVERETT |
| House | 107 | BACHUS, Spencer T., III | spencer bachus&#124;spencer t bachus&#124;\bs bachus&#124;\bna bachus&#124;(^&#124;senator &#124;representative )bachus\b&#124;bachus, spencer&#124;bachus spencer&#124;bachus, s\b&#124;representative bachus\b&#124;s t bachus | 29301 | 1 | AL | 6 | B000013 | Spencer | BACHUS |
| House | 107 | HILLIARD, Earl Frederick | earl hilliard&#124;earl frederick hilliard&#124;\be hilliard&#124;earl f hilliard&#124;\bna hilliard&#124;(^&#124;senator &#124;representative )hilliard\b&#124;hilliard, earl&#124;hilliard earl&#124;hilliard, e\b&#124;representative hilliard\b&#124;e f hilliard | 29302 | 1 | AL | 7 | H000621 | Earl | HILLIARD |

``` r

data("cr2007_03_01")
kable(head(cr2007_03_01))
```

| date | text | header | url |
|:---|:---|:---|:---|
| 2007-03-01 | HON. SAM GRAVES;Mr. GRAVES | RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-2 |
| 2007-03-01 | HON. MARK UDALL;Mr. UDALL | INTRODUCING A CONCURRENT RESOLUTION HONORING THE 50TH ANNIVERSARY OF THE INTERNATIONAL GEOPHYSICAL YEAR (IGY); Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-3 |
| 2007-03-01 | HON. JAMES R. LANGEVIN;Mr. LANGEVIN | BIOSURVEILLANCE ENHANCEMENT ACT OF 2007; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-4 |
| 2007-03-01 | HON. JIM COSTA;Mr. COSTA | A TRIBUTE TO THE LIFE OF MRS. VERNA DUTY; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-5 |
| 2007-03-01 | HON. SAM GRAVES;Mr. GRAVES | RECOGNIZING JARRETT MUCK FOR ACHIEVING THE RANK OF EAGLE SCOUT | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-1 |
| 2007-03-01 | HON. SANFORD D. BISHOP;Mr. BISHOP | IN HONOR OF SYNOVUS BEING NAMED ONE OF THE BEST COMPANIES IN AMERICA; Congressional Record Vol. 153, No. 35 | https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E432-2 |

### Text Cleaning

By default,
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
performs basic text cleaning to improve pattern matching. It converts
text to lowercase, removes specific punctuation (`+`, `—`, `!`, `?`,
`:`, `;`), replaces line breaks, tabs, periods, and dashes with spaces,
and normalizes commas and excess whitespace. This can be disabled by
setting `do_clean_text = FALSE`. Additionally, the `typo_table`
parameter allows users to specify common misspellings and their
corrections. When provided, matches are performed on the corrected text
rather than the original text.

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
  col_name = "text",
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
| 5 | HON. SAM GRAVES;Mr. GRAVES | 20124 | samuel graves&#124;\bs graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves\b&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s\b&#124;representative graves\b | SAM GRAVES |
| 6 | HON. SANFORD D. BISHOP;Mr. BISHOP | 29339 | sanford bishop&#124;sanford dixon bishop&#124;\bs bishop&#124;sanford d bishop&#124;\bna bishop&#124;(^&#124;senator &#124;representative )bishop\b.{1,4}ga&#124;bishop, sanford&#124;bishop sanford&#124;bishop, s\b&#124;representative bishop\b.{1,4}ga&#124;s d bishop | sanford d bishop |
| 7 | HON. EDOLPHUS TOWNS;Mr. TOWNS | 15072 | edolphus towns&#124;\be towns&#124;ed towns&#124;(^&#124;senator &#124;representative )towns\b&#124;towns, ed&#124;towns, edolphus&#124;towns edolphus&#124;towns, e\b&#124;representative towns\b | EDOLPHUS TOWNS |

Function Arguments: - `data`: The text dataset to search. - `col_name`:
Which column contains the text (defaults to `"text"`). Note: If a simple
character vector is passed instead of a data frame, it is internally
converted, and this argument is ignored. - `regex_table`: The lookup
table of patterns. - `data_return_cols`: Additional columns from `data`
to include in the result. - `regex_return_cols`: Additional columns from
the pattern table to attach.

Each row in the output corresponds to a detected match, and includes
both the original text and the matching pattern.

------------------------------------------------------------------------

### Advanced Usage

By default,
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
evaluates every pattern against every text entry. If it is known that
each row contains at most one match, setting `unique_match = TRUE`
utilizes a faster algorithm that stops searching a row once the first
match is found. This improves execution speed on large datasets.

``` r
result_advanced <- extract(
  data = cr2007_03_01,
  regex_table = members,
  unique_match = TRUE,
  date_col = "date",
  date_start = "2007-01-01",
  date_end = "2007-12-31",
  remove_acronyms = TRUE,
  data_return_cols = c("text"),
  regex_return_cols = c("icpsr")
)

kable(head(result_advanced))
```

| row_id | text | icpsr | pattern | match |
|---:|:---|---:|:---|:---|
| 1 | HON. SAM GRAVES;Mr. GRAVES | 20124 | samuel graves&#124;\bs graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves\b&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s\b&#124;representative graves\b | SAM GRAVES |
| 2 | HON. MARK UDALL;Mr. UDALL | 29906 | mark udall&#124;\bm udall&#124;mark e udall&#124;\bna udall&#124;(^&#124;senator &#124;representative )udall\b.{1,4}co&#124;udall, mark&#124;udall mark&#124;udall, m\b&#124;representative udall\b.{1,4}co&#124;m e udall | MARK UDALL |
| 3 | HON. JAMES R. LANGEVIN;Mr. LANGEVIN | 20136 | james langevin&#124;\bj langevin&#124;james r langevin&#124;jim langevin&#124;jim r langevin&#124;(^&#124;senator &#124;representative )langevin\b&#124;langevin, jim&#124;langevin, james&#124;langevin james&#124;langevin, j\b&#124;representative langevin\b&#124;j r langevin | james r langevin |
| 5 | HON. SAM GRAVES;Mr. GRAVES | 20124 | samuel graves&#124;\bs graves&#124;sam graves&#124;(^&#124;senator &#124;representative )graves\b&#124;graves, sam&#124;graves, samuel&#124;graves samuel&#124;graves, s\b&#124;representative graves\b | SAM GRAVES |
| 6 | HON. SANFORD D. BISHOP;Mr. BISHOP | 29339 | sanford bishop&#124;sanford dixon bishop&#124;\bs bishop&#124;sanford d bishop&#124;\bna bishop&#124;(^&#124;senator &#124;representative )bishop\b.{1,4}ga&#124;bishop, sanford&#124;bishop sanford&#124;bishop, s\b&#124;representative bishop\b.{1,4}ga&#124;s d bishop | sanford d bishop |
| 7 | HON. EDOLPHUS TOWNS;Mr. TOWNS | 15072 | edolphus towns&#124;\be towns&#124;ed towns&#124;(^&#124;senator &#124;representative )towns\b&#124;towns, ed&#124;towns, edolphus&#124;towns edolphus&#124;towns, e\b&#124;representative towns\b | EDOLPHUS TOWNS |

Function Arguments: - `unique_match`: If TRUE, utilizes a faster
algorithm that stops searching a row after the first match. -
`date_col`, `date_start`, `date_end`: Filter rows by date before
matching. - `remove_acronyms`: Skip patterns consisting entirely of
uppercase letters (e.g., “NASA” or “USA”).

## These filters can be combined with any subset of columns for flexible outputs.

### Named Entity Recognition (NER) Validation

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
optionally supports validation using Named Entity Recognition (NER).
When `use_ner = TRUE`, the function uses the `spacyr` package to confirm
that regex matches correspond to actual named entities in the text.

Function Arguments: - `use_ner`: Logical; if `TRUE`, validates matches
using `spacyr` Named Entity Recognition. - `ner_entity_types`: Character
vector specifying which entity types to retain. For example, `"ORG"`
keeps only organization entities.

Example:

``` r
spacyr::spacy_initialize()

result_ner <- regextable::extract(
  data = cr2007_03_01,
  regex_table = members,
  use_ner = TRUE,
  ner_entity_types = c("PERSON"),
  data_return_cols = "text",
  regex_return_cols = "icpsr"
)
```

### Parallel Matching

[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
supports parallel processing via the `cl` parameter, which is
recommended for large datasets or extensive lookup tables.

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

- `regextable` is a tool for extracting data from text using lookup
  tables.
- [`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
  handles text cleaning and efficient matching by default.
- Advanced performance parameters, such as `unique_match` and `cl`,
  allow for significant speed improvements on large text.
- Optional parameters allow advanced control over filtering, NER
  validation, and output structure.
