#' Extract REDCap Form Column Names from Data Dictionary
#'
#' Parses a REDCap data dictionary (CSV format) to identify which variables belong to the
#' `diagnostic` and `sequencing` REDCap forms. This supports preparation of REDCap repeat
#' instruments for data upload. A default dictionary bundled with the package is used unless a custom path is provided.
#'
#' @param dictPath Path to the REDCap data dictionary (CSV file). Defaults to an internal dictionary bundled with the package.
#'
#' @return A named list with three elements:
#' \describe{
#'   \item{diagnostic_columns}{Character vector of variable names for the diagnostic form.}
#'   \item{sequencing_columns}{Character vector of variable names for the sequencing form, including REDCap repeat metadata.}
#'   \item{all_dict_cols}{Character vector of all variables defined in the dictionary, including REDCap metadata columns.}
#' }
#'
#' @importFrom dplyr filter pull union
#' @importFrom magrittr %>%
#'
#' @export
get_redcap_form_columns <- function(dictPath = system.file("extdata", 
                                                           "RABVlab_DataDictionary_redcap2025-08-04.csv", 
                                                           package = "rabvRedcapProcessing")) {
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
#' Processes cleaned laboratory data and splits it into two REDCap-compatible data frames:
#' one for the `diagnostic` form and another for the `sequencing` form. These are formatted
#' for use with REDCap repeat instruments. The function uses a built-in REDCap dictionary
#' by default, but you may provide a custom dictionary via the `dictPath` argument.
#'
#' @param mydata A data frame containing cleaned lab records. Must include a `sample_id` and `duplicate_id` column.
#' @param dictPath File path to the REDCap data dictionary (CSV format). Defaults to a dictionary bundled with the package.
#' @param access_group A character string specifying the REDCap Data Access Group. Must be one of:
#' `"east_africa"`, `"malawi"`, `"nigeria"`, `"peru"`, or `"philippines"`.
#'
#' @return A named list with two tibbles:
#' \describe{
#'   \item{diagnostic_form}{A tibble ready for REDCap import into the diagnostic form.}
#'   \item{sequencing_form}{A tibble ready for REDCap import into the sequencing form.}
#' }
#'
#' @details
#' Uses \code{\link{get_redcap_form_columns}} to extract form-specific variables.
#' Ensures REDCap repeat instrument fields (`redcap_repeat_instrument`, `redcap_repeat_instance`)
#' are properly set and all required fields are present. Missing fields are filled with `""`
#' as required for REDCap imports.
#'
#' @importFrom dplyr mutate select any_of union across
#' @importFrom tidyr replace_na
#'
#' @export
final_processing <- function(mydata, dictPath = system.file("extdata", 
                                                            "RABVlab_DataDictionary_redcap2025-08-04.csv", 
                                                            package = "rabvRedcapProcessing"),
                             access_group = c("east_africa", "malawi", "nigeria", "peru", "philippines")) {
  # QC check that correct access group is given
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
      redcap_data_access_group = access_group,
      across(everything(), ~replace_na(as.character(.), ""))
    )
  
  sequencing_form <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instrument = "sequencing",
      redcap_data_access_group = access_group
    ) %>%
    dplyr::select(any_of(c("sample_id", sequencing_columns))) %>%
    dplyr::mutate(across(everything(), ~replace_na(as.character(.), "")))
  
  return(list(
    diagnostic_form = diagnostic_form,
    sequencing_form = sequencing_form
  ))
}
