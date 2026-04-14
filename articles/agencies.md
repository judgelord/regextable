# Agencies Regex Table

### Introduction

This vignette demonstrates how to extract sub-agency names from texts
using a regex lookup table that includes agencies, sub-agency names,
sections, and departments. The
[`regextable::extract()`](https://judgelord.github.io/regextable/reference/extract.md)
function provides a consistent workflow for identifying sub-agency names
across different texts.

Install and load the package:

``` r
library(regextable)
library(kableExtra)
library(googledrive)
```

### Agencies Data File

The `agencies_by_section` table contains a sample of agencies, including
their sub-agencies, acronyms, and reference sources used for matching
and standardization.

``` r
googledrive::drive_deauth()
googledrive::drive_download(
  googledrive::as_id("1O51ItAquJ4ErmepNXBU9ZCQVXc4npVPN"),
  path = "agencies_by_section.rda",
  overwrite = TRUE
)
load("agencies_by_section.rda")
kable(head(agencies_by_section))
```

| section | department | agency | subagency_name | subagency_acronym |
|:---|:---|:---|:---|:---|
| WHITE HOUSE OFFICE | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | WHITE HOUSE OFFICE | NA |
| CHIEF OF STAFF | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | CHIEF OF STAFF | NA |
| DEPUTY CHIEFS OF STAFF | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | DEPUTY CHIEFS OF STAFF | NA |
| PRINCIPAL DEPUTY CHIEFS OF STAFF | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | DEPUTY CHIEFS OF STAFF | NA |
| SENIOR ADVISERS | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | SENIOR ADVISERS | NA |
| OFFICE OF WHITE HOUSE COUNSEL | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | OFFICE OF WHITE HOUSE COUNSEL | NA |

### Body Data Files

The `body_parsed` dataset contains text sections along with associated
organizational metadata. Each row includes the full text, the section
and department it belongs to, the agency and sub-agency names,
sub-agency acronyms, and any detected mentions of agencies or acronyms.

``` r
googledrive::drive_download(
  googledrive::as_id("1Dvu0VAOWrgiqYX5SPnv_uw7QtqvHjtUw"),
  path = "body_parsed.rda",
  overwrite = TRUE
)
load("body_parsed.rda")
kable(head(body_parsed))
```

| text | section | department | agency | subagency_name | subagency_acronym | agencies_mentioned | acronyms_mentioned |
|:---|:---|:---|:---|:---|:---|:---|:---|
| Section One | NA | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | POLICY COORDINATING COMMITTEE | PCC | NULL | NULL |
| Section One | NA | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | NATIONAL SECURITY COUNCIL | NSC | NULL | NULL |
| Section One | NA | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | DOMESTIC POLICY COUNCIL | DPC | NULL | NULL |
| Section One | NA | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | COUNCIL ON ENVIRONMENTAL QUALITY | NEPA | NULL | NULL |
| Section One | NA | DEPARTMENT OF LABOR | DOL | EQUAL EMPLOYMENT OPPORTUNITY COMMISSION | EEOC | NULL | NULL |
| WHITE HOUSE OFFICE | WHITE HOUSE OFFICE | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | WHITE HOUSE OFFICE | NA | NULL | NULL |

### Extracting Sub-Agency Names from Body Texts

This example demonstrates how to search the `text` column of the
`body_parsed` dataset using patterns from the `subagency_name` column of
the `agencies_by_section` regex table.

By setting `use_ner = TRUE`, the
[`extract()`](https://judgelord.github.io/regextable/reference/extract.md)
function performs Named Entity Recognition (NER) to validate that the
regex matches actually correspond to organizational entities in the
`text`. The final output returns the matched names, retains the `text`
and `department` columns from the original data, and attaches the
corresponding `agency` metadata from the lookup table.

``` r
spacyr::spacy_initialize()

agencies_df <- extract(
  data = body_parsed,
  col_name = "text",
  regex_table = agencies_by_section,
  pattern_col = "subagency_name",
  data_return_cols = c("text", "department"),
  regex_return_cols = c("agency"),
  use_ner = TRUE
)
kable(head(agencies_df))
```

| row_id | text | department | agency | pattern | match |
|---:|:---|:---|:---|:---|:---|
| 11 | Since the inaugural Administration of the late 18th century, citizens have chosen to devote both their time and their talent to defending and strengthening our nation by serving at the pleasure of the President. Their shared patriotic endeavor has proven to be a noble one, not least because the jobs in what is now known as the White House Office (WHO) are among the most demanding in all of government. | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | WHITE HOUSE OFFICE | White House Office |
| 16 | The Chief of Staff’s first managerial task is to establish an organizational chart for the WHO. It should be simple and contain clear lines of authority and responsibility to avoid conflicts. It should also identify specific points of contact for each element of the government outside of the White House. These contacts should include the White House Liaisons who are selected by the Office of Presidential Personnel (PPO). | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | OFFICE OF PRESIDENTIAL PERSONNEL | Office of Presidential Personnel |
| 18 | \* The National Economic Council (NEC); | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | NATIONAL ECONOMIC COUNCIL | National Economic Council |
| 19 | \* The Domestic Policy Council (DPC); and | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | DOMESTIC POLICY COUNCIL | Domestic Policy Council |
| 20 | \* The National Security Council (NSC). | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | NATIONAL SECURITY COUNCIL | National Security Council |
| 21 | The President is briefed on all of his policy priorities by his Cabinet and senior staff as directed by the chief. The chief—along with senior WHO staff—maps out the issues and themes that will be covered daily and weekly. The chief then works with the policy councils, the Cabinet, and the Office of Communications and Office of Legislative Affairs (OLA) to sequence and execute the rollout of policies and announcements. White House Counsel and senior advisers and senior counselors are also intimately involved. | EXECUTIVE OFFICE OF THE PRESIDENT | EOP | OFFICE OF COMMUNICATIONS | Office of Communications |
