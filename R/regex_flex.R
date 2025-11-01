#' @title Flexible Regex Application
#' @description Apply user specific flexible regex_table methods
#' @param df Data frame to process
#' @param col_name Name of the column to apply regex transformations to
#' @param regex_table Regex table specifying pattern-replacement pairs
#' @param date_col Name of the date column (default: "date")
#' @param date_start Start date for filtering
#' @param date_end End date for filtering
#' @return Modified data frame
#' @import dplyr
#' @import stringr
#' @export

#Date-based regex application
apply_regextable_date <- function(df, col_name, regex_table, date_col = "date", date_start = NULL, date_end = NULL) {

  #Input validation
  if(!col_name %in% names(df)){ #Checks if column name exists in the data frame
    stop("Column '",col_name,"' not found in data frame")
  }
  if(!date_col %in% names(df)){ #Checks if date column exists in the data frame
    stop("Date column '", date_col, "' not found in data frame")
  }

  #Convert date column to Date type if needed
  if(!inherits(df[[date_col]], "Date")){
    df[[date_col]]<-as.Date(df[[date_col]])
  }

  #Checks if start date is before or equal to end date
  if(!is.null(date_start) && !is.null(date_end) && date_start>date_end){
    stop("date_start must be before or equal to date_end")
  }

  #Identify rows to process
  if (!is.null(date_start) && !is.null(date_end)){
    date_start<-as.Date(date_start)
    date_end<-as.Date(date_end)

    rows_to_process<-df[[date_col]] >= date_start & df[[date_col]] <= date_end
  }

  #Process all rows if no date range specified
  else{
    rows_to_process<-rep(TRUE, nrow(df))
  }

  # Apply regex only to selected rows
  df[[col_name]]<-as.character(df[[col_name]])  #ensure character
  df[[col_name]][rows_to_process]<-apply_regextable(df[[col_name]][rows_to_process], regex_table)

  return(df)
}


#Acronym-based regex application
apply_regextable_acronyms<-function(df, col_name, regex_table, remove_acronyms=TRUE){

  if(!col_name %in% names(df)) stop("Column '", col_name, "' not found in data frame")

  if(remove_acronyms){
    regex_table<-regex_table[!grepl("^[A-Z]{2,}$", regex_table$pattern), ]#keeps only rows with no acronyms
  }

  df[[col_name]]<-as.character(df[[col_name]])
  df[[col_name]]<-apply_regextable(df[[col_name]], regex_table) #only non-acronyms patterns in the table will be applied to the column

  return(df)
}
