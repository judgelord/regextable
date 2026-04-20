# regextable 0.1.2

## New Features
* **Typo Correction:** Added `typo_table`, `typo_from_col`, and `typo_to_col` parameters to `extract()`. Text replacements are applied sequentially prior to pattern matching using strict word boundaries ('\\b').
* **Unique Matching:** Added `unique_match` to stop after the first match per row for faster performance when only one match is expected.
* **Named Entity Recognition (NER):** Added optional NER validation via `spacyr` (`use_ner`). Added the `ner_timing` parameter to control whether validation happens `"after"` regex matching (post-match validation) or `"before"` (restricting regex searches only to pre-extracted entities). Matches are filtered by specified entity types using `ner_entity_types` (e.g., `"ORG"`, `"PERSON"`).

## Data Updates
* Updated `members` and `cr2007_03_01` datasets (filtered to `congress == 107`)

## Documentation & Maintenance
* Added `NEWS.md` for version tracking.
* Updated `roxygen2` documentation.
* Updated vignettes to include NER examples.
* Added a `pkgdown` site for additional vignettes and examples
