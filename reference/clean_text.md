# Clean Text

Cleans a character vector by converting to lowercase, removing or
replacing specific punctuation, normalizing commas, and squishing excess
whitespace.

## Usage

``` r
clean_text(text)
```

## Arguments

- text:

  Character vector to clean.

## Value

A cleaned character vector.

## Examples

``` r
clean_text(c("Hello  World!?", "This--is\tR.\nTesting: 1, 2, , 3;"))
#> [1] "hello world"                 "this is r testing 1, 2, , 3"
```
