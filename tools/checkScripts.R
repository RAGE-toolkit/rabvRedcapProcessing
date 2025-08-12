


# a guide script to use rabvRedcapProcessing

# Install package
  # if not already installed
  # install.packages("devtools") 
devtools::install_github("RAGE-toolkit/rabvRedcapProcessing")
library(rabvRedcapProcessing)

library(dplyr) # in addition, we also use dplyr to manipulate data in this script

## read_data ######

# replace this with the path to your data
myData <- read_data(filepath = system.file("extdata", 
                                           "test_data.csv", 
                                           package = "rabvRedcapProcessing"))

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
out_data <- final_processing(mydata = recoded_data,
                             access_group ="philippines")


names(out_data)

write.csv(out_data$diagnostic_form, "~/Desktop/diagnostic_form.csv", row.names = F)
write.csv(out_data$sequencing_form, "~/Desktop/sequencing_form.csv", row.names = F)




