# Clean Text

Cleans a character vector by converting text to lowercase, removing
selected punctuation (plus signs, em dashes, exclamation points),
normalizing commas, and removing whitespace.

## Usage

``` r
clean_text(text)
```

## Arguments

- text:

  Character vector to clean.

## Value

Cleaned character vector.

## Examples

``` r
clean_text(c("Hello  World!", "This is\tR"))
#> [1] "hello world" "this is r"  
```
