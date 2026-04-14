# Native American Tribes Regex Table

### Introduction

This vignette demonstrates how to use the `regextable` package to
extract references to Native American tribes from text. It showcases the
core
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
workflow using a lookup table of tribe names and name variants.

Install and load the package:

``` r
library(regextable)
library(kableExtra)
library(googledrive)
```

### Regex Table of Native American Tribes

The following table contains tribe names and regex patterns used for
matching. Each row represents a tribe and includes possible spelling
variations or alternate names used in text.

This lookup table includes the following columns:

- Name
- Strings
- Source
- Website
- Notes
- Type
- Emphasis

``` r
googledrive::drive_deauth()

googledrive::drive_download(
  googledrive::as_id("1_946hi1zXeRvlGWIztrZDKJEcPM2jUY0"),
  path = "tribes_regex.csv",
  overwrite = TRUE
)

tribes_regex <- read.csv("tribes_regex.csv", stringsAsFactors = FALSE)
kable(head(tribes_regex))
```

| Name | Strings | Source | Website | Notes | Type | Emphasis |
|:---|:---|:---|:---|:---|:---|:---|
| Ahahui o Hawaii (at William S. Richardson School of Law) | Ahahui o Hawaii | Comments for Hawaii Rulemaking | http://www2.hawaii.edu/~ahahui/about-ahahui-o-hawaii.htm |  | Center within University | Law |
| American Indian Business Association (University of New Mexico) | American Indian Business Association | https://www.ncai.org/tribal-directory/tribal-organizations | https://aiba.unm.edu/?fbclid=IwAR3d-ys6QaMLfpf_HzVWHUuvDA1FGswcUX9Oh8ZiAizYwn_eNSusQsoOwOY |  | Center within University | Business |
| American Indian Policy Institute (Arizona State University) | American Indian Policy Institute | https://nativeamericatoday.com/political-organizations-and-advocacy-groups/ | https://aipi.asu.edu/ |  | Center within University | Governance/Advocacy |
| Center for Indian Law and Policy (Seattle University) | center for indian law and policy | Unmatched Commenters List | https://law.seattleu.edu/centers-and-institutes/center-for-indian-law-and-policy/ |  | Center within University | Law |
| Center for Indigenous Research, Science, and Technology (Kansas University) | Center for Indigenous Research | Googling other organization | https://ipsr.ku.edu/cfirst/ |  | Center within University | Research |
| Center for Native Peoples and the Environment (State University of New York) | Center for Native Peoples and the Environment | https://biamaps.doi.gov/resourceguide/tribes/index.html | https://www.esf.edu/nativepeoples/index.php |  | Center within University | Environment/Resources |

### Gathering Sample Data

To demonstrate extraction, this vignette collects tribe names from the
National Congress of American Indians (NCAI) Tribal Directory. The
directory provides publicly available information about federally
recognized tribes. The scraping example uses the rvest, dplyr, purrr,
tibble, and stringr packages for HTML parsing and iteration. The code is
included for reference only and is not evaluated in this vignette.

The following code can be run to scrape the live directory directly from
the website:

``` r
max_page <- read_html("https://www.ncai.org/tribal-directory") %>%
  html_elements(".Pagination_numberButton__vLhpm") %>%
  html_text() %>%
  as.numeric() %>%
  max(na.rm = TRUE)

all_pages <- paste0("https://www.ncai.org/tribal-directory/page/", 1:max_page)

tribes_df <- map_df(all_pages, function(url) {
  message("Scraping: ", url)
  html <- read_html(url)
  cards <- html %>% html_elements("article.TribeCard_tribeCard__UJcdx")

  map_df(cards, function(card) {
    tibble(
      Region = card %>% html_element(".TribeCard_regionLabel___OVFL")
        %>% html_text(trim = TRUE)
        %>% str_remove(" Region"),
      Tribe = card %>% html_element("h2") %>% html_text(trim = TRUE),
      Recognition = card %>% html_element(".TribeCard_federal__bQB0g")
        %>% html_text(trim = TRUE),
      District = card %>% html_element(".TribeCard_generic__MLwRU")
        %>% html_text(trim = TRUE)
        %>% str_remove("Congressional District ")
    )
  })
})
```

Live web scraping may take a long time to complete and is sensitive to
changes in website structure. For reproducibility and convenience, a
pre-scraped version of the dataset is available for download at:

[Tribes data
frame](https://drive.google.com/file/d/1vL_dI4SuvnxwIXr40X12uBoGSSDn_xL-/view)

For this example, a smaller sample of the full dataset is used:

``` r
googledrive::drive_download(
  googledrive::as_id("1y4PwIYBdXoW6RmlGUeA9Qk3Josp0P0dl"),
  path = "tribes_df.csv",
  overwrite = TRUE
)

tribes_df <- read.csv("tribes_df.csv", stringsAsFactors = FALSE)
kable(head(tribes_df))
```

| Region | Tribe | Recognition | District |
|:---|:---|:---|:---|
| Southern Plains | Absentee-Shawnee Tribe of Indians of Oklahoma | Federally Recognized | OK-05 |
| Alaska | Agdaagux Tribe of King Cove | Federally Recognized | AK-01 |
| Pacific | Agua Caliente Band of Cahuilla Indians | Federally Recognized | CA-45 |
| Western | Ak-Chin Indian Community | Federally Recognized | AZ-07 |
| Alaska | Akiachak Native Community (IRA) | Federally Recognized | AK-01 |
| Alaska | Akiak Native Community (IRA) | Federally Recognized | AK-01 |

### Extracting Tribe Names from Directory

This example demonstrates how to use
[`regextable::extract()`](https://judgelord.github.io/regextable/reference/extract.md)
to parse and standardize the Native American tribe names found within
the scraped Tribal Directory data (`tribes_df`).

The
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
function searches the `Tribe` column using the regex patterns located in
the `Strings` column of `tribes_regex`. When a match is found, the
function returns the original tribe name along with metadata from the
regex table, such as the source reference.

``` r
tribe_directory_df <- extract(
  data = tribes_df,
  regex_table = tribes_regex,
  col_name = "Tribe",
  pattern_col = "Strings",
  data_return_cols = "Tribe",
  regex_return_cols = "Source"
)

kable(head(tribe_directory_df))
```

| row_id | Tribe | Source | pattern | match |
|---:|:---|:---|:---|:---|
| 1 | Absentee-Shawnee Tribe of Indians of Oklahoma | Federal Register (https://www.federalregister.gov/documents/2023/01/12/2023-00504/indian-entities-recognized-by-and-eligible-to-receive-services-from-the-united-states-bureau-of) | Shawnee Tribe | Shawnee Tribe |
| 1 | Absentee-Shawnee Tribe of Indians of Oklahoma | https://www.werelate.org/wiki/Cherokee_Heritage_Project | Nee Tribe &#124; Nuluti Equani Ehi &#124; Near River Dwellers | nee Tribe |
| 2 | Agdaagux Tribe of King Cove | Federal Register (https://www.federalregister.gov/documents/2023/01/12/2023-00504/indian-entities-recognized-by-and-eligible-to-receive-services-from-the-united-states-bureau-of) | Agdaagux | Agdaagux |
| 3 | Agua Caliente Band of Cahuilla Indians | Federal Register (https://www.federalregister.gov/documents/2023/01/12/2023-00504/indian-entities-recognized-by-and-eligible-to-receive-services-from-the-united-states-bureau-of) | Agua Caliente | Agua Caliente |
| 5 | Akiachak Native Community (IRA) | Federal Register (https://www.federalregister.gov/documents/2023/01/12/2023-00504/indian-entities-recognized-by-and-eligible-to-receive-services-from-the-united-states-bureau-of) | Akiachak | Akiachak |
| 7 | Alabama-Coushatta Tribe of Texas | Federal Register (https://www.federalregister.gov/documents/2023/01/12/2023-00504/indian-entities-recognized-by-and-eligible-to-receive-services-from-the-united-states-bureau-of) | Coushatta Tribe | Coushatta Tribe |
