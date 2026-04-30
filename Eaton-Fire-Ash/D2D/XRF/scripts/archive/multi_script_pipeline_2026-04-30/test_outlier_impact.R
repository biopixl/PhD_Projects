#!/usr/bin/env Rscript
# =============================================================================
# Outlier impact on matrix correction & threshold performance
# =============================================================================
# The paired ash dataset is dominated by one extreme sample (XPAH28, ICP-MS
# Pb=18,528 ppm — 10× higher than the next-highest sample) and a handful of
# moderately high samples (XPAH20=1933, JPL73=804). The matrix-correction
# proportional regression slope = Σxy/Σx² is leverage-sensitive: XPAH28's x²
# alone dominates the denominator. This script tests whether excluding such
# high-leverage samples from MATRIX-CORRECTION TRAINING (while still
# evaluating on the full paired set) improves threshold performance for the
# 70% of samples that sit below 80 ppm.
#
# Strategies (evaluated for each of the 4 arms):
#   S1. All_LOOCV         — current default (slope refit leaving each sample
#                           out).
#   S2. Drop_XPAH28       — exclude only the 18,528 ppm extreme.
#   S3. Drop_top2         — exclude XPAH28 + XPAH20 (>1500 ppm).
#   S4. Drop_top3         — exclude XPAH28 + XPAH20 + JPL73 (>800 ppm).
#   S5. CapICPMS_1000     — exclude all samples >1000 ppm from training.
#   S6. CapICPMS_500      — exclude all samples >500 ppm.
#   S7. CooksD            — exclude samples with Cook's D > 4/n in the
#                           proportional regression.
#
# All strategies use LOOCV among the eligible samples; ineligible samples
# (training-excluded outliers) get the full-fit slope of the eligible set.
# Validation metrics are computed on the COMPLETE paired set (37 samples).
#
# Output: results/Table_outlier_strategy_comparison.csv
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

ROOT <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D/XRF"
REPO <- "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/D2D"
THRESHOLDS_PPM <- c(80, 200, 320, 500, 800, 1000)

ash_pred <- read_csv(file.path(ROOT, "data/validation/ash_predicted_Pb.csv"),
                     show_col_types = FALSE) %>%
  select(sample_id, method, arm, Pb_clay_pred)
icpms <- read_csv(file.path(REPO, "ICPMS/EFA_ICPMS_PPM.csv"),
                  show_col_types = FALSE) %>%
  select(sample_id = EFA.ID, Pb_icpms = Pb)

paired <- ash_pred %>%
  inner_join(icpms, by = "sample_id") %>%
  filter(!is.na(Pb_clay_pred), !is.na(Pb_icpms), Pb_clay_pred > 0)

prop_slope <- function(x, y) sum(x * y) / sum(x * x)

# Cook's D for proportional regression y = b·x:
#   leverage h_i = x_i^2 / Σx²
#   r_i = y_i - b·x_i
#   D_i = r_i² × h_i / ((1 - h_i)² × s²)   with s² = Σr²/(n-1)
cooks_d_prop <- function(x, y) {
  b   <- prop_slope(x, y)
  r   <- y - b * x
  h   <- x^2 / sum(x^2)
  s2  <- sum(r^2) / (length(r) - 1)
  (r^2 * h) / ((1 - h)^2 * s2)
}

# -----------------------------------------------------------------------------
# Per-arm strategy evaluator
# -----------------------------------------------------------------------------

eval_strategy <- function(d, eligible_idx, label) {
  d$is_eligible <- FALSE; d$is_eligible[eligible_idx] <- TRUE
  e <- d[eligible_idx, ]

  # LOOCV among eligible; slope-extrapolation for ineligible.
  full_slope <- prop_slope(e$Pb_clay_pred, e$Pb_icpms)
  preds <- numeric(nrow(d))
  for (i in seq_len(nrow(d))) {
    if (d$is_eligible[i]) {
      ei <- eligible_idx[eligible_idx != i]
      s  <- prop_slope(d$Pb_clay_pred[ei], d$Pb_icpms[ei])
    } else {
      s  <- full_slope
    }
    preds[i] <- d$Pb_clay_pred[i] * s
  }
  d$predicted_Pb_ppm <- preds

  # Metrics on the FULL paired set
  resid   <- d$predicted_Pb_ppm - d$Pb_icpms
  ba_diff <- d$Pb_icpms - d$predicted_Pb_ppm
  cls <- function(t, p) {
    TP <- sum(t & p); TN <- sum(!t & !p); FP <- sum(!t & p); FN <- sum(t & !p)
    list(sens = if (TP+FN>0) TP/(TP+FN) else NA_real_,
         spec = if (TN+FP>0) TN/(TN+FP) else NA_real_,
         acc  = (TP+TN)/max(TP+TN+FP+FN,1))
  }
  thr <- map_dfc(THRESHOLDS_PPM, function(t) {
    m <- cls(d$Pb_icpms > t, d$predicted_Pb_ppm > t)
    tibble(!!paste0("sens_",t):=m$sens,
           !!paste0("spec_",t):=m$spec)
  })

  base <- tibble(
    strategy        = label,
    n_train         = nrow(e),
    n_eval          = nrow(d),
    matrix_slope_full = full_slope,
    pearson_r       = cor(d$predicted_Pb_ppm, d$Pb_icpms),
    RMSE_ppm        = sqrt(mean(resid^2)),
    MAE_ppm         = mean(abs(resid)),
    BA_bias_ppm     = mean(ba_diff),
    BA_LOA_range    = 2 * 1.96 * sd(ba_diff)
  )
  bind_cols(base, thr)
}

# -----------------------------------------------------------------------------
# Run all strategies × all arms
# -----------------------------------------------------------------------------

run_arm <- function(arm_label) {
  d <- paired %>% filter(arm == arm_label) %>% as.data.frame()
  n <- nrow(d)
  cooks <- cooks_d_prop(d$Pb_clay_pred, d$Pb_icpms)

  strategies <- list(
    list(label = "S1_All_LOOCV",     idx = seq_len(n)),
    list(label = "S2_Drop_XPAH28",   idx = which(d$sample_id != "XPAH28")),
    list(label = "S3_Drop_top2",     idx = which(!d$sample_id %in% c("XPAH28","XPAH20"))),
    list(label = "S4_Drop_top3",     idx = which(!d$sample_id %in% c("XPAH28","XPAH20","JPL73"))),
    list(label = "S5_CapICPMS_1000", idx = which(d$Pb_icpms <= 1000)),
    list(label = "S6_CapICPMS_500",  idx = which(d$Pb_icpms <= 500)),
    list(label = "S7_CooksD",        idx = which(cooks <= 4/n))
  )

  map_dfr(strategies, function(s)
    eval_strategy(d, s$idx, s$label) %>%
      mutate(arm = arm_label, .before = 1))
}

results <- map_dfr(unique(paired$arm), run_arm)

write_csv(results,
          file.path(ROOT, "results/Table_outlier_strategy_comparison.csv"))

cat("=== Outlier impact on matrix correction (all 4 arms × 7 strategies) ===\n")
cat("All strategies use LOOCV among eligible training samples.\n")
cat("Validation metrics computed on the FULL paired set (n=37).\n\n")

for (a in unique(results$arm)) {
  cat("--- Arm:", a, "---\n")
  print(results %>% filter(arm == a) %>%
          select(strategy, n_train, matrix_slope_full,
                 pearson_r, RMSE_ppm, MAE_ppm,
                 BA_bias_ppm, BA_LOA_range,
                 sens_80, sens_200, sens_320, sens_500, sens_800, sens_1000) %>%
          mutate(across(where(is.numeric), ~ round(.x, 2))),
        n = Inf, width = 200)
  cat("\n")
}

cat("Written:", file.path(ROOT, "results/Table_outlier_strategy_comparison.csv"), "\n")
