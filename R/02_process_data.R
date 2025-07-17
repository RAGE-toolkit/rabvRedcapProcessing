#' Classify Diagnostic Result from Multiple Test Columns
#'
#' This function assigns an overall diagnostic result based on available test results:
#' lateral flow test (LFT), RT-qPCR, HMPCR, FAT, and DRIT. If columns are missing,
#' it defaults to `NA`. Hierarchy: FAT/DRIT > LFT > RT-qPCR > HMPCR.
#'
#' @param df A data frame containing any combination of: `lateral_flow_test`, `rtqpcr`,
#' `hmpcr_n405`, `fat`, `drit`.
#'
#' @return A character vector of diagnostic results: "Positive", "Negative", "Inconclusive", or NA
#' @export
#'
#' @examples
#' df <- tibble::tibble(
#'   lateral_flow_test = c("", "0", "1"),
#'   rtqpcr = c("30", "", "40"),
#'   hmpcr_n405 = c("", "1", "0"),
#'   fat = c("", "", ""),
#'   drit = c("Negative", "", "")
#' )
#' df$diagnostic_result <- create_diagnostic_result_rule(df)
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
      all_missing <- all(is.na(c(lft, rt, hmp, fat, drit)))
      if (all_missing) return(NA_character_)

      # FAT/DRIT override
      if (!is.na(fat) || !is.na(drit)) {
        if (fat == "Positive" || drit == "Positive") return("Positive")
        if ((fat == "Negative" || drit == "Negative") &&
            (!is.na(lft) && lft == "1" || !is.na(rt) && rt < 32 || hmp %in% c("0", "1")))
          return("Positive")
        return("Negative")
      }

      # LFT
      if (!is.na(lft)) return(ifelse(lft == "1", "Positive", "Negative"))

      # RT-qPCR
      if (!is.na(rt)) {
        if (rt < 32) return("Positive")
        if (rt <= 36) return("Inconclusive")
        return("Negative")
      }

      # HMPCR
      if (!is.na(hmp)) return(ifelse(hmp %in% c("0", "1"), "Positive", "Negative"))

      # Fallback
      NA_character_
    }
  )
}
