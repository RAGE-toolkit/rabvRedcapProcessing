#
#
# # Specify the columns that belong to each instrument (adjust based on actual columns)
#
# library(tidyverse)
#
# data_dict <- read.csv("../../existing_data/RABVlab_DataDictionary_2025-07-10_v1_ML.csv")
#
# required <- c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance")
#
# diagnostic_columns <- data_dict %>%
#   filter(Form.Name == "diagnostic") %>%
#   pull(Variable...Field.Name) %>%
#   union(required)
#
# sequencing_columns <- data_dict %>%
#   filter(Form.Name == "sequencing") %>%
#   pull(Variable...Field.Name) %>%
#   union(required)
#
#
# # parse a single choice‐string into a named vector (dynamically create dictionaries)
# parse_dict <- function(choice_str){
#   # split into “code, label” pieces
#   pieces <- str_split(choice_str, "\\|")[[1]] %>% str_trim()
#   # for each piece, split into code and label
#   kv <- map(pieces, ~{
#     parts <- str_split_fixed(.x, ",", 2)
#     code  <- str_trim(parts[1])
#     label <- str_trim(parts[2])
#     set_names(code, label)
#   })
#   # combine into one vector
#   unlist(kv)
# }
#
# # example: build a list of dicts, named by the field
# dicts <- data_dict %>%
#   filter(Choices..Calculations..OR.Slider.Labels != "") %>%
#   mutate(dict = map(Choices..Calculations..OR.Slider.Labels, parse_dict)) %>%
#   select(Variable...Field.Name, dict) %>%
#   deframe()
#
# # Dynamically extract dictionaries
# # 1. Rename each element so it gets a “_dict” suffix
# dicts_named <- setNames(dicts,
#          paste0(names(dicts), "_dict"))
# # 2. Push them all into your workspace
# list2env(dicts_named, envir = .GlobalEnv)
#
#
#
#
#
#
# # then refer to, e.g.
# dict_env$sample_tissuetype_dict
#
#
#
#
# # Define country dictionary
# country_dict  <- dicts[["country"]]
#
# # process this further to take either country full name or short
#       # parse out codes and names
#       entries <- names(country_dict)
#       parts   <- strsplit(entries, ":\\s*")
#       codes   <- sapply(parts, `[`, 1)
#       names_  <- sapply(parts, `[`, 2)
#       values  <- unname(country_dict)
#
#       # build a lookup that maps both code→value and name→value
#       country_dict <- c(
#         setNames(values, codes),
#         setNames(values, names_)
#       )
#
#
# # Define sample tissue dictionary
# tissue_dict   <- dicts[["sample_tissuetype"]]
#
# # Define the sample buffer dictionary
# buffer_dict   <- dicts[["sample_buffer"]]
#
# # Define the hmpcr dictionary
# hmpcr_dict <- dicts[["hmpcr_n405"]]
#
# # Define the rt_assay dictionary
# rt_assay_dict <- dicts[["rtassay"]]
#
# # Define the lateral flow dictionary
# lateral_flow_dict <- dicts[["lateral_flow_test"]]
#
# # Define the FAT dictionary
# fat_dict <- dicts[["fat"]]
#
# # Define the DRIT dictionary
# drit_dict <- dicts[["drit"]]
#
# # Define the test center dictionary
# test_center_dict <- dicts[["test_centre"]]
#
# # Define the ngs platform dictionary
# ngs_platform_dict <- dicts[["ngs_platform"]]
#
# # Define the nanopore platform dictionary
# nanopore_platform_dict <- dicts[["nanopore_platform"]]
#
# # Define the illumina platform dictionary
# illumina_platform_dict <- dicts[["illumina_platform"]]
#
# # Define the ngs prep dictionary
# ngs_prep_dict <-  dicts[["ngs_prep"]]
#
# # Define the ngs library dictionary
# ngs_library_dict <- dicts[["ngs_library"]]
#
#
# # Do this dynamically
#
# names(dicts)
#
# # 1. Rename each element so it gets a “_dict” suffix
# dicts_named <- setNames(dicts,
#                         paste0(names(dicts), "_dict"))
#
# # 2. Push them all into your workspace (or any environment you like)
# list2env(dicts_named, envir = .GlobalEnv)
#
#
# # 3. Update country dict
#
#   # process this further to take either country full name or short
#   # parse out codes and names
# entries <- names(country_dict)
# parts   <- strsplit(entries, ":\\s*")
# codes   <- sapply(parts, `[`, 1)
# names_  <- sapply(parts, `[`, 2)
# values  <- unname(country_dict)
#
# # build a lookup that maps both code→value and name→value
# country_dict <- c(
#   setNames(values, codes),
#   setNames(values, names_)
# )
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
