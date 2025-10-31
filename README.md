
<!-- README.md is generated from README.Rmd. Please edit that file -->

## legislators: Find legislator names in messy text <img src="man/figures/logo.png" align="right" width="150"/> [![CRAN status](https://www.r-pkg.org/badges/version/legislators)](https://CRAN.R-project.org/package=legislators)

### Installation

    devtools::install_github("judgelord/legislators")

``` r
library(legislators)
```

## Data

This package relies on a dataframe (`members`) of permutations of the
names of members of Congress. This dataframe builds on the basic
structure of voteview.com data, especially the `bioname` field. From
this and other corrections, it constructs a regular expression search
`pattern` and conditions under which this pattern should yield a match
(e.g., when that pattern has a unique match to a member of Congress in a
given Congress). `pattern` differs from Congress to Congress because
some members move from the House to the Senate and because members with
similar names join or leave Congress. Users can customize the provided
`members` data and supply their updated version to
`extractMemberName()`.

``` r
data("members")

head(members)
```

    #> # A tibble: 6 × 9
    #>   congress chamber   bioname                      pattern                                                                                                          icpsr state…¹ distr…² first…³ last_…⁴
    #>      <dbl> <chr>     <chr>                        <chr>                                                                                                            <dbl> <chr>     <dbl> <chr>   <chr>  
    #> 1      117 President TRUMP, Donald John           "donald trump|donald john trump|\\bd trump|donald j trump|don trump|don john trump|don j trump|(^|senator |repr… 99912 USA           0 Donald  TRUMP  
    #> 2      117 President BIDEN, Joseph Robinette, Jr. "joseph biden|joseph robinette biden|\\bj biden|joseph r biden|joe biden|joe robinette biden|joe r biden|(^|sen… 99913 USA           0 Joseph  BIDEN  
    #> 3      117 House     ROGERS, Mike Dennis          "mike rogers|mike dennis rogers|\\bm rogers|mike d rogers|michael rogers|michael dennis rogers|michael d rogers… 20301 AL            3 Mike    ROGERS 
    #> 4      117 House     SEWELL, Terri                "terri sewell|\\bt sewell|terri a sewell|\\bna sewell|(^|senator |representative )sewell\\b|sewell, terri|sewel… 21102 AL            7 Terri   SEWELL 
    #> 5      117 House     BROOKS, Mo                   "mo brooks|\\bm brooks|\\bna brooks|(^|senator |representative )brooks\\b|brooks, mo|brooks mo|brooks, m\\b|rep… 21193 AL            5 Mo      BROOKS 
    #> 6      117 House     PALMER, Gary James           "gary palmer|gary james palmer|\\bg palmer|gary j palmer|\\bna palmer|(^|senator |representative )palmer\\b|pal… 21500 AL            6 Gary    PALMER 
    #> # … with abbreviated variable names ¹​state_abbrev, ²​district_code, ³​first_name, ⁴​last_name

------------------------------------------------------------------------

Before searching the text, several functions clean it and “fix” common
human typos and OCR errors that frustrate matching. These corrections
are currently supplied in the `typos` dataset, and all types of
corrections (cleaning, typos, OCR errors) are optional. Additionally,
users can customize the `typos` dataset and provide it as an argument to
`extractMemberName()`.

``` r
data("typos")

head(typos)
```

    #> # A tibble: 6 × 2
    #>   typos                                                                                                  correct            
    #>   <chr>                                                                                                  <chr>              
    #> 1 ( 0 | 0, )                                                                                             " o "              
    #> 2 aaron( | [a-z]* )s chock($| |,|;)|s chock, aaron                                                       "aaron schock"     
    #> 3 adam( | [a-z]* )(schif|sdxiff)($| |,|;)|(schif|sdxiff), adam                                           "adam schiff"      
    #> 4 adrian( | [a-z]* )espaillat|espaillat, adrian|adriano( | [a-z]* )espaillet($| |,|;)|espaillet, adriano "adriano espaillat"
    #> 5 al( | [a-z]* )fianken($| |,|;)|fianken, al                                                             "al franken"       
    #> 6 (alccc|ateee)( | [a-z]* )hastings|hastings, (alccc|ateee)                                              "alcee hastings"

------------------------------------------------------------------------

# Find U.S. legislator names in messy text with typos and inconsistent name formats

## Basic Usage

The main function, `extractMemberName()`, returns a dataframe of the
names and ICPSR ID numbers of members of Congress in a supplied vector
of text.

> in the future, `extractMemberName()` may default to returning a list
> of dataframes the same length as the supplied data

For example, we can use `extractMemberName()` to detect the names of
members of Congress in the text of the Congressional Record. Let’s start
with text from the Congressional Record from 3/1/2007, scraped and
parsed using methods described
[here](https://judgelord.github.io/congressionalrecord/).

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

``` r
head(cr2007_03_01$url)
```

    #> [1] "https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-2"
    #> [2] "https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-3"
    #> [3] "https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-4"
    #> [4] "https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-5"
    #> [5] "https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E431-1"
    #> [6] "https://www.congress.gov/congressional-record/2007/03/01/extensions-of-remarks-section/article/E432-2"

This is an extremely simple example because the text strings containing
the names of the members of Congress in the `speaker` column are short,
consistently formatted, and do not contain much other text. However,
`extractMemberName()` can also search much longer and messier texts,
including text where names are not consistently formatted or where they
contain common typos introduced by humans or common OCR errors. Indeed,
these functions were developed to identify members of Congress in ugly
text data like
[this](https://judgelord.github.io/corr/corr_pres.html#22).

To better match member names, this function currently requires either:

- a column “congress” (this can be created from a date) or
- a vector of congresses to limit the search to supplied to the
  `congresses` argument

For illustration, I show both options in the example below.

Member names augmented from voteview come with the `legislators`
package, but users can also supply a customized version of these data to
the `members` argument.

### `extractMemberName()`

``` r
# extract legislator names and match to voteview ICPSR numbers
cr <- extractMemberName(data = cr2007_03_01, 
                        col_name = "speaker", # The text strings to search
                        congress = 110,
                        cl = 4 #Use 4 cores (on Mac)
)
```

    #> Fixing typos...
    #> Searching data for members of the 110th congress, n = 154 (123 distinct strings).

``` r
cr
```

    #> # A tibble: 193 × 14
    #>    data_id icpsr bioname                    last_name first_name congress chamber state_abbrev district_code date       speaker                          header                            url   url_txt
    #>      <int> <dbl> <chr>                      <chr>     <chr>         <dbl> <chr>   <chr>                <dbl> <date>     <chr>                            <chr>                             <chr> <chr>  
    #>  1       1 20124 GRAVES, Samuel             GRAVES    Samuel          110 House   MO                       6 2007-03-01 hon sam graves;mr graves         RECOGNIZING JARRETT MUCK FOR ACH… http… https:…
    #>  2       2 29906 UDALL, Mark                UDALL     Mark            110 House   CO                       2 2007-03-01 hon mark udall;mr udall          INTRODUCING A CONCURRENT RESOLUT… http… https:…
    #>  3       3 20136 LANGEVIN, James            LANGEVIN  James           110 House   RI                       2 2007-03-01 hon james r langevin;mr langevin BIOSURVEILLANCE ENHANCEMENT ACT … http… https:…
    #>  4       4 20501 COSTA, Jim                 COSTA     Jim             110 House   CA                      20 2007-03-01 hon jim costa;mr costa           A TRIBUTE TO THE LIFE OF MRS. VE… http… https:…
    #>  5       5 20124 GRAVES, Samuel             GRAVES    Samuel          110 House   MO                       6 2007-03-01 hon sam graves;mr graves         RECOGNIZING JARRETT MUCK FOR ACH… http… https:…
    #>  6       6 29339 BISHOP, Sanford Dixon, Jr. BISHOP    Sanford         110 House   GA                       2 2007-03-01 hon sanford d bishop;mr bishop   IN HONOR OF SYNOVUS BEING NAMED … http… https:…
    #>  7       7 15072 TOWNS, Edolphus            TOWNS     Edolphus        110 House   NY                      10 2007-03-01 hon edolphus towns;mr towns      NEW PUNJAB CHIEF MINISTER URGED … http… https:…
    #>  8       8 29576 DAVIS, Thomas M., III      DAVIS     Thomas          110 House   VA                      11 2007-03-01 hon tom davis;mr tom davis       HONORING THE 30TH ANNIVERSARY OF… http… https:…
    #>  9       9 20124 GRAVES, Samuel             GRAVES    Samuel          110 House   MO                       6 2007-03-01 hon sam graves;mr graves         RECOGNIZING BRIAN PATRICK WESSLI… http… https:…
    #> 10      10 29906 UDALL, Mark                UDALL     Mark            110 House   CO                       2 2007-03-01 hon mark udall;mr udall          INTRODUCTION OF ROYALTY-IN-KIND … http… https:…
    #> # … with 183 more rows

In this example, all observations are in the 110th Congress, so we only
search for members who served in the 110th.

Because `extractMemberName()` links each detected name to ICPSR IDs from
voteview.com, we already have some information, like state and district
for each legislator detected in the text (scroll to the right).

## TODO

### Dynamic data

- [ ] make some kind of version-controlled spreadsheet where users can
  submit additional nicknames, maiden names, etc. to augment the
  voteview data. This is currently done in
  data/make_members/nameCongress.R, but it would not be easy for users
  to edit and then re-make the regex table.
- [ ] make some sort of version-controlled spreadsheet where users can
  submit common typos they find. Currently, typos.R generates typos.rda,
  which is loaded with the package.

### Vignettes

- [ ] Add a vignette using messy OCRed legislator letters to FERC from
  replication data for [“Legislator Advocacy on Behalf of Constituents
  and Corporate Donors”](https://judgelord.github.io/research/ferc/)
- [ ] Add a vignette using [public comment
  data](https://github.com/judgelord/rulemaking) (sparse legislator
  names)

### Functions

- [x] `extractMemberName()` needs options to supply custom typos and
  additions to the main regex table
- [x] correcting OCR errors and typos should be optional in
  `extractMemberName()`
- [ ] integrate with the [`congress`](https://github.com/ippsr/congress)
  and/or [`congressData`](https://github.com/IPPSR/congress) packages.
  For example, we may want a function (`augmentCongress` or
  `augment_legislators`?) to join in identifiers for other datasets on
  ICPSR numbers. Perhaps this is best left to users using the `congress`
  package.
- [ ] Additionally, `committees.R` provides a crosswalk for Stewart
  ICPSR numbers
- [ ] Support dates for congress

### Documentation

- [ ] Document helper functions for `extractMemberName()`
- [x] Document additional functions that help prep text for best
  matching
- [ ] Document example data (including FERC and public comment data for
  new vignettes)
