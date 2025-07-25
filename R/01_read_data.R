#' Read and preprocess REDCap lab data
#'
#' This function reads a CSV file and performs basic preprocessing:
#' - Assigns a `duplicate_id` to repeated `sample_id`s
#' - Parses `ngs_rundate` to Date format using `lubridate::dmy`
#'
#' @param filepath Path to the input CSV file
#'
#' @return A tibble with cleaned and annotated data
#' @export
#'
#' @examples
#' lab_data <- read_data("data/my_lab_records.csv")
read_data <- function(filepath) {
  # Load and preprocess
  dayta <- read.csv(filepath, stringsAsFactors = FALSE) %>%
    dplyr::group_by(sample_id) %>%
    dplyr::mutate(
      duplicate_id = dplyr::row_number(),
      ngs_rundate = lubridate::dmy(ngs_rundate)
    ) %>%
    dplyr::ungroup()

  # Console feedback
  message("✅ Your data contains ", nrow(dayta), " entries.")
  message("🔁 Detected ", sum(duplicated(dayta$sample_id)), " duplicate sample IDs.")

  return(dayta)
}
