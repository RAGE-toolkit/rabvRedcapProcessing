


final_processing <- function(mydata, dictPath){
  # Optionally, match column order to dictionary
  # add "redcap_repeat_instrument", "redcap_repeat_instance", dag
  # split into diagnostic and sequencing BUT check for unnecessary diagnostic duplicates

  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)

  # Extract diagnostic and sequencing columns
  diagnostic_columns <- data_dict %>%
    dplyr::filter(Form.Name == "diagnostic") %>%
    dplyr::pull(Variable...Field.Name)  %>%
    union(c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance"))

  sequencing_columns <- data_dict %>%
    dplyr::filter(Form.Name == "sequencing") %>%
    dplyr::pull(Variable...Field.Name) %>%
    union(c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance"))


  dict_cols <- data_dict %>%
    dplyr::pull(Variable...Field.Name) %>%
    union(c("redcap_repeat_instrument", "redcap_repeat_instance"))


  mydata <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instance = duplicate_id,
      redcap_repeat_instrument = "") %>%
    dplyr::select(all_of(dict_cols))



  diagnostic_form <- mydata %>%
      dplyr::mutate(
        redcap_repeat_instrument = "diagnostic",
      ) %>%
      dplyr::select(all_of(diagnostic_columns))


  sequencing_form <- mydata %>%
    dplyr::mutate(
      redcap_repeat_instrument = "sequencing",
    ) %>%
    dplyr::select(all_of(sequencing_columns))

output_data <- bind_rows(diagnostic_form, sequencing_form) %>%
    dplyr::mutate(across(everything(), as.character)) %>%  # Convert all columns to character
    mutate_all(~ replace_na(., ""))

}

write.csv(output_data, "~/Desktop/redcap_ready.csv")


# # Create diagnostic data rows
# diagnostic_data_PH <-combined_ph %>%
#   dplyr::mutate(
#     redcap_repeat_instrument = "diagnostic",
#     redcap_repeat_instance = duplicate_id,
#     sample_buffer = "Unknown",
#     rtqpcr = "Unknown",
#     test_centre = "Other"
#   ) %>%
#   dplyr::select(all_of(diagnostic_columns))
#
#
#
# # Create sequencing data rows
# sequencing_data_PH <- combined_ph %>%
#   dplyr::mutate(
#     redcap_repeat_instrument = "sequencing",
#     redcap_repeat_instance = duplicate_id,
#     ngs_platform = "Nanopore",
#     nanopore_platform = "Minion"
#   ) %>%
#   dplyr::select(all_of(sequencing_columns))
