#' Extract REDCap Form Column Names from Data Dictionary
#'
#' Parses a REDCap data dictionary (CSV format) to identify which variables belong to the
#' `diagnostic` and `sequencing` REDCap forms. This supports preparation of REDCap repeat
#' instruments for data upload. A default dictionary bundled with the package is used unless a custom path is provided.
#'
#' @param dictUrl A URL to the data dictionary CSV file. Defaults to GitHub raw link.
#' @param fallbackPath Local fallback path, \code{system.file()}.
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
get_redcap_form_columns <- function(
  dictUrl = "https://raw.githubusercontent.com/RAGE-toolkit/rage-redcap/main/data_dictionaries/RAGEredcap_DataDictionary.csv",
  fallbackPath = system.file("extdata", "RABVlab_DataDictionary.csv", package = "rabvRedcapProcessing")
  ) {
  
  # Try to read from GitHub or fall back to the local file
  data_dict <- tryCatch({
    read.csv(dictUrl, stringsAsFactors = FALSE)
  }, error = function(e) {
    warning("Failed to download from GitHub, using fallback system file.")
    read.csv(fallbackPath, stringsAsFactors = FALSE)
  })
  
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

#' Infer REDCap Data Access Group from `country`
#'
#' Maps country names to REDCap Data Access Groups row-by-row.
#' - Kenya, Uganda, Tanzania → "east_africa"
#' - Malawi → "malawi"
#' - Nigeria → "nigeria"
#' - Peru → "peru"
#' - Philippines → "philippines"
#' Unrecognised or missing countries return NA (with a message listing examples).
#'
#' @param country Character vector of country names.
#' @return Character vector of access groups.
#'
#' @examples
#' infer_access_group(c("Kenya","uganda","PERU","Unknown"))
#' # [1] "east_africa" "east_africa" "peru" NA
#'
#' @export
infer_access_group <- function(country) {
  country2 <- tolower(trimws(country))
  
  map <- c(
    "kenya" = "east_africa",
    "uganda" = "east_africa",
    "tanzania" = "east_africa",
    "united republic of tanzania" = "east_africa",
    "malawi" = "malawi",
    "nigeria" = "nigeria",
    "peru" = "peru",
    "philippines" = "philippines"
  )
  
  out <- unname(map[country2])
  
  if (any(is.na(out))) {
    unknowns <- unique(country[is.na(out)])
    message("⚠️ Unrecognised `country`, access group set to NA. Examples: ",
            paste(head(unknowns, 5), collapse = ", "),
            if (length(unknowns) > 5) " …" else "")
  }
  
  out
}

#' Harmonize platform-specific fields based on `ngs_platform`
#'
#' Nanopore → blank illumina_platform
#' Illumina → blank nanopore_platform
#'
#' @param df Data frame with ngs_platform + platform-specific cols
#' @return Data frame with harmonized platform fields
#' @export
harmonize_platform_fields <- function(df) {
  if (!"ngs_platform" %in% names(df)) return(df)

  df %>%
    dplyr::mutate(
      illumina_platform = dplyr::case_when(
        tolower(trimws(ngs_platform)) == "nanopore" ~ "",
        TRUE ~ as.character(illumina_platform)
      ),
      nanopore_platform = dplyr::case_when(
        tolower(trimws(ngs_platform)) == "illumina" ~ "",
        TRUE ~ as.character(nanopore_platform)
      )
    )
}


#' Prepare Diagnostic and Sequencing REDCap Forms
#'
#' Processes cleaned lab data into two REDCap-ready tibbles:
#' `diagnostic_form` and `sequencing_form`. Access group is inferred
#' per row from the `country` column via \code{\link{infer_access_group}}:
#' Kenya/Uganda/Tanzania → "east_africa"; Malawi/Nigeria/Peru/Philippines map to
#' themselves. Unrecognised countries get NA.
#'
#' By default, the function loads the project dictionary from the RAGE GitHub
#' (raw CSV). If that URL is unavailable, it falls back to an internal CSV bundled
#' with the package. You may also provide a custom dictionary URL or file path.
#'
#' @param mydata A data frame with cleaned lab records. Must include `sample_id`,
#'   `duplicate_id`, and `country`.
#' @param dictUrl A URL to the data dictionary CSV file (defaults to RAGE GitHub).
#' @param fallbackPath Local fallback path, typically via \code{system.file()}.
#'
#' @return A named list with:
#' \describe{
#'   \item{diagnostic_form}{Tibble ready for REDCap import into the diagnostic form.}
#'   \item{sequencing_form}{Tibble ready for REDCap import into the sequencing form.}
#' }
#'
#' @details
#' Uses \code{\link{get_redcap_form_columns}} to obtain expected field sets.
#' Ensures repeat instrument fields are present and fills blanks with "" as
#' expected by REDCap imports.
#'
#' @examples
#' \dontrun{
#' processed <- final_processing(mydata = cleaned_data)
#' write.csv(processed$diagnostic_form, "diagnostic_form.csv", row.names = FALSE)
#' write.csv(processed$sequencing_form, "sequencing_form.csv", row.names = FALSE)
#' }
#'
#' @importFrom dplyr mutate select any_of across
#' @importFrom tidyr replace_na
#' @export

final_processing <- function(
    mydata,
    dictUrl = "https://raw.githubusercontent.com/RAGE-toolkit/rage-redcap/main/data_dictionaries/RAGEredcap_DataDictionary.csv",
    fallbackPath = system.file("extdata", "RABVlab_DataDictionary.csv", package = "rabvRedcapProcessing")
) {
  # infer access group per row
  if (!("country" %in% names(mydata))) {
    stop("`mydata` must contain a `country` column to infer access group.")
  }
  mydata$redcap_data_access_group <- infer_access_group(mydata$country)
  
  # harmonize_platform_fields
  mydata <- harmonize_platform_fields(mydata)
  
  # dictionary-derived field sets
  form_cols <- get_redcap_form_columns(dictUrl = dictUrl, fallbackPath = fallbackPath)
  diagnostic_columns <- form_cols$diagnostic_columns
  sequencing_columns <- form_cols$sequencing_columns
  all_dict_cols <- form_cols$all_dict_cols
  
  # common REDCap repeat metadata
  mydata <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instance   = duplicate_id,
      redcap_repeat_instrument = ""
    ) %>%
    dplyr::select(any_of(c("sample_id", "redcap_data_access_group", all_dict_cols)))
  
  # diagnostic
  diagnostic_form <- mydata %>%
    dplyr::select(any_of(c("sample_id", "redcap_data_access_group", diagnostic_columns))) %>%
    dplyr::mutate(
      dplyr::across(dplyr::everything(), ~ tidyr::replace_na(as.character(.), ""))
    )
  
  # sequencing
  sequencing_form <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instrument = "sequencing"
    ) %>%
    dplyr::select(any_of(c("sample_id", "redcap_data_access_group", sequencing_columns))) %>%
    dplyr::mutate(
      dplyr::across(dplyr::everything(), ~ tidyr::replace_na(as.character(.), ""))
    )
  
  list(
    diagnostic_form = diagnostic_form,
    sequencing_form = sequencing_form
  )
}

