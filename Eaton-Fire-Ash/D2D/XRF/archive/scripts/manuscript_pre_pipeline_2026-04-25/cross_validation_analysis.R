#!/usr/bin/env Rscript
# =============================================================================
# Cross-Validation Analysis for XRF Calibration
# =============================================================================
# PROBLEM: Current analysis is circular
#   - Model trained on ALL samples
#   - R² evaluated on SAME samples
#   - This doesn't assess generalization to new samples
#
# SOLUTION: Proper cross-validation
#   - Leave-one-out CV (LOOCV) - each sample predicted by model trained on others
#   - K-fold CV - similar but in groups
#   - Bootstrap validation - repeated resampling with replacement
#
# This gives honest estimate of prediction error on unseen samples
# =============================================================================

library(tidyverse)
library(boot)

set.seed(42)  # Reproducibility

cat("=============================================================================\n")
cat("CROSS-VALIDATION ANALYSIS FOR XRF CALIBRATION\n")
cat("Addressing circularity in model evaluation\n")
cat("=============================================================================\n\n")

# =============================================================================
# 1. Load Data
# =============================================================================

df <- read_csv("harmonized_xrf_icpms_Lb_paired.csv", show_col_types = FALSE)

cat("Total paired samples:", nrow(df), "\n\n")

# =============================================================================
# 2. Current (Circular) Approach - For Comparison
# =============================================================================

cat("=============================================================================\n")
cat("CURRENT APPROACH (CIRCULAR - FOR REFERENCE ONLY)\n")
cat("=============================================================================\n\n")

# Fit on ALL data
model_full <- lm(Pb_icpms ~ Pb_Lb_sum, data = df)
df$pred_full <- predict(model_full)
df$resid_full <- df$Pb_icpms - df$pred_full

# In-sample metrics (these are BIASED - too optimistic)
r2_insample <- summary(model_full)$r.squared
rmse_insample <- sqrt(mean(df$resid_full^2))

cat("In-sample (circular) metrics:\n")
cat(sprintf("  R² = %.4f\n", r2_insample))
cat(sprintf("  RMSE = %.1f ppm\n", rmse_insample))
cat("\n  WARNING: These metrics are overly optimistic!\n")
cat("  They evaluate on the SAME data used to fit the model.\n\n")

# =============================================================================
# 3. Leave-One-Out Cross-Validation (LOOCV)
# =============================================================================

cat("=============================================================================\n")
cat("LEAVE-ONE-OUT CROSS-VALIDATION (LOOCV)\n")
cat("=============================================================================\n\n")

cat("For each sample:\n")
cat("  1. Remove that sample from training data\n")
cat("  2. Fit model on remaining n-1 samples\n")
cat("  3. Predict the held-out sample\n")
cat("  4. Record prediction error\n\n")

# LOOCV predictions
loocv_results <- tibble(
  Base_ID = character(),
  Pb_icpms = numeric(),
  Pb_Lb_sum = numeric(),
  pred_loocv = numeric(),
  resid_loocv = numeric(),
  model_intercept = numeric(),
  model_slope = numeric()
)

for (i in 1:nrow(df)) {
  # Training data: all except sample i
  df_train <- df[-i, ]
  df_test <- df[i, ]

  # Fit model on training data
  model_cv <- lm(Pb_icpms ~ Pb_Lb_sum, data = df_train)

  # Predict held-out sample
  pred <- predict(model_cv, newdata = df_test)

  loocv_results <- bind_rows(loocv_results, tibble(
    Base_ID = df_test$Base_ID,
    Pb_icpms = df_test$Pb_icpms,
    Pb_Lb_sum = df_test$Pb_Lb_sum,
    pred_loocv = pred,
    resid_loocv = df_test$Pb_icpms - pred,
    model_intercept = coef(model_cv)[1],
    model_slope = coef(model_cv)[2]
  ))
}

# LOOCV metrics
r2_loocv <- 1 - sum(loocv_results$resid_loocv^2) / sum((loocv_results$Pb_icpms - mean(loocv_results$Pb_icpms))^2)
rmse_loocv <- sqrt(mean(loocv_results$resid_loocv^2))
mae_loocv <- mean(abs(loocv_results$resid_loocv))

cat("LOOCV Results:\n")
cat(sprintf("  R² (cross-validated) = %.4f\n", r2_loocv))
cat(sprintf("  RMSE (cross-validated) = %.1f ppm\n", rmse_loocv))
cat(sprintf("  MAE (cross-validated) = %.1f ppm\n", mae_loocv))

cat("\nComparison to in-sample metrics:\n")
cat(sprintf("  R² dropped from %.4f to %.4f (Δ = %.4f)\n",
            r2_insample, r2_loocv, r2_insample - r2_loocv))
cat(sprintf("  RMSE increased from %.1f to %.1f ppm (Δ = %.1f ppm)\n",
            rmse_insample, rmse_loocv, rmse_loocv - rmse_insample))

# =============================================================================
# 4. Model Stability Analysis
# =============================================================================

cat("\n=============================================================================\n")
cat("MODEL STABILITY ACROSS LOOCV FOLDS\n")
cat("=============================================================================\n\n")

cat("How much do model coefficients change when one sample is removed?\n\n")

intercept_range <- range(loocv_results$model_intercept)
slope_range <- range(loocv_results$model_slope)

cat(sprintf("Full model: Intercept = %.1f, Slope = %.4f\n",
            coef(model_full)[1], coef(model_full)[2]))
cat(sprintf("LOOCV Intercept range: [%.1f, %.1f]\n", intercept_range[1], intercept_range[2]))
cat(sprintf("LOOCV Slope range: [%.4f, %.4f]\n", slope_range[1], slope_range[2]))

# Identify influential samples
loocv_results <- loocv_results %>%
  mutate(
    intercept_change = abs(model_intercept - coef(model_full)[1]),
    slope_change = abs(model_slope - coef(model_full)[2])
  )

influential <- loocv_results %>%
  filter(intercept_change > 50 | slope_change > 0.1) %>%
  arrange(desc(intercept_change))

if (nrow(influential) > 0) {
  cat("\nInfluential samples (removing them changes model substantially):\n")
  print(influential %>% select(Base_ID, Pb_icpms, intercept_change, slope_change), n = 5)
}

# =============================================================================
# 5. Bootstrap Cross-Validation
# =============================================================================

cat("\n=============================================================================\n")
cat("BOOTSTRAP VALIDATION (1000 iterations)\n")
cat("=============================================================================\n\n")

cat("For each bootstrap iteration:\n")
cat("  1. Resample n samples WITH replacement (training set)\n")
cat("  2. Fit model on bootstrap sample\n")
cat("  3. Predict OUT-OF-BAG samples (not selected in this iteration)\n")
cat("  4. Record prediction errors on OOB samples\n\n")

n_boot <- 1000
boot_results <- tibble(
  iteration = integer(),
  n_train = integer(),
  n_oob = integer(),
  r2_oob = numeric(),
  rmse_oob = numeric(),
  intercept = numeric(),
  slope = numeric()
)

for (b in 1:n_boot) {
  # Bootstrap sample (with replacement)
  idx_train <- sample(1:nrow(df), size = nrow(df), replace = TRUE)
  idx_oob <- setdiff(1:nrow(df), unique(idx_train))

  if (length(idx_oob) < 3) next  # Skip if too few OOB samples

  df_train <- df[idx_train, ]
  df_oob <- df[idx_oob, ]

  # Fit model
  model_boot <- lm(Pb_icpms ~ Pb_Lb_sum, data = df_train)

  # Predict OOB
  pred_oob <- predict(model_boot, newdata = df_oob)
  resid_oob <- df_oob$Pb_icpms - pred_oob

  # OOB metrics
  ss_res <- sum(resid_oob^2)
  ss_tot <- sum((df_oob$Pb_icpms - mean(df_oob$Pb_icpms))^2)
  r2_oob <- ifelse(ss_tot > 0, 1 - ss_res / ss_tot, NA)
  rmse_oob <- sqrt(mean(resid_oob^2))

  boot_results <- bind_rows(boot_results, tibble(
    iteration = b,
    n_train = length(idx_train),
    n_oob = length(idx_oob),
    r2_oob = r2_oob,
    rmse_oob = rmse_oob,
    intercept = coef(model_boot)[1],
    slope = coef(model_boot)[2]
  ))
}

# Summarize bootstrap results
boot_summary <- boot_results %>%
  filter(!is.na(r2_oob)) %>%
  summarise(
    n_valid = n(),
    r2_mean = mean(r2_oob),
    r2_median = median(r2_oob),
    r2_sd = sd(r2_oob),
    r2_ci_lower = quantile(r2_oob, 0.025),
    r2_ci_upper = quantile(r2_oob, 0.975),
    rmse_mean = mean(rmse_oob),
    rmse_median = median(rmse_oob),
    rmse_sd = sd(rmse_oob),
    rmse_ci_lower = quantile(rmse_oob, 0.025),
    rmse_ci_upper = quantile(rmse_oob, 0.975)
  )

cat("Bootstrap OOB Performance (", boot_summary$n_valid, " valid iterations):\n\n", sep = "")
cat("  R² (out-of-bag):\n")
cat(sprintf("    Mean = %.4f, Median = %.4f\n", boot_summary$r2_mean, boot_summary$r2_median))
cat(sprintf("    95%% CI: [%.4f, %.4f]\n", boot_summary$r2_ci_lower, boot_summary$r2_ci_upper))
cat(sprintf("    SD = %.4f\n", boot_summary$r2_sd))

cat("\n  RMSE (out-of-bag):\n")
cat(sprintf("    Mean = %.1f ppm, Median = %.1f ppm\n", boot_summary$rmse_mean, boot_summary$rmse_median))
cat(sprintf("    95%% CI: [%.1f, %.1f] ppm\n", boot_summary$rmse_ci_lower, boot_summary$rmse_ci_upper))

# =============================================================================
# 6. Threshold Classification with CV
# =============================================================================

cat("\n=============================================================================\n")
cat("THRESHOLD CLASSIFICATION WITH CROSS-VALIDATION\n")
cat("=============================================================================\n\n")

thresholds <- c(80, 200, 400, 1000)

# Using LOOCV predictions
loocv_results <- loocv_results %>%
  mutate(pred_positive = pred_loocv > 0)

cv_classification <- tibble()

for (thresh in thresholds) {
  # Using CV predictions (honest)
  df_cv <- loocv_results %>%
    filter(pred_positive) %>%  # Only valid predictions
    mutate(
      true_above = Pb_icpms >= thresh,
      pred_above = pred_loocv >= thresh
    )

  TP_cv <- sum(df_cv$true_above & df_cv$pred_above)
  TN_cv <- sum(!df_cv$true_above & !df_cv$pred_above)
  FP_cv <- sum(!df_cv$true_above & df_cv$pred_above)
  FN_cv <- sum(df_cv$true_above & !df_cv$pred_above)

  sens_cv <- TP_cv / (TP_cv + FN_cv)
  spec_cv <- TN_cv / (TN_cv + FP_cv)

  # Using in-sample predictions (biased)
  df_insample <- df %>%
    filter(pred_full > 0) %>%
    mutate(
      true_above = Pb_icpms >= thresh,
      pred_above = pred_full >= thresh
    )

  TP_is <- sum(df_insample$true_above & df_insample$pred_above)
  TN_is <- sum(!df_insample$true_above & !df_insample$pred_above)
  FP_is <- sum(!df_insample$true_above & df_insample$pred_above)
  FN_is <- sum(df_insample$true_above & !df_insample$pred_above)

  sens_is <- TP_is / (TP_is + FN_is)
  spec_is <- TN_is / (TN_is + FP_is)

  cv_classification <- bind_rows(cv_classification, tibble(
    threshold = thresh,
    sens_insample = sens_is,
    sens_cv = sens_cv,
    sens_drop = sens_is - sens_cv,
    spec_insample = spec_is,
    spec_cv = spec_cv,
    spec_drop = spec_is - spec_cv,
    FN_cv = FN_cv,
    FP_cv = FP_cv
  ))
}

cat("Classification Performance: In-Sample vs Cross-Validated\n")
cat("─────────────────────────────────────────────────────────────────────────────\n")
cat(sprintf("%-10s %12s %12s %8s %12s %12s %8s\n",
            "Threshold", "Sens(in)", "Sens(CV)", "Δ", "Spec(in)", "Spec(CV)", "Δ"))
cat("─────────────────────────────────────────────────────────────────────────────\n")
for (i in 1:nrow(cv_classification)) {
  r <- cv_classification[i, ]
  cat(sprintf("%-10d %12.1f%% %12.1f%% %8.1f%% %12.1f%% %12.1f%% %8.1f%%\n",
              r$threshold,
              r$sens_insample * 100, r$sens_cv * 100, r$sens_drop * 100,
              r$spec_insample * 100, r$spec_cv * 100, r$spec_drop * 100))
}

# =============================================================================
# 7. What to Expect with New Samples
# =============================================================================

cat("\n=============================================================================\n")
cat("EXPECTED PERFORMANCE ON NEW SAMPLES\n")
cat("=============================================================================\n\n")

cat("Based on bootstrap OOB validation, if you calibrate with these 35 samples\n")
cat("and then measure 100 NEW ash samples with XRF:\n\n")

cat(sprintf("  Expected R² = %.2f (95%% CI: %.2f - %.2f)\n",
            boot_summary$r2_median, boot_summary$r2_ci_lower, boot_summary$r2_ci_upper))
cat(sprintf("  Expected RMSE = %.0f ppm (95%% CI: %.0f - %.0f ppm)\n",
            boot_summary$rmse_median, boot_summary$rmse_ci_lower, boot_summary$rmse_ci_upper))

cat("\nInterpretation:\n")
if (boot_summary$r2_median < 0.9) {
  cat("  - R² drops substantially from in-sample estimate\n")
  cat("  - The 0.994 figure is overly optimistic\n")
}
if (boot_summary$rmse_ci_upper > 500) {
  cat("  - RMSE could be quite high (>500 ppm) on new samples\n")
  cat("  - Prediction uncertainty is substantial\n")
}

# =============================================================================
# 8. Summary Comparison
# =============================================================================

cat("\n=============================================================================\n")
cat("SUMMARY: CIRCULAR vs CROSS-VALIDATED METRICS\n")
cat("=============================================================================\n\n")

comparison <- tibble(
  Metric = c("R²", "RMSE (ppm)", "MAE (ppm)"),
  `In-Sample (Circular)` = c(
    sprintf("%.4f", r2_insample),
    sprintf("%.0f", rmse_insample),
    sprintf("%.0f", mean(abs(df$resid_full)))
  ),
  `LOOCV` = c(
    sprintf("%.4f", r2_loocv),
    sprintf("%.0f", rmse_loocv),
    sprintf("%.0f", mae_loocv)
  ),
  `Bootstrap OOB` = c(
    sprintf("%.4f (%.4f-%.4f)", boot_summary$r2_median,
            boot_summary$r2_ci_lower, boot_summary$r2_ci_upper),
    sprintf("%.0f (%.0f-%.0f)", boot_summary$rmse_median,
            boot_summary$rmse_ci_lower, boot_summary$rmse_ci_upper),
    "—"
  )
)

cat("─────────────────────────────────────────────────────────────────────────────\n")
cat(sprintf("%-12s %20s %15s %25s\n", "Metric", "In-Sample", "LOOCV", "Bootstrap OOB (95% CI)"))
cat("─────────────────────────────────────────────────────────────────────────────\n")
for (i in 1:nrow(comparison)) {
  cat(sprintf("%-12s %20s %15s %25s\n",
              comparison$Metric[i],
              comparison$`In-Sample (Circular)`[i],
              comparison$LOOCV[i],
              comparison$`Bootstrap OOB`[i]))
}

cat("\n")
cat("KEY FINDING: The in-sample R² of 0.994 is inflated.\n")
cat(sprintf("Cross-validated R² = %.3f is the honest estimate of generalization.\n", r2_loocv))
cat(sprintf("The in-sample approach overestimates R² by %.3f (%.1f%% relative).\n",
            r2_insample - r2_loocv, (r2_insample - r2_loocv) / r2_loocv * 100))

# =============================================================================
# 9. Save Results
# =============================================================================

write_csv(loocv_results, "Table_LOOCV_predictions.csv")
write_csv(cv_classification, "Table_CV_classification.csv")
write_csv(boot_results, "Table_bootstrap_results.csv")

# Summary for manuscript
cv_summary <- tibble(
  Metric = c("R² (in-sample)", "R² (LOOCV)", "R² (Bootstrap OOB median)",
             "R² 95% CI lower", "R² 95% CI upper",
             "RMSE in-sample (ppm)", "RMSE LOOCV (ppm)", "RMSE Bootstrap median (ppm)",
             "RMSE 95% CI lower (ppm)", "RMSE 95% CI upper (ppm)"),
  Value = c(r2_insample, r2_loocv, boot_summary$r2_median,
            boot_summary$r2_ci_lower, boot_summary$r2_ci_upper,
            rmse_insample, rmse_loocv, boot_summary$rmse_median,
            boot_summary$rmse_ci_lower, boot_summary$rmse_ci_upper)
)
write_csv(cv_summary, "Table_CV_summary.csv")

cat("\nOutput files saved:\n")
cat("  - Table_LOOCV_predictions.csv\n")
cat("  - Table_CV_classification.csv\n")
cat("  - Table_bootstrap_results.csv\n")
cat("  - Table_CV_summary.csv\n")

cat("\n=============================================================================\n")
cat("Analysis complete.\n")
cat("=============================================================================\n")
