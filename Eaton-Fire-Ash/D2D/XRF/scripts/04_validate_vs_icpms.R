#!/usr/bin/env Rscript
# =============================================================================
# 04 — Validate ash predictions against ICP-MS gold standard
# =============================================================================
# For each ash sample×arm prediction, join the ICP-MS Pb measurement and
# produce the headline validation summary that downstream tables and figures
# read from. Three families of statistics:
#
#   Correlation/error: Pearson r, R², RMSE, MAE, mean residual.
#   Bland-Altman: bias and 95% limits of agreement (LOA) on absolute and
#       percent difference, plus geometric ratio. BA is reported alongside
#       R²/RMSE because high R² with wide LOA still means poor agreement
#       — see Bland & Altman 1986. The summary file is the single source
#       of truth for downstream Table 3 and the BA figure.
#   Threshold classification: sensitivity / specificity / accuracy at
#       6 regulatory thresholds (80, 200, 320, 500, 800, 1000 ppm).
#
# Inputs:
#   data/validation/ash_predicted_Pb.csv
#   ../ICPMS/EFA_ICPMS_PPM.csv          (Base_ID joined on EFA.ID)
#
# Outputs:
#   data/validation/validation_paired.csv          (long: sample × arm)
#   data/validation/validation_summary_4arms.csv   (4 rows; r/R²/RMSE +
#                                                   BA + threshold metrics)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D"

THRESHOLDS_PPM <- c(80, 200, 320, 500, 800, 1000)

predictions <- read_csv(file.path(ROOT, "XRF/data/validation/ash_predicted_Pb.csv"),
                        show_col_types = FALSE)
icpms <- read_csv(file.path(ROOT, "ICPMS/EFA_ICPMS_PPM.csv"),
                  show_col_types = FALSE) %>%
  select(Base_ID = EFA.ID, Sample_Type = alq.type, Pb_icpms = Pb,
         Lat, Lon)

paired <- predictions %>%
  inner_join(icpms, by = c("sample_id" = "Base_ID")) %>%
  mutate(
    residual_ppm     = predicted_Pb_ppm - Pb_icpms,
    abs_residual_ppm = abs(residual_ppm),
    pct_error        = 100 * residual_ppm / Pb_icpms,
    # Bland-Altman per-row terms
    ba_mean          = (Pb_icpms + predicted_Pb_ppm) / 2,
    ba_diff          = Pb_icpms - predicted_Pb_ppm,
    ba_pct           = 100 * ba_diff / ba_mean,
    ba_lograt        = if_else(predicted_Pb_ppm > 0 & Pb_icpms > 0,
                               log10(Pb_icpms / predicted_Pb_ppm), NA_real_)
  ) %>%
  select(sample_id, method, arm, Sample_Type,
         Pb_icpms, predicted_Pb_ppm,
         residual_ppm, abs_residual_ppm, pct_error,
         ba_mean, ba_diff, ba_pct, ba_lograt)

write_csv(paired,
          file.path(ROOT, "XRF/data/validation/validation_paired.csv"))

cat("=== 04 — Validation pairing ===\n")
cat("Paired ash samples:", n_distinct(paired$sample_id), "\n")
cat("Thresholds (ppm):", paste(THRESHOLDS_PPM, collapse = ", "), "\n")
cat("Per arm:\n"); print(count(paired, arm))

# -----------------------------------------------------------------------------
# Per-arm summary statistics
# -----------------------------------------------------------------------------

classify_metrics <- function(truth, pred, threshold) {
  t_above <- truth > threshold
  p_above <- pred  > threshold
  TP <- sum( t_above &  p_above, na.rm = TRUE)
  TN <- sum(!t_above & !p_above, na.rm = TRUE)
  FP <- sum(!t_above &  p_above, na.rm = TRUE)
  FN <- sum( t_above & !p_above, na.rm = TRUE)
  list(
    sens = if ((TP + FN) > 0) TP / (TP + FN) else NA_real_,
    spec = if ((TN + FP) > 0) TN / (TN + FP) else NA_real_,
    acc  = (TP + TN) / max(TP + TN + FP + FN, 1)
  )
}

# -----------------------------------------------------------------------------
# Correlation + Bland-Altman per arm
# -----------------------------------------------------------------------------

base_stats <- paired %>% group_by(arm, method) %>%
  summarise(
    n              = n(),
    pearson_r      = cor(predicted_Pb_ppm, Pb_icpms, use = "complete.obs"),
    r_squared      = pearson_r^2,
    RMSE_ppm       = sqrt(mean(residual_ppm^2, na.rm = TRUE)),
    MAE_ppm        = mean(abs_residual_ppm, na.rm = TRUE),
    mean_bias_ppm  = mean(residual_ppm, na.rm = TRUE),
    median_pct_err = median(pct_error, na.rm = TRUE),
    # Bland-Altman: bias and 95% LOA on absolute differences (ICP-MS − XRF)
    BA_bias_ppm    = mean(ba_diff, na.rm = TRUE),
    BA_sd_ppm      = sd(ba_diff,   na.rm = TRUE),
    BA_LOA_lo_ppm  = BA_bias_ppm - 1.96 * BA_sd_ppm,
    BA_LOA_hi_ppm  = BA_bias_ppm + 1.96 * BA_sd_ppm,
    BA_LOA_range   = BA_LOA_hi_ppm - BA_LOA_lo_ppm,
    # Bland-Altman: percent difference
    BA_pct_bias    = mean(ba_pct, na.rm = TRUE),
    BA_pct_sd      = sd(ba_pct,   na.rm = TRUE),
    BA_pct_LOA_lo  = BA_pct_bias - 1.96 * BA_pct_sd,
    BA_pct_LOA_hi  = BA_pct_bias + 1.96 * BA_pct_sd,
    # Bland-Altman: geometric ratio (multiplicative agreement)
    BA_geom_ratio  = 10^mean(ba_lograt, na.rm = TRUE),
    .groups = "drop"
  )

# -----------------------------------------------------------------------------
# Per-threshold classification for the 6 regulatory levels
# -----------------------------------------------------------------------------

threshold_stats <- map_dfr(THRESHOLDS_PPM, function(t) {
  paired %>% group_by(arm, method) %>%
    summarise(
      threshold = t,
      sens = classify_metrics(Pb_icpms, predicted_Pb_ppm, t)$sens,
      spec = classify_metrics(Pb_icpms, predicted_Pb_ppm, t)$spec,
      acc  = classify_metrics(Pb_icpms, predicted_Pb_ppm, t)$acc,
      .groups = "drop"
    )
})

# Wide format: one row per arm with sens_<T>, spec_<T>, acc_<T> columns
threshold_wide <- threshold_stats %>%
  pivot_wider(id_cols = c(arm, method),
              names_from = threshold,
              values_from = c(sens, spec, acc),
              names_glue = "{.value}_{threshold}")

per_arm <- base_stats %>%
  left_join(threshold_wide, by = c("arm", "method")) %>%
  arrange(method, arm)

write_csv(per_arm,
          file.path(ROOT, "XRF/data/validation/validation_summary_4arms.csv"))

# Long-format threshold table — convenient for figures and Table 4.
write_csv(threshold_stats,
          file.path(ROOT, "XRF/data/validation/validation_thresholds_long.csv"))

cat("\n=== 4-arm validation summary (correlation + BA + thresholds) ===\n")
print(per_arm %>%
        select(arm, method, n, pearson_r, RMSE_ppm, MAE_ppm,
               BA_bias_ppm, BA_LOA_lo_ppm, BA_LOA_hi_ppm) %>%
        mutate(across(where(is.numeric), ~ round(.x, 1))),
      n = Inf)

cat("\n=== Threshold classification (sensitivity/specificity/accuracy) ===\n")
print(threshold_stats %>%
        mutate(across(where(is.numeric), ~ round(.x, 3))) %>%
        arrange(method, arm, threshold),
      n = Inf)

cat("\nWritten:\n")
cat("  ", file.path(ROOT, "XRF/data/validation/validation_paired.csv"), "\n")
cat("  ", file.path(ROOT, "XRF/data/validation/validation_summary_4arms.csv"), "\n")
cat("  ", file.path(ROOT, "XRF/data/validation/validation_thresholds_long.csv"), "\n")
