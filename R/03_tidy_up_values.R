#' Tidy Up Lab Data Values Before Recoding
#'
#' This function standardizes common mismatches in lab data to align with REDCap dictionary values.
#' It harmonizes tissue types, buffer names, test results (FAT, dRIT, lateral flow), and PCR results.
#' It also sanitizes `sample_id` to remove special characters (`+`, `&`) which may break REDCap uploads.
#'
#' @param df A data frame containing raw lab data.
#'
#' @return A cleaned data frame with harmonized categorical values.
#'
#' @examples
#' \dontrun{
#' cleaned_df <- tidy_up_values(raw_df)
#'}
#'
#' @importFrom dplyr mutate case_when
#' @importFrom stringr str_detect str_to_lower str_replace_all
#' @export
tidy_up_values <- function(df) {
  df_edited <- df %>%
    dplyr::mutate(
      sample_tissuetype = dplyr::case_when(
        str_detect(tolower(sample_tissuetype), "salivary") ~ "Salivary_gland",
        str_detect(tolower(sample_tissuetype), "saliva") ~ "Saliva",
        str_detect(tolower(sample_tissuetype), "brain") ~ "Brain",
        TRUE ~ sample_tissuetype
      ),
      
      sample_buffer = dplyr::case_when(
        str_to_lower(sample_buffer) %in% c("none", "no buffer") ~ "No_buffer_fresh",
        str_detect(tolower(sample_buffer), "glycerol") ~ "Glycerol-saline",
        str_detect(tolower(sample_buffer), "shield") ~ "RNAshield",
        str_detect(tolower(sample_buffer), "rnala") ~ "RNAlater",
        str_detect(tolower(sample_buffer), "-80") ~ "No_buffer_fresh_stored_at_-80",
        TRUE ~ sample_buffer
      ),
      
      fat = dplyr::case_when(
        tolower(fat) %in% c("pos", "positive", "pos1", "pos2") ~ "Positive",
        tolower(fat) %in% c("neg", "negative") ~ "Negative",
        TRUE ~ fat
      ),
      
      drit = dplyr::case_when(
        tolower(drit) %in% c("pos", "positive", "pos1", "pos2") ~ "Positive",
        tolower(drit) %in% c("neg", "negative") ~ "Negative",
        TRUE ~ drit
      ),
      
      lateral_flow_test = dplyr::case_when(
        tolower(lateral_flow_test) %in% c("pos", "positive", "pos1", "pos2") ~ "Positive",
        tolower(lateral_flow_test) %in% c("neg", "negative") ~ "Negative",
        TRUE ~ lateral_flow_test
      ),
      
      hmpcr_n405 = dplyr::case_when(
        tolower(hmpcr_n405) == "pos1" ~ "Pos1",
        tolower(hmpcr_n405) == "pos2" ~ "Pos2",
        tolower(hmpcr_n405) == "neg" ~ "Neg",
        TRUE ~ hmpcr_n405
      ),
      
      sample_id = sample_id %>%
        str_replace_all("[&+]", "_")
    )
  
  return(df_edited)
}
