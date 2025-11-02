#' @title Date-based Regex Application
#' @description Apply user specific flexible regex_table methods
#' @param df Data frame to process
#' @param col_name Name of the column to apply regex transformations to
#' @param regex_table Regex table specifying pattern-replacement pairs
#' @param date_col Name of the date column (default: "date")
#' @param date_start Start date for filtering (optional)
#' @param date_end End date for filtering (optional)
#' @return Modified data frame
#' @import dplyr
#' @import stringr
#' @export

apply_regextable_date <- function(df, col_name, regex_table, date_col = "date", date_start = NULL, date_end = NULL) {

  #Input validation
  if(!col_name %in% names(df)) stop("Column '",col_name,"' not found in data frame")
  if(!date_col %in% names(df)) stop("Date column '", date_col, "' not found in data frame")

  #Convert date column to Date type
  df[[date_col]]<-as.Date(df[[date_col]])

  #Identify rows to process
  if(!is.null(date_start) || !is.null(date_end)){
    date_start <- if(!is.null(date_start)) as.Date(date_start) else -Inf
    date_end <- if(!is.null(date_end)) as.Date(date_end) else Inf
    
    if(date_start>date_end){
      stop("date_start must be before or equal to date_end")
    }
    
    rows_to_process <- df[[date_col]] >= date_start & df[[date_col]] <= date_end
  }
  else{
    rows_to_process <- rep(TRUE, nrow(df))
  }

  #apply regextable to any rows that are within the dates
  if(any(rows_to_process)) df[[col_name]][rows_to_process] <- apply_regextable(as.character(df[[col_name]][rows_to_process]), regex_table)
  
  df
}

#' @title Acronym-based Regex Application
#' @description Apply regex transformations with optional acronym filtering
#' @param df Data frame to process
#' @param col_name Name of the column to apply regex transformations to
#' @param regex_table Regex table specifying pattern-replacement pairs
#' @param remove_acronyms Logical, if TRUE removes acronym patterns (default: TRUE)
#' @return Modified data frame
#' @export

apply_regextable_acronyms <- function(df, col_name, regex_table, remove_acronyms=TRUE){

  if(!col_name %in% names(df)) stop("Column '", col_name, "' not found in data frame")
  #keeps only rows with no acronyms
  if(remove_acronyms) regex_table <- regex_table[!grepl("^[A-Z]{2,}$", regex_table$pattern),]

  df[[col_name]] <- as.character(df[[col_name]])
  df[[col_name]] <- apply_regextable(df[[col_name]], regex_table) #only non-acronyms patterns in the table will be applied to the column

  return(df)
}

#' @title Pattern-specific Regex Application
#' @description Apply regex transformations using a specific pattern column from regex_table
#' @param df Data frame to process
#' @param col_name Name of the column to apply regex transformations to
#' @param regex_table Regex table containing multiple pattern columns
#' @param pattern Name of the pattern column to use (default: "pattern")
#' @return Modified data frame
#' @export

apply_regextable_pattern <- function(df, col_name, regex_table, pattern="pattern"){

  #Checks if column name and pattern are found in df and table
  if(!col_name %in% names(df)){
    stop("Column '", col_name, "' not found in data frame")
  }
  if(!pattern %in% names(regex_table)){
    stop("Pattern '", pattern, "' not found in regex table")
  }

  #creates temp_table using chosen pattern column
  temp_table <- data.frame(pattern=regex_table[[pattern]], replacement=regex_table$replacement, stringsAsFactors=FALSE)

  #applies replacement based on the chosen pattern set
  df[[col_name]] <- as.character(df[[col_name]])
  df[[col_name]] <- apply_regextable(df[[col_name]],temp_table)

  return(df)
}
