#' Recode Human-Readable Labels to REDCap Dictionary Codes
#'
#' This function maps human-readable values in a dataset back to their corresponding
#' REDCap dictionary codes using a named list of field-specific dictionaries. It is useful
#' when REDCap exports or manually curated data use labels, but the system requires coded values.
#'
#' Only columns that exist in both `dayta` and `dicts` are considered. Any unmatched values
#' (either due to typos, unexpected entries, or blanks) are flagged in the console output.
#'
#' @param dicts A named list of dictionaries (typically from \code{\link{read_and_parse_dict}}),
#'   where each element corresponds to a REDCap field and contains a named character vector of
#'   code-to-label mappings.
#' @param dayta A data frame or tibble with label values (to be converted back to codes).
#'
#' @return A tibble with the same structure as `dayta`, but with dictionary-mapped values
#'   replaced by their corresponding REDCap codes where applicable.
#'
#' @details
#' For each applicable column:
#' - The dictionary is reversed (label → code)
#' - Each label in the data is matched to its code
#' - If labels are not matched (e.g. due to typos or blanks), a warning message is shown
#' - Unmatched values are left as \code{NA} in the output
#'
#' @examples
#' dicts <- list(
#'   fat = c("0" = "Negative", "1" = "Positive"),
#'   sample_buffer = c("0" = "Glycerol-saline", "1" = "RNAlater")
#' )
#'
#' df <- tibble::tibble(
#'   fat = c("Positive", "Negative", "Unknown"),
#'   sample_buffer = c("RNAlater", "Glycerol-saline", "")
#' )
#'
#' recoded <- recode_data(dicts, df)
#' print(recoded)
#'
#' @importFrom glue glue
#' @export
recode_data <- function(dicts, dayta) {
  recoded_data <- dayta
  warned <- FALSE  # flag to print the global warning once
  
  for (col in intersect(names(dicts), names(dayta))) {
    dict <- dicts[[col]]
    label_to_code <- setNames(names(dict), dict)
    
    original_vals <- as.character(dayta[[col]])
    matched_vals <- label_to_code[original_vals]
    
    # Identify unmatched values
    unmatched_all <- unique(original_vals[is.na(matched_vals)])
    
    # Split unmatched into blanks and real mismatches
    blanks <- unmatched_all[unmatched_all == "" | is.na(unmatched_all)]
    non_blanks <- unmatched_all[!(unmatched_all == "" | is.na(unmatched_all))]
    
    if (length(unmatched_all) > 0) {
      if (!warned) {
        message("⚠️ Some values could not be matched to dictionary codes.")
        message("→ Please review and replace these in your data to match allowed dictionary values.")
        warned <- TRUE
      }
      
      if (length(non_blanks) > 0) {
        message(glue::glue(" - `{col}`: {paste(non_blanks, collapse = ', ')}"))
      }
      if (length(blanks) > 0) {
        message(glue::glue(" - `{col}`: contains blanks"))
      }
    }
    
    recoded_data[[col]] <- matched_vals
  }
  
  return(recoded_data)
}


