#' Recode label values back to their dictionary codes
#'
#' This function assumes that your data contains human-readable labels
#' and you want to recode them to the corresponding REDCap codes.
#'
#' @param dicts A named list of REDCap dictionaries (code → label)
#' @param dayta A data frame or tibble with columns to recode
#'
#' @return A tibble with recoded columns
#' @export
recode_data <- function(dicts, dayta) {
  recoded_data <- dayta

  for (col in intersect(names(dicts), names(dayta))) {
    dict <- dicts[[col]]

    # Reverse the dictionary: label → code
    label_to_code <- setNames(names(dict), dict)

    # Coerce and match based on lowercase labels
    original_vals <- as.character(dayta[[col]])
    matched_vals <- label_to_code[original_vals]

    # Warn if any unmatched
    if (any(is.na(matched_vals) & !is.na(original_vals))) {
      unmatched <- unique(original_vals[is.na(matched_vals)])
      message(glue::glue("⚠️ Unmatched values in `{col}`: {paste(unmatched, collapse = ', ')}"))
    }

    recoded_data[[col]] <- matched_vals
  }

  return(recoded_data)
}

