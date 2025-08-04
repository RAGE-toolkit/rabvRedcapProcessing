#' Read and Parse REDCap Data Dictionary
#'
#' Reads a REDCap data dictionary (CSV format) and parses the "Choices" column
#' to create a named list of value-label pairs for use in data recoding. By default,
#' it loads an internal dictionary included with the package, but users can specify
#' a different dictionary file via the `dictPath` argument.
#'
#' Special handling is provided for the "country" field, allowing both country names
#' and codes to be valid inputs by building a dual-mapped dictionary.
#'
#' @param dictPath Path to the REDCap data dictionary CSV file. If not specified, a default
#' dictionary included in the package will be used.
#'
#' @return A named list of named vectors, where each list element corresponds to a field name,
#' and each named vector maps value codes to human-readable labels.
#'
#' @export
#'
#' @importFrom dplyr filter mutate select
#' @importFrom tibble deframe
#' @importFrom stringr str_split str_trim str_split_fixed
#' @importFrom purrr map
#' @importFrom magrittr %>%
#'
#' @examples
#' # Use the default dictionary included with the package
#' dicts <- read_and_parse_dict()
#'
#' # Or specify a custom dictionary path
#' dicts <- read_and_parse_dict("path/to/my_dictionary.csv")
#' 
#' dicts[["sample_buffer"]]
#' # > Glycerol-saline = Glycerol-saline
#' # > RNAshield = RNAshield
read_and_parse_dict <- function(dictPath = system.file("extdata", 
                                                       "RABVlab_DataDictionary_redcap2025-08-04.csv", 
                                                       package = "rabvRedcapProcessing")) {
  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)

  # Helper to parse single string of "code, label | code, label"
  parse_dict <- function(choice_str) {
    pieces <- stringr::str_split(choice_str, "\\|")[[1]] %>% 
    stringr::str_trim()
    # key values
    kv <- purrr::map(pieces, ~{
      parts <- stringr::str_split_fixed(.x, ",", 2)
      code  <- stringr::str_trim(parts[1])
      label <- stringr::str_trim(parts[2])
      setNames(label, code)  # named vector: names = code, value = label
    })
    unlist(kv)
  }

  dicts <- data_dict %>%
    dplyr::filter(.data$Choices..Calculations..OR.Slider.Labels != "") %>%
    dplyr::mutate(
      dict = purrr::map(.data$Choices..Calculations..OR.Slider.Labels, parse_dict)) %>%
    dplyr::select("Variable...Field.Name", "dict") %>%
    tibble::deframe()

  # Define country dictionary
  country_dict  <- dicts[["country"]]

  # process this further to take either country full name or short
  # parse out codes and names
  entries <- names(country_dict)
  values  <- unname(country_dict)
  parts   <- strsplit(values, ":\\s*")
  codes   <- sapply(parts, `[`, 1)
  names_  <- sapply(parts, `[`, 2)


  # build a lookup that maps both code→value and name→value
  country_dict <- c(
   # setNames(codes, entries),
    setNames(names_, entries)
  )

  dicts[["country"]] <- country_dict


  return(dicts)
}
