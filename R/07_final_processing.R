#' Extract REDCap Form Column Names from Data Dictionary
#'
#' Parses a REDCap data dictionary CSV file to identify which variables belong to the
#' diagnostic and sequencing forms. This helps define the expected structure for export
#' into REDCap repeat instruments.
#'
#' @param dictPath A file path to the REDCap data dictionary (CSV format).
#'
#' @return A named list with three elements:
#' \describe{
#'   \item{diagnostic_columns}{A character vector of variable names for the diagnostic form.}
#'   \item{sequencing_columns}{A character vector of variable names for the sequencing form. Includes `sample_id`, `redcap_repeat_instrument`, and `redcap_repeat_instance`.}
#'   \item{all_dict_cols}{A character vector of all variables in the dictionary, including REDCap metadata columns.}
#' }
#'
#' @importFrom dplyr filter pull union
#' @importFrom magrittr %>%
#' 
#' @export
get_redcap_form_columns <- function(dictPath) {
  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)
  
  list(
    diagnostic_columns = data_dict %>%
      dplyr::filter(Form.Name == "diagnostic") %>%
      dplyr::pull(Variable...Field.Name), 
    
    sequencing_columns = data_dict %>%
      dplyr::filter(Form.Name == "sequencing") %>%
      dplyr::pull(Variable...Field.Name) %>%
      union(c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance")),
    
    all_dict_cols = data_dict %>%
      dplyr::pull(Variable...Field.Name) %>%
      union(c("redcap_repeat_instrument", "redcap_repeat_instance"))
  )
}


#' Prepare Diagnostic and Sequencing REDCap Forms
#'
#' This function processes cleaned laboratory data and splits it into two REDCap-ready data frames:
#' one for the `diagnostic` form and one for the `sequencing` form. It assigns REDCap metadata
#' fields like `redcap_repeat_instrument`, `redcap_repeat_instance`, and `redcap_access_group`.
#' It ensures all necessary fields exist based on the data dictionary and fills missing values with empty strings.
#'
#' @param mydata A data frame containing cleaned lab records. Must include a `sample_id` column and a `duplicate_id` column for repeat instance tracking.
#' @param dictPath File path to the REDCap data dictionary (CSV format).
#' @param access_group A string specifying the REDCap Data Access Group (DAG). Must be one of:
#' `"east_africa"`, `"malawi"`, `"nigeria"`, `"peru"`, `"philippines"`.
#'
#' @return A named list with two tibbles:
#' \describe{
#'   \item{diagnostic_form}{A data frame ready for REDCap import into the `diagnostic` repeat instrument.}
#'   \item{sequencing_form}{A data frame ready for REDCap import into the `sequencing` repeat instrument.}
#' }
#'
#' @details
#' This function internally calls \code{\link{get_redcap_form_columns}} to determine which variables belong to each form.
#' It assigns `redcap_repeat_instance` from the `duplicate_id` column, and sets the repeat instrument name accordingly.
#' Blank values are replaced with empty strings, as expected by REDCap for import.
#'
#' @importFrom dplyr mutate select any_of union across
#' @importFrom tidyr replace_na
#' @export
final_processing <- function(mydata, dictPath,
                             access_group = c("east_africa", "malawi", "nigeria", "peru", "philippines")) {
  access_group <- match.arg(access_group)
  
  form_cols <- get_redcap_form_columns(dictPath)
  diagnostic_columns <- form_cols$diagnostic_columns
  sequencing_columns <- form_cols$sequencing_columns
  all_dict_cols <- form_cols$all_dict_cols
  
  mydata <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instance = duplicate_id,
      redcap_repeat_instrument = ""
    ) %>%
    dplyr::select(any_of(c("sample_id", all_dict_cols)))
  
  diagnostic_form <- mydata %>%
    dplyr::select(any_of(c("sample_id", diagnostic_columns))) %>%
    dplyr::mutate(
      redcap_access_group = access_group,
      across(everything(), ~replace_na(as.character(.), ""))
    )
  
  sequencing_form <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instrument = "sequencing",
      redcap_access_group = access_group
    ) %>%
    dplyr::select(any_of(c("sample_id", sequencing_columns))) %>%
    dplyr::mutate(across(everything(), ~replace_na(as.character(.), "")))
  
  return(list(
    diagnostic_form = diagnostic_form,
    sequencing_form = sequencing_form
  ))
}
