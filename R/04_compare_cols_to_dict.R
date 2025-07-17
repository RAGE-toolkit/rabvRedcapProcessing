#' Compare REDCap Data Columns to Dictionary
#'
#' Compares the columns in a data file to those in a REDCap data dictionary.
#' Reports missing columns in either the file or the dictionary. If dictionary fields are missing
#' from the file, they are added to the dataset with `NA` values.
#'
#' @param dayta A data frame or tibble containing the uploaded dataset (e.g., from a REDCap export).
#' @param dictPath File path to the REDCap data dictionary (CSV format).
#'
#' @return A data frame with any missing dictionary fields added (as `NA` columns).
#'
#' @details
#' This function is useful for harmonizing datasets with their corresponding metadata dictionary,
#' especially when preparing data for REDCap or ensuring all expected variables are present before analysis.
#'
#' @examples
#' \dontrun{
#' updated_data <- compare_cols_to_dict(my_data, "REDCap_DataDictionary.csv")
#' }
#'
#' @export
compare_cols_to_dict <- function(dayta, dictPath) {

  # Load the REDCap dictionary
  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)

  # Column names
  file_cols <- names(dayta)
  dict_cols <- data_dict$`Variable...Field.Name`

  # Compare
  missing_in_dict <- setdiff(file_cols, dict_cols)
  missing_in_file <- setdiff(dict_cols, file_cols)

  # Print results
  if (length(missing_in_dict) > 0) {
    message("ℹ️ Columns in the file but NOT in the dictionary:\n- ", paste(missing_in_dict, collapse = ", "))
  } else {
    message("✅ All file columns are found in the dictionary.")
  }

  if (length(missing_in_file) > 0) {
    message("⚠️ Columns in the dictionary but NOT in the file:\n- ", paste(missing_in_file, collapse = ", "))
    message("🛠️ These columns will be added to the dataset with blank (NA) values.")

    # Add missing columns with NA
    for (col in missing_in_file) {
      dayta[[col]] <- NA
    }
  } else {
    message("✅ All dictionary fields are found in the file.")
  }

  return(dayta)
}
