#!/usr/bin/env Rscript
# =============================================================================
# 02 — Fit calibration models from PBP clay standards
# =============================================================================
# For each preparation method (pellet, powder), fit linear calibrations of the
# form  Known_Pb_ppm ~ <response>  on the PBP clay standards. Sweep candidate
# response variables so the choice of intensity line / line combination is
# empirical, not assumed.
#
# Excluded from the intensity sweep due to spectral overlap with elements
# present in the ash matrix:
#   Pb_Lα1, Pb_Lα2  (As Kα ~10.543 keV — As is present in samples)
#   Pb_Ll           (Ge/W/Au L-lines region, lower SNR)
#   Pb_Lγ1          (Rb Kβ, Y Kα, Sr Kβ in the 14.7–15 keV region)
#
# Inputs:
#   data/calibration/PBP_calibration_table.csv
#
# Outputs:
#   data/calibration/calibration_sweep_full.csv     (all candidates, ranked)
#   data/calibration/calibration_models_4arms.csv   (FP + best-intensity per
#                                                    prep — the 4 canonical
#                                                    models carried into ash)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(broom)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"

cal <- read_csv(file.path(ROOT, "data/calibration/PBP_calibration_table.csv"),
                show_col_types = FALSE)

# -----------------------------------------------------------------------------
# Candidate responses (interference-free + the FP-derived concentration).
# Each entry is a function that returns a numeric vector from a calibration
# data frame; that lets sums and multi-predictor models share the same fitter.
# -----------------------------------------------------------------------------

# Single-predictor candidates: response label -> column expression
single_responses <- list(
  "FP_concentration"   = quote(FP_value_ppm),
  "Pb_Lb1"             = quote(Pb_Lb1_cps),
  "Pb_Lb2"             = quote(Pb_Lb2_cps),
  "Pb_Lb3"             = quote(Pb_Lb3_cps),
  "Pb_Lb4"             = quote(Pb_Lb4_cps),
  "Pb_Lb1+Lb2"         = quote(Pb_Lb1_cps + Pb_Lb2_cps),
  "Pb_Lb1+Lb3"         = quote(Pb_Lb1_cps + Pb_Lb3_cps),
  "Pb_Lb1+Lb2+Lb3+Lb4" = quote(Pb_Lb1_cps + Pb_Lb2_cps + Pb_Lb3_cps + Pb_Lb4_cps)
)

# Multi-predictor candidates: separate slopes per line
multi_responses <- list(
  "Pb_Lb1,Lb2 (multi)" = c("Pb_Lb1_cps", "Pb_Lb2_cps"),
  "Pb_Lb1,Lb3 (multi)" = c("Pb_Lb1_cps", "Pb_Lb3_cps")
)

# -----------------------------------------------------------------------------
# Fit one model and return tidy stats. NA-aware: drops rows with missing
# responses (PBP04_powder_1 is the only standard expected to drop).
# -----------------------------------------------------------------------------

# formula_rhs is the literal RHS of the lm() formula. For a single-predictor
# response (including sums like Pb_Lb1_cps + Pb_Lb2_cps), the expression is
# wrapped in I() so it stays a single regressor; multi-predictor candidates
# leave it bare so '+' means "separate slopes."
fit_single <- function(df, label, expr) {
  rhs <- paste0("I(", deparse1(expr), ")")
  fmla <- as.formula(paste("Known_Pb_ppm ~", rhs))
  df2 <- df %>% mutate(.response = !!expr) %>%
    filter(!is.na(.response), !is.na(Known_Pb_ppm))
  if (nrow(df2) < 3) return(NULL)
  m <- lm(fmla, data = df2)
  g <- glance(m); co <- tidy(m)
  tibble(
    response      = label,
    response_type = if (label == "FP_concentration") "FP" else "Intensity",
    formula_rhs   = rhs,
    is_multi      = FALSE,
    n             = nrow(df2),
    intercept     = co$estimate[1],
    slope         = co$estimate[2],
    r_squared     = g$r.squared,
    adj_r2        = g$adj.r.squared,
    RMSE_ppm      = sqrt(mean(m$residuals^2)),
    AIC           = AIC(m),
    BIC           = BIC(m)
  )
}

fit_multi <- function(df, label, cols) {
  df2 <- df %>% select(Known_Pb_ppm, all_of(cols)) %>% drop_na()
  if (nrow(df2) < length(cols) + 2) return(NULL)
  rhs <- paste(cols, collapse = " + ")
  fmla <- as.formula(paste("Known_Pb_ppm ~", rhs))
  m <- lm(fmla, data = df2)
  g <- glance(m); co <- tidy(m)
  tibble(
    response      = label,
    response_type = "Intensity",
    formula_rhs   = rhs,
    is_multi      = TRUE,
    n             = nrow(df2),
    intercept     = co$estimate[1],
    slope         = NA_real_,        # see calibration_models_4arms_coefs.csv
    r_squared     = g$r.squared,
    adj_r2        = g$adj.r.squared,
    RMSE_ppm      = sqrt(mean(m$residuals^2)),
    AIC           = AIC(m),
    BIC           = BIC(m)
  )
}

# -----------------------------------------------------------------------------
# Sweep within each method
# -----------------------------------------------------------------------------

sweep_method <- function(df_method, method_label) {
  rows_single <- imap(single_responses, ~ fit_single(df_method, .y, .x)) %>%
    compact() %>% bind_rows()
  rows_multi  <- imap(multi_responses,  ~ fit_multi(df_method, .y, .x)) %>%
    compact() %>% bind_rows()
  bind_rows(rows_single, rows_multi) %>% mutate(method = method_label, .before = 1)
}

sweep_pellet <- sweep_method(filter(cal, method == "pellet"), "pellet")
sweep_powder <- sweep_method(filter(cal, method == "powder"), "powder")
sweep_full   <- bind_rows(sweep_pellet, sweep_powder) %>%
  arrange(method, desc(r_squared))

write_csv(sweep_full,
          file.path(ROOT, "data/calibration/calibration_sweep_full.csv"))

cat("=== 02 — Calibration sweep ===\n")
cat("(",  nrow(sweep_full), "candidates total — ",
    nrow(sweep_pellet), "pellet,", nrow(sweep_powder), "powder)\n\n")
print(sweep_full %>%
        select(method, response, n, r_squared, RMSE_ppm, AIC) %>%
        mutate(across(c(r_squared, RMSE_ppm, AIC), ~ round(.x, 3))),
      n = Inf)

# -----------------------------------------------------------------------------
# Pick the canonical 4-arm panel: FP + best Intensity per prep method
# -----------------------------------------------------------------------------

best_intensity <- sweep_full %>%
  filter(response_type == "Intensity") %>%
  group_by(method) %>% slice_max(r_squared, n = 1, with_ties = FALSE) %>%
  ungroup() %>% mutate(arm = paste0(method, "_intensity"))

fp_arms <- sweep_full %>%
  filter(response_type == "FP") %>%
  mutate(arm = paste0(method, "_FP"))

models_4arms <- bind_rows(fp_arms, best_intensity) %>%
  select(arm, method, response_type, response, formula_rhs, is_multi,
         n, intercept, slope, r_squared, RMSE_ppm) %>%
  arrange(method, response_type)

write_csv(models_4arms,
          file.path(ROOT, "data/calibration/calibration_models_4arms.csv"))

cat("\n=== Canonical 4 arms (FP + best Intensity per method) ===\n")
print(models_4arms %>%
        mutate(across(c(intercept, slope, r_squared, RMSE_ppm), ~ round(.x, 4))),
      n = Inf)
