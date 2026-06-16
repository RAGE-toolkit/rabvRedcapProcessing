


# a guide script to use rabvRedcapProcessing

# Install package
  # if not already installed
  # install.packages("devtools") 
devtools::install_github("RAGE-toolkit/rabvRedcapProcessing", force = TRUE)
install.packages("here")
library(here)

#library(dplyr) # in addition, we also use dplyr to manipulate data in this script

## read_data ######change filepath as needed
# this should find the test data in the rage_redcap github repo if you have it cloned on your laptop (no need to change filepath)
filepath <- here("rage_redcap","data", "test_data", "test-metadata.csv")

# replace this with the path to your data
myData <- read_data(filepath)

## read_and_parse_dict#####
  # There is an inbuilt dictionsry, but you can specify a url to a customized dictionary
myDicts <- read_and_parse_dict()


## compare_cols_to_dict ####
updated_data <- compare_cols_to_dict(dayta = myData)
    # Read the message carefully

## tidy up values ####
updated_data <- tidy_up_values(updated_data)

## scan_mismatched_levels ####

    # To check coded columns:
names(myDicts)

    # To view the codes of a specific column 
myDicts$sample_tissuetype
myDicts$ngs_prep
    # Carefully move column by column
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "sample_tissuetype")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "sample_buffer")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "country")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "hmpcr_n405")
myDicts$hmpcr_n405

scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "test_centre")
myDicts$test_centre

scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "ngs_platform")
scan_mismatched_levels(dayta = updated_data, dicts = myDicts, col_to_check = "nanopore_platform")

# "Note: ⚠️ You are responsible in making sure all values in coded columns match the dictionary values

  # Process the mismatched values where necessary using custom scriptd -- outside the package

# create final diagnosis 
updated_data2 <- create_diagnostic_result_rule(updated_data) 


# Recode data##########
recoded_data <- recode_data(dicts = myDicts, dayta = updated_data2)


# final process ##########
out_data <- final_processing(mydata = recoded_data)

# derive output filenames from input file
input_dir <- dirname(filepath)

input_name <- tools::file_path_sans_ext(
  basename(filepath)
)

diagnostic_outfile <- file.path(
  input_dir,
  paste0(input_name, "_diagnostic_form.csv")
)

sequencing_outfile <- file.path(
  input_dir,
  paste0(input_name, "_sequencing_form.csv")
)

# write outputs
write.csv(
  out_data$diagnostic_form,
  diagnostic_outfile,
  row.names = FALSE
)

write.csv(
  out_data$sequencing_form,
  sequencing_outfile,
  row.names = FALSE
)




