#' Compare REDCap Data Columns to Data Dictionary
#'
#' Compares the column names of a dataset against the variable names
#' specified in a REDCap data dictionary. By default, it uses a bundled dictionary
#' included with the package, but users can specify a custom dictionary path via the `dictPath` argument.
#'
#' Any columns found in the dictionary but missing from the dataset will be added as blank (`NA`) columns.
#' The function also reports any mismatches between the dataset and the dictionary.
#'
#' @param dayta A data frame or tibble representing your dataset (e.g., from REDCap export).
#' @param dictPath Path to the REDCap data dictionary (CSV format). Defaults to an internal file included in the package.
#'
#' @return A data frame that includes all columns defined in the dictionary.
#' Any missing columns originally absent from the dataset will be added with `NA` values.
#'
#' @details
#' Useful for validating and aligning datasets with a REDCap project structure before import,
#' recoding, or further processing.
#'
#' @examples
#' # Use the default dictionary bundled with the package
#' updated_data <- compare_cols_to_dict(my_data)
#'
#' # Or use a custom REDCap dictionary
#' updated_data <- compare_cols_to_dict(my_data, "custom_dictionary.csv")
#'
#' @export
compare_cols_to_dict <- function(dayta, dictPath = system.file("extdata", 
                                                               "RABVlab_DataDictionary_redcap2025-08-04.csv", 
                                                               package = "rabvRedcapProcessing")) {
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
