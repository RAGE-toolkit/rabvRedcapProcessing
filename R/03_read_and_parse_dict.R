#' Read and Parse REDCap Data Dictionary
#'
#' This function reads a REDCap data dictionary (CSV format) and parses the "Choices" column
#' to create a named list of value-label pairs for use in data recoding. If the field is "country",
#' a special parser allows both country codes and names to map to values.
#'
#' @param dictPath Path to the REDCap data dictionary CSV file.
#'
#' @return A named list of named vectors, where each list element corresponds to a field name,
#' and each named vector maps value codes to human-readable labels.
#'
#' @export
#'
#' @examples
#' dicts <- read_and_parse_dict("data_dictionary.csv")
#' dicts[["sample_buffer"]]
#' # > 0 = Glycerol-saline
#' # > 1 = RNAshield
#' # > ...

read_and_parse_dict <- function(dictPath) {
  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)

  # Helper to parse single string of "code, label | code, label"
  parse_dict <- function(choice_str) {
    pieces <- stringr::str_split(choice_str, "\\|")[[1]] %>% stringr::str_trim()
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
      dict = purrr::map(.data$Choices..Calculations..OR.Slider.Labels, parse_dict)
    ) %>%
    # dplyr::select(field = .data$Variable...Field.Name, dict) %>% # deprecated
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
