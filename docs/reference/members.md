# members dataset

Lookup table of member names and metadata for regex matching.

## Format

A tibble with 9 columns:

- congress:

  Congress number (numeric)

- chamber:

  Chamber (House/President/Senate)

- bioname:

  Full bio name of the member

- pattern:

  Regex pattern to match this member's name

- icpsr:

  Numeric ICPSR identifier

- state_abbrev:

  Two-letter state abbreviation

- district_code:

  District number (0 for President)

- first_name:

  First name of the member

- last_name:

  Last name of the member

## Source

Generated for the `regextable` package.
