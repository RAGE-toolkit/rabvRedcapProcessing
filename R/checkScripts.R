

rm(list = ls())

library(tidyverse)

scripts <- c("R/01_read_data.R", "R/02_process_data.R", "R/03_read_and_parse_dict.R",
         "R/04_compare_cols_to_dict.R", "R/05_scan_mismatched_levels.R",
         "R/06_recode_data.R")

lapply(scripts, source)

## read_data ######
myData <- read_data("./inst/data/Genomic_surveillance_data_RedCap - data_for_upload.csv")

# too many duplicates, partly because of empty sample ids

myData <- myData %>%
  dplyr::mutate(sample_id = if_else(sample_id == "", sample_sequenceid, sample_id)) %>%

# process data #####
  dplyr::mutate(diagnostic_result = create_diagnostic_result_rule(.))


## read_and_parse_dict#####
myDicts <- read_and_parse_dict("./inst/data/RABVlab_DataDictionary_2025-07-15.csv")


## compare_cols_to_dict ####
updated_data <- compare_cols_to_dict(dayta = myData,
                     dictPath = "./inst/data/RABVlab_DataDictionary_2025-07-15.csv")

## scan_mismatched_levels ####
# To check coded columns:
names(myDicts)

# To view the codes of a specific column
myDicts$sample_tissuetype
myDicts$ngs_prep

scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "sample_tissuetype")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "lateral_flow_test")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "ngs_prep")

  # Process the mismatched values where necessary

# Recode
recoded_data <- recode_data(dicts = myDicts, dayta = updated_data)


myDicts$country
myDicts$sample_tissuetype
myDicts$lateral_flow_test



