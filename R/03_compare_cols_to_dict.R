#' Compare REDCap Data Columns to Data Dictionary
#'
#' This function compares the column names of a dataset against the variable names
#' specified in a REDCap data dictionary. It reports discrepancies and adds any
#' missing dictionary variables to the dataset as `NA` columns.
#'
#' @param dayta A data frame or tibble representing your dataset (e.g., from REDCap export).
#' @param dictPath A string. Path to the REDCap data dictionary in CSV format.
#'
#' @return A data frame with all columns defined in the dictionary. Any missing columns
#' originally absent from the dataset will be added and filled with `NA`.
#'
#' @details
#' Useful for ensuring consistency between your dataset and a REDCap project structure,
#' especially before importing data or validating fields.
#'
#' @examples
#' \dontrun{
#' updated_data <- compare_cols_to_dict(my_data, "REDCap_DataDictionary.csv")
#' }
#'
#' @importFrom utils read.csv
#' @export
compare_cols_to_dict <- function(dayta, dictPath) {
  # Load dictionary
  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)
  
  # Extract column names
  file_cols <- names(dayta)
  dict_cols <- data_dict$`Variable...Field.Name`
  
  # Compare sets
  missing_in_dict <- setdiff(file_cols, dict_cols)
  missing_in_file <- setdiff(dict_cols, file_cols)
  
  # Report extras in data not in dictionary
  if (length(missing_in_dict) > 0) {
    message("ℹ️ Columns in the file but NOT in the dictionary:\n- ", paste(missing_in_dict, collapse = ", "))
  } else {
    message("✅ All file columns are found in the dictionary.")
  }
  
  # Report and add missing dictionary fields to dataset
  if (length(missing_in_file) > 0) {
    message("⚠️ Columns in the dictionary but NOT in the file:\n- ", paste(missing_in_file, collapse = ", "))
    message("🛠️ These columns will be added to the dataset with blank (NA) values.")
    for (col in missing_in_file) {
      dayta[[col]] <- NA
    }
  } else {
    message("✅ All dictionary fields are present in the file.")
  }
  
  return(dayta)
}
