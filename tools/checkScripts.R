

rm(list = ls())

remove.packages(c("ggplot2", "dplyr", "tidyr", "readr", 
                  "purrr", "tibble", "stringr", "rabvRedcapProcessing"))


devtools::install_github("RAGE-toolkit/rabvRedcapProcessing@devel")
library(rabvRedcapProcessing)
ls("package:rabvRedcapProcessing")


# scripts <- c("R/01_read_data.R","R/02_read_and_parse_dict.R", "R/03_tidy_up_values.R",
#          "R/03_compare_cols_to_dict.R", "R/04_scan_mismatched_levels.R",
#          "R/05_create_final_diagnosis.R", "R/06_recode_data.R", 
#          "R/07_final_processing.R")
# 
# lapply(scripts, source)

## read_data ######
myData <- read_data("~/Documents/rabiesResearch/redcap_working_repos/rabvRedcapProcessing/inst/data/test_data.csv")

# too many duplicates, partly because of empty sample ids

myData <- myData %>%
  dplyr::mutate(sample_id = if_else(sample_id == "", sample_sequenceid, sample_id)) 


## read_and_parse_dict#####
myDicts <- read_and_parse_dict("~/Documents/rabiesResearch/redcap_working_repos/rabvRedcapProcessing/inst/data/RABVlab_DataDictionary_redcap_2025-07-24.csv")


## compare_cols_to_dict ####
updated_data <- compare_cols_to_dict(dayta = myData,
                     dictPath = "~/Documents/rabiesResearch/redcap_working_repos/rabvRedcapProcessing/inst/data/RABVlab_DataDictionary_redcap_2025-07-24.csv")


## tidy up values ####
updated_data <- tidy_up_values(updated_data)

## scan_mismatched_levels ####
# To check coded columns:
names(myDicts)

# To view the codes of a specific column
myDicts$sample_tissuetype
myDicts$ngs_prep

scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "sample_tissuetype")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "sample_buffer")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "country")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "hmpcr_n405")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "lateral_flow_test")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "fat")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "drit")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "test_centre")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "ngs_platform")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "nanopore_platform")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "illumina_platform")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "ngs_prep")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "ngs_library")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "ngs_analysis_type")



  # Process the mismatched values where necessary

updated_data <- updated_data %>%
      # create final diagnosis ##### 
  dplyr::mutate(diagnostic_result = create_diagnostic_result_rule(.))


# Recode data##########
recoded_data <- recode_data(dicts = myDicts, dayta = updated_data)


# final process ##########
out_data <- final_processing(mydata = recoded_data, dictPath = "./inst/data/RABVlab_DataDictionary_redcap_2025-07-24.csv",
                             access_group ="philippines")


names(out_data)

write.csv(out_data$diagnostic_form, "~/Desktop/checkpackageDiagnostic.csv", row.names = F)
