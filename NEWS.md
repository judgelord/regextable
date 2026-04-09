# regextable 0.1.2

## New Features
* **Typo Correction:** Added `typo_table`, `typo_from_col`, and `typo_to_col` parameters to `extract()`. Text replacements are applied sequentially prior to pattern matching using strict word boundaries ('\\b'), ensuring automated normalization of text replacements.
* **Unique Matching:** Added `unique_match` to stop after the first match per row for faster performance when only one match is expected.
* **NER Post-Match Validation:** Added optional Named Entity Recognition via `spacyr` (`use_ner`). Matches are retained only if they align with specified entity types (via `ner_entity_types`, e.g., `"ORG"`, `"PERSON"`).

## Data Updates
* Updated `members` and `cr2007_03_01` datasets (filtered to `congress == 107`)

## Documentation & Maintenance
* Added `NEWS.md` for version tracking.
* Updated `roxygen2` documentation.
* Updated vignettes to include NER examples.
* Added a `pkgdown` site for additional vignettes and examples
