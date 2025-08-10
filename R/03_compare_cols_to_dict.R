#' Compare REDCap Data Columns to Data Dictionary
#'
#' Compares the column names of a dataset against the variable names
#' specified in a REDCap data dictionary. By default,
#' it loads an online dictionary in the RAGE redcap repository, or as a fallback, 
#' an internal dictionary included with the package, but users can specify
#' a different dictionary file via the `dictUrl` argument.
#'
#' Any columns found in the dictionary but missing from the dataset will be added as blank (`NA`) columns.
#' The function also reports any mismatches between the dataset and the dictionary.
#'
#' @param dayta A data frame or tibble representing your dataset (e.g., from REDCap export).
#' @param dictUrl A URL to the data dictionary CSV file. Defaults to GitHub raw link.
#' @param fallbackPath Local fallback path, \code{system.file()}.
#'
#' @return A data frame that includes all columns defined in the dictionary.
#' Any missing columns originally absent from the dataset will be added with `NA` values.
#'
#' @details
#' Useful for validating and aligning datasets with a REDCap project structure before import,
#' recoding, or further processing.
#'
#' @examples
#'
#' # Use the default dictionary bundled with the package
#' \dontrun{
#' updated_data <- compare_cols_to_dict(my_data)
#'
#' # Or use a custom REDCap dictionary
#' updated_data <- compare_cols_to_dict(my_data, "custom_dictionary.csv")
#'}
#' @export
compare_cols_to_dict <- function(dayta, dictUrl = "https://raw.githubusercontent.com/RAGE-toolkit/rage-redcap/main/data_dictionaries/RAGEredcap_DataDictionary.csv",
                                 fallbackPath = system.file("extdata", "RABVlab_DataDictionary.csv", package = "rabvRedcapProcessing")) {
  # Try to read from GitHub or fall back to the local file
  data_dict <- tryCatch({
    read.csv(dictUrl, stringsAsFactors = FALSE)
  }, error = function(e) {
    warning("Failed to download from GitHub, using fallback system file.")
    read.csv(fallbackPath, stringsAsFactors = FALSE)
  })
  
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
