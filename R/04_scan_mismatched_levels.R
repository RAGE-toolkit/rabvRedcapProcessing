#' Scan for Mismatched Categorical Values Against REDCap Dictionary
#'
#' Checks whether all values in a specified column of your dataset are present in the REDCap dictionary definitions.
#' Returns (invisibly) any values that are not found in the dictionary and prints a message for review.
#'
#' @param dayta A data frame or tibble containing the dataset to be checked.
#' @param dicts A named list of dictionaries created from the REDCap dictionary (e.g., using `read_and_parse_dict()`),
#'              where each element corresponds to a coded field and maps value labels to codes.
#' @param col_to_check A string indicating the column name in `dayta` to check against the dictionary.
#'
#' @return Invisibly returns a character vector of values not listed in the dictionary for that column.
#'         Also prints messages to console for user feedback.
#'
#' @details This function is helpful for validating categorical variables with predefined coding (e.g., gender, yes/no),
#' ensuring that all observed values match expected dictionary labels. It optionally notifies the user of fallback
#' categories like "Other" or "Unknown" if present in the dictionary.
#'
#' @examples
#' \dontrun{
#' scan_mismatched_levels(my_data, myDicts, "sample_buffer")
#' }
#'
#' @export
scan_mismatched_levels <- function(dayta, dicts, col_to_check) {
  # Check if the column is in the dictionary
  if (!col_to_check %in% names(dicts)) {
    message(glue::glue("⚠️ '{col_to_check}' is not a coded field (i.e., not constrained in the dictionary)."))
    return(invisible(NULL))
  }

  # Extract values from the column
  column_values <- unique(as.character(dayta[[col_to_check]]))

  # Get allowed labels from dict
  allowed_labels <- unname(dicts[[col_to_check]])

  # Identify mismatched values
  not_in_dict <- setdiff(column_values, allowed_labels)

  # Reporting
  if (length(not_in_dict) == 0) {
    message(glue::glue("✅ All values in '{col_to_check}' are valid and match the dictionary."))
  } else {
    message(glue::glue("❌ The following values in '{col_to_check}' are not listed in the dictionary:\n - ",
                       paste(not_in_dict, collapse = ", ")))

    # Check for fallback categories
    if (any(c("Unknown", "Other") %in% allowed_labels)) {
      fallback <- allowed_labels[allowed_labels %in% c("Unknown", "Other")]
      message(glue::glue("ℹ️ These values will be classed as: {paste(fallback, collapse = ' or ')}"))
    }
  }

  invisible(not_in_dict)
}



