#' Classify Overall Diagnostic Result from Multiple Rabies Test Columns
#'
#' This function derives an overall diagnostic result based on available test outcomes,
#' following a defined logical hierarchy across multiple diagnostic assays. It is designed
#' to work with lateral flow test (LFT), RT-qPCR, hemi-nested PCR (HMPCR), 
#' direct fluorescent antibody test (FAT), and direct rapid immunohistochemical test (DRIT).
#'
#' The function assumes that categorical variables have already been cleaned and recoded
#' using standardized dictionary values (e.g., `"Positive"`, `"Negative"`, `"Pos1"`, `"Neg"`).
#'
#' ## Decision Logic
#' The diagnostic result is classified as follows:
#' 1. **Lateral flow test positive overrides all other results** → returns `"Positive"`.
#' 2. If **all available test results are "Negative"**, then returns `"Negative"`.
#' 3. If **FAT or DRIT is "Positive"**, returns `"Positive"`.
#' 4. If **RT-qPCR Ct value < 32**, returns `"Positive"`.
#'    - If Ct value is between 32–36 (inclusive), returns `"Inconclusive"`.
#'    - If Ct > 36, returns `"Negative"`.
#' 5. If **HMPCR is "Pos1" or "Pos2"**, returns `"Positive"`, or `"Negative"` if `"Neg"`.
#' 6. If no valid results are available, returns `NA`.
#'
#' @param df A data frame containing any combination of the following columns:
#'   - `lateral_flow_test`: Categorical values (e.g., `"Positive"`, `"Negative"`).
#'   - `rtqpcr`: Numeric Ct values (or character values coercible to numeric).
#'   - `hmpcr_n405`: HMPCR results (e.g., `"Pos1"`, `"Pos2"`, `"Neg"`).
#'   - `fat`: FAT result.
#'   - `drit`: DRIT result.
#'
#' @return A character vector (`"Positive"`, `"Negative"`, `"Inconclusive"`, or `NA`)
#'   representing the overall diagnostic interpretation for each row.
#'
#' @export
#' @examples
#' df <- tibble::tibble(
#'   lateral_flow_test = c("Positive", "Negative", NA),
#'   rtqpcr = c("30", "37", "34"),
#'   hmpcr_n405 = c("Pos1", "Neg", "Neg"),
#'   fat = c(NA, NA, "Positive"),
#'   drit = c(NA, "Negative", NA)
#' )
#' df$diagnosis <- create_diagnostic_result_rule(df)
create_diagnostic_result_rule <- function(df) {
  n <- nrow(df)
  
  get_column <- function(col, default = NA_character_, numeric = FALSE) {
    if (col %in% names(df)) {
      val <- df[[col]]
      val[val == ""] <- NA
      if (numeric) suppressWarnings(as.numeric(val)) else val
    } else {
      rep(default, n)
    }
  }
  
  lft       <- get_column("lateral_flow_test")
  rt        <- get_column("rtqpcr", default = NA_real_, numeric = TRUE)
  hmp       <- get_column("hmpcr_n405")
  fat_test  <- get_column("fat")
  drit_test <- get_column("drit")
  
  purrr::pmap_chr(
    list(lft, rt, hmp, fat_test, drit_test),
    function(lft, rt, hmp, fat, drit) {
      all_tests <- c(lft, rt, hmp, fat, drit)
      
      if (all(is.na(all_tests))) return(NA_character_)
      
      # 1. LFT positive overrides all
      if (!is.na(lft) && lft == "Positive") return("Positive")
      
      # 2. If all results are "Negative" (excluding NA), return Negative
      if (all(all_tests[!is.na(all_tests)] == "Negative")) return("Negative")
      
      # 3. FAT/DRIT override
      if (!is.na(fat) && fat == "Positive") return("Positive")
      if (!is.na(drit) && drit == "Positive") return("Positive")
      
      # 4. RT-qPCR logic
      if (!is.na(rt)) {
        if (rt < 32) return("Positive")
        if (rt <= 36) return("Inconclusive")
        return("Negative")
      }
      
      # 5. HMPCR logic
      if (!is.na(hmp) && hmp %in% c("Pos1", "Pos2")) return("Positive")
      if (!is.na(hmp) && hmp == "Neg") return("Negative")
      
      # Fallback
      NA_character_
    }
  )
}
