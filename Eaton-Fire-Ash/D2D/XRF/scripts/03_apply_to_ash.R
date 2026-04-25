#!/usr/bin/env Rscript
# =============================================================================
# 03 — Predict Pb in ash (two-stage: clay calibration + ash-matrix correction)
# =============================================================================
# Pb prediction in ash requires two transformations:
#
#   Stage A. Clay calibration (from script 02): the 4-arm models (FP +
#            best Intensity, per pellet/powder) trained on PBP clay standards.
#            Applied directly to ash they give Pb_clay_pred — a matrix-naive
#            estimate that systematically under-predicts ash Pb by ~3× because
#            clay and ash have different mass-attenuation coefficients.
#
#   Stage B. Ash-matrix correction: per arm, fit a proportional regression
#            ICPMS_Pb ~ Pb_clay_pred on paired ash. The slope-fit training
#            set excludes high-leverage outliers flagged by Cook's D > 4/n
#            (typically XPAH28 and JPL73, whose extreme x² otherwise dominates
#            the proportional-regression denominator). The same rule applies
#            to all four arms (FP and Intensity, pellet and powder) so the
#            workflow is consistent across response types.
#
#            Eligible samples receive a LOOCV slope (refit excluding their own
#            row). Ineligible samples (training-excluded outliers) are still
#            predicted, using the full eligible-set slope. Validation in
#            script 04 then evaluates on the COMPLETE paired set.
#
# Outputs:
#   data/validation/ash_matrix_correction_4arms.csv  (slope per arm, LOOCV
#                                                     spread, full-fit slope,
#                                                     excluded sample list)
#   data/validation/ash_predicted_Pb.csv             (long: sample × arm; the
#                                                     predicted_Pb_ppm column
#                                                     is matrix-corrected;
#                                                     is_training_eligible
#                                                     flag preserved)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"

REPO     <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D"

cal      <- read_csv(file.path(ROOT, "data/calibration/PBP_calibration_table.csv"),
                     show_col_types = FALSE)
arms     <- read_csv(file.path(ROOT, "data/calibration/calibration_models_4arms.csv"),
                     show_col_types = FALSE)
elements <- read_csv(file.path(ROOT, "data/cleaned/XRF_elements_clean.csv"),
                     show_col_types = FALSE)
pb_lines <- read_csv(file.path(ROOT, "data/cleaned/XRF-Pb_clean.csv"),
                     show_col_types = FALSE)
icpms    <- read_csv(file.path(REPO, "ICPMS/EFA_ICPMS_PPM.csv"),
                     show_col_types = FALSE) %>%
  select(sample_id = EFA.ID, Pb_icpms = Pb)

# -----------------------------------------------------------------------------
# Build ash response table — one row per ash sample×method, with the same
# response columns the calibration models expect.
# -----------------------------------------------------------------------------

ash_fp <- elements %>%
  filter(!str_starts(sample_id, "PBP"), element == "Pb") %>%
  mutate(
    unit = if_else(unit == "wt_%", "%", unit),
    FP_value_ppm = case_when(
      unit == "%"   ~ value * 1e4,
      unit == "ppm" ~ value,
      TRUE          ~ NA_real_
    )
  ) %>%
  # Average replicate Pb measurements within (sample_id, method).
  group_by(sample_id, method) %>%
  summarise(FP_value_ppm = mean(FP_value_ppm, na.rm = TRUE), .groups = "drop")

ash_intens <- pb_lines %>%
  filter(!str_starts(sample_id, "PBP"),
         line_symbol %in% c("Pb_Lb1", "Pb_Lb2", "Pb_Lb3", "Pb_Lb4")) %>%
  group_by(sample_id, method, line_symbol) %>%
  summarise(cts_per_s = mean(cts_per_s, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = line_symbol, values_from = cts_per_s,
              names_glue = "{line_symbol}_cps")

ash <- ash_fp %>% full_join(ash_intens, by = c("sample_id", "method"))

cat("=== 03 — Ash response table ===\n")
cat("Rows:", nrow(ash), " (", length(unique(ash$sample_id)), "samples ×",
    length(unique(ash$method)), "methods)\n")
cat("Per method:\n"); print(count(ash, method))

# -----------------------------------------------------------------------------
# Refit the 4 arms and predict on ash
# -----------------------------------------------------------------------------

predict_arm_clay <- function(arm_row, cal_data, ash_data) {
  m <- arm_row$method
  cal_m <- cal_data %>% filter(method == m)
  ash_m <- ash_data %>% filter(method == m)

  fmla <- as.formula(paste("Known_Pb_ppm ~", arm_row$formula_rhs))
  fit  <- lm(fmla, data = cal_m)

  ash_m %>%
    mutate(Pb_clay_pred = predict(fit, newdata = ash_m),
           arm = arm_row$arm,
           response_label = arm_row$response,
           formula_rhs = arm_row$formula_rhs) %>%
    select(sample_id, method, arm, response_label, formula_rhs, Pb_clay_pred)
}

predictions <- map_dfr(seq_len(nrow(arms)),
                       ~ predict_arm_clay(arms[.x, ], cal, ash)) %>%
  filter(str_detect(arm, paste0("^", method, "_")))

# -----------------------------------------------------------------------------
# Stage B — Ash-matrix correction
#
# The clay calibration's prediction Pb_clay_pred is the matrix-naive estimate.
# Fit  ICPMS_Pb = m_arm × Pb_clay_pred  (proportional, no intercept) on the
# subset of ash samples that have an ICP-MS measurement. The slope m_arm is
# the matrix-attenuation factor (≈3 for both prep methods in this study).
#
# For each ash sample with an ICPMS partner, the LOOCV slope (refit with that
# row excluded) is used to derive its corrected prediction so downstream
# validation isn't circular. Samples without ICPMS get the full-fit slope.
# -----------------------------------------------------------------------------

predictions <- predictions %>%
  left_join(icpms, by = "sample_id")

# Lookup table mapping arm -> response_type, so the matrix-correction logic
# can branch on Intensity vs FP.
arm_to_type <- arms %>% select(arm, response_type) %>% deframe()

# Proportional regression slope and Cook's D for y = b·x (no intercept).
prop_slope <- function(x, y) sum(x * y) / sum(x * x)
cooks_d_prop <- function(x, y) {
  b <- prop_slope(x, y); r <- y - b * x
  h <- x^2 / sum(x^2);  s2 <- sum(r^2) / max(length(r) - 1, 1)
  (r^2 * h) / ((1 - h)^2 * s2)
}

fit_correction_arm <- function(df_arm) {
  arm_label    <- df_arm$arm[1]
  response_type <- arm_to_type[[arm_label]]
  d <- df_arm %>% filter(!is.na(Pb_icpms), !is.na(Pb_clay_pred), Pb_clay_pred > 0)

  # Cook's D > 4/n flags high-leverage / high-residual samples; applied
  # uniformly to every arm so the workflow is consistent.
  d$cooks_D <- cooks_d_prop(d$Pb_clay_pred, d$Pb_icpms)
  cooks_thr <- 4 / nrow(d)
  d$is_training_eligible <- d$cooks_D <= cooks_thr
  e_idx <- which(d$is_training_eligible)
  excluded_ids <- d$sample_id[!d$is_training_eligible]
  full <- prop_slope(d$Pb_clay_pred[e_idx], d$Pb_icpms[e_idx])

  # LOOCV slope: for eligible row i, refit on (eligible - {i}); for ineligible
  # row, use the full eligible-set slope.
  d$loo_slope <- NA_real_
  for (i in seq_len(nrow(d))) {
    if (d$is_training_eligible[i]) {
      ei <- setdiff(e_idx, i)
      d$loo_slope[i] <- prop_slope(d$Pb_clay_pred[ei], d$Pb_icpms[ei])
    } else {
      d$loo_slope[i] <- full
    }
  }
  loo_slopes_eligible <- d$loo_slope[d$is_training_eligible]

  df_arm <- df_arm %>%
    left_join(d %>% select(sample_id, cooks_D, is_training_eligible, loo_slope),
              by = "sample_id") %>%
    mutate(
      matrix_slope_full = full,
      matrix_slope_used = if_else(!is.na(loo_slope), loo_slope, full),
      predicted_Pb_ppm  = Pb_clay_pred * matrix_slope_used
    )

  list(
    df = df_arm,
    summary = tibble(
      arm                  = arm_label,
      method               = df_arm$method[1],
      response_type        = response_type,
      n_paired_total       = nrow(d),
      n_training_eligible  = length(e_idx),
      n_excluded           = nrow(d) - length(e_idx),
      excluded_samples     = if (length(excluded_ids))
                               paste(excluded_ids, collapse = ";") else "",
      matrix_slope_full    = full,
      matrix_slope_LOO_min = min(loo_slopes_eligible),
      matrix_slope_LOO_max = max(loo_slopes_eligible),
      matrix_slope_LOO_sd  = sd(loo_slopes_eligible)
    )
  )
}

per_arm <- predictions %>% group_split(arm) %>% map(fit_correction_arm)
predictions <- map_dfr(per_arm, "df")
correction_summary <- map_dfr(per_arm, "summary")

write_csv(correction_summary,
          file.path(ROOT, "data/validation/ash_matrix_correction_4arms.csv"))

predictions <- predictions %>%
  select(sample_id, method, arm, response_label, formula_rhs,
         Pb_clay_pred, matrix_slope_used, matrix_slope_full,
         predicted_Pb_ppm)

write_csv(predictions, file.path(ROOT, "data/validation/ash_predicted_Pb.csv"))

cat("\n=== Matrix correction (4 arms) ===\n")
print(correction_summary %>%
        mutate(across(where(is.numeric), ~ round(.x, 4))),
      n = Inf)

cat("\n=== Predictions (matrix-corrected) ===\n")
cat("Rows:", nrow(predictions), "\n")
cat("Per arm:\n"); print(count(predictions, arm))
cat("\nPredicted Pb_ppm summary by arm:\n")
print(predictions %>% group_by(arm) %>%
        summarise(n      = n(),
                  median = round(median(predicted_Pb_ppm, na.rm = TRUE), 1),
                  mean   = round(mean(predicted_Pb_ppm, na.rm = TRUE), 1),
                  max    = round(max(predicted_Pb_ppm, na.rm = TRUE), 1),
                  .groups = "drop"))

cat("\nWritten:\n")
cat("  ", file.path(ROOT, "data/validation/ash_matrix_correction_4arms.csv"), "\n")
cat("  ", file.path(ROOT, "data/validation/ash_predicted_Pb.csv"), "\n")
