#Constants, potentially to be updated by hand
#
#See also: ocr.errors(), typos, members

## Used in cleanFROMcolumn()
common_names <- "Bill|Bobby|Buddy|GT|Buck|Chuck|Hank|Rick|Duke|Randy|Andy"

generational_suffixes <- " Jr\\.| Jr| III| II| Ii| IV| ll| \\(Il\\)|, JR\\."

post_nominal_letters <- " Jr,| CPA,| M\\.D\\.,| MD,| M\\.C\\.,| P\\.E\\.,| Ii,"

state_abbreviations <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                         "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA",
                         "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
                         "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX",
                         "UT", "VT", "VA", "WA", "WV", "WI", "WY",
                         "AS", "DC", "GU", "MP", "PR", "VI", "TT",
                         "USA")
state_names <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
                 "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
                 "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
                 "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
                 "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
                 "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
                 "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
                 "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah",
                 "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin",
                 "Wyoming",
                 "American Samoa", "District of Columbia", "Guam", "Northern Mariana Islands",
                 "Puerto Rico", "Virgin Islands", "Trust Territories",
                 "United States")

