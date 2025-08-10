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
    
    # Unmatched (including blanks)
    unmatched_all <- unique(original_vals[is.na(matched_vals)])
    unmatched_idx <- is.na(matched_vals)
    blanks        <- unmatched_all[unmatched_all == "" | is.na(unmatched_all)]
    non_blanks    <- unmatched_all[!(unmatched_all == "" | is.na(unmatched_all))]
    
    # Split unmatched into blanks and real mismatches
    blanks <- unmatched_all[unmatched_all == "" | is.na(unmatched_all)]
    non_blanks <- unmatched_all[!(unmatched_all == "" | is.na(unmatched_all))]
    
    if (length(unmatched_all) > 0) {
      if (!warned) {
        message("⚠️ Some values could not be matched to dictionary codes.")
        message("→ Please review these carefully:")
        warned <- TRUE
      }
      
      if (length(non_blanks) > 0) {
        message(glue::glue(" - `{col}`: {paste(non_blanks, collapse = ', ')}"))
      }
      if (length(blanks) > 0) {
        message(glue::glue(" - `{col}`: contains blanks"))
      }
    }
    
    # --- Per-column fallback handling ---------------------------------------
    allowed_labels <- unname(dict)  # the label set for this column
    fallback_candidates <- c("Unknown", "Other", "NA")
    present_fallbacks <- intersect(fallback_candidates, allowed_labels)
    
    
    if (length(present_fallbacks) > 0) {
      # Use first in preference order (Unknown > Other > NA)
      fallback_label <- present_fallbacks[1]
      # Get its code from this column's dict
      fallback_code <- names(dict)[match(fallback_label, dict)]
      
      # Replace any NA (i.e., unmatched) with the fallback code
      n_replaced <- sum(is.na(matched_vals))
      if (n_replaced > 0) {
        matched_vals[is.na(matched_vals)] <- fallback_code
        message(glue::glue("ℹ️ `{col}`: {n_replaced} unmatched value(s) set to fallback '{fallback_label}' (code = {fallback_code})."))
      }
    } else {
      # No fallback available for this column; leave NAs as-is
      if (any(is.na(matched_vals))) {
        message(glue::glue("ℹ️ `{col}` has no fallback label ('Unknown'/'Other'/'NA') in its dictionary; leaving {sum(is.na(matched_vals))} unmatched value(s) as NA."))
      }
    }
    # ------------------------------------------------------------------------
    
    recoded_data[[col]] <- unname(matched_vals)
  }
 
  return(recoded_data)
}


