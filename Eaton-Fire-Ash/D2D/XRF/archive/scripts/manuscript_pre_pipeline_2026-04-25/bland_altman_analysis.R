#!/usr/bin/env Rscript
# =============================================================================
# Bland-Altman Method Agreement Analysis for XRF-ICP-MS Comparison
# =============================================================================
# Addresses limitations of R² for method comparison:
# 1. R² doesn't show concentration-dependent errors
# 2. R² doesn't capture systematic bias
# 3. R² doesn't test for 1:1 relationship
# 4. High-concentration outliers dominate R²
# 5. Log-log plots compress error visibility
#
# This script implements proper method agreement analysis following:
# - Bland & Altman (1986) Lancet
# - Giavarina (2015) Biochemia Medica
# =============================================================================

library(tidyverse)
library(patchwork)
library(broom)

# =============================================================================
# 1. Load Data
# =============================================================================

cat("=== Bland-Altman Method Agreement Analysis ===\n\n")

# Load the paired ICP-MS and L-line data
df <- read_csv(
 "harmonized_xrf_icpms_Lb_paired.csv",
 show_col_types = FALSE
)

cat("Loaded", nrow(df), "paired samples\n\n")

# =============================================================================
# 2. Refit L-line Calibration Model (for transparency)
# =============================================================================

# Model: ICP-MS Pb ~ Pb Lβ counts
model_Lb <- lm(Pb_icpms ~ Pb_Lb_sum, data = df)

cat("L-line Calibration Model:\n")
cat("  ICP-MS Pb = ", round(coef(model_Lb)[1], 1), " + ",
    round(coef(model_Lb)[2], 4), " × (Lβ1 + Lβ2 counts)\n", sep = "")
cat("  R² = ", round(summary(model_Lb)$r.squared, 4), "\n")
cat("  RMSE = ", round(sqrt(mean(model_Lb$residuals^2)), 1), " ppm\n\n")

# Generate predictions
df <- df %>%
 mutate(
   Pb_pred_Lb = predict(model_Lb, newdata = .),
   # Handle negative predictions (model limitation at low concentrations)
   Pb_pred_Lb_adj = pmax(Pb_pred_Lb, 1)  # Floor at 1 ppm for ratio calculations
 )

# =============================================================================
# 3. Bland-Altman Statistics
# =============================================================================

cat("=== Bland-Altman Analysis ===\n\n")

# Filter to samples with positive predictions for valid B-A analysis
df_valid <- df %>% filter(Pb_pred_Lb > 0)
cat("Samples with positive predictions:", nrow(df_valid), "of", nrow(df), "\n")

# Compute B-A metrics
df_valid <- df_valid %>%
 mutate(
   # Mean of two methods (x-axis in B-A plot)
   BA_mean = (Pb_icpms + Pb_pred_Lb) / 2,

   # Absolute difference (ICP-MS - XRF_calibrated)
   BA_diff = Pb_icpms - Pb_pred_Lb,

   # Percent difference (relative to mean)
   BA_pct_diff = (Pb_icpms - Pb_pred_Lb) / BA_mean * 100,

   # Ratio (multiplicative agreement)
   BA_ratio = Pb_icpms / Pb_pred_Lb,

   # Log ratio (for proportional bias assessment)
   BA_log_ratio = log10(Pb_icpms / Pb_pred_Lb)
 )

# Bland-Altman statistics
ba_stats <- list(
 # Absolute differences
 abs_mean_diff = mean(df_valid$BA_diff),
 abs_sd_diff = sd(df_valid$BA_diff),
 abs_loa_lower = mean(df_valid$BA_diff) - 1.96 * sd(df_valid$BA_diff),
 abs_loa_upper = mean(df_valid$BA_diff) + 1.96 * sd(df_valid$BA_diff),

 # Percent differences
 pct_mean_diff = mean(df_valid$BA_pct_diff),
 pct_sd_diff = sd(df_valid$BA_pct_diff),
 pct_loa_lower = mean(df_valid$BA_pct_diff) - 1.96 * sd(df_valid$BA_pct_diff),
 pct_loa_upper = mean(df_valid$BA_pct_diff) + 1.96 * sd(df_valid$BA_pct_diff),

 # Ratio-based (multiplicative)
 ratio_geometric_mean = 10^mean(df_valid$BA_log_ratio),
 ratio_loa_lower = 10^(mean(df_valid$BA_log_ratio) - 1.96 * sd(df_valid$BA_log_ratio)),
 ratio_loa_upper = 10^(mean(df_valid$BA_log_ratio) + 1.96 * sd(df_valid$BA_log_ratio))
)

# Calculate confidence intervals (per reporting standards)
n_valid <- nrow(df_valid)
se_bias <- ba_stats$abs_sd_diff / sqrt(n_valid)
ci_bias_lower <- ba_stats$abs_mean_diff - qt(0.975, n_valid - 1) * se_bias
ci_bias_upper <- ba_stats$abs_mean_diff + qt(0.975, n_valid - 1) * se_bias

# SE for LOA (Bland & Altman 1986)
se_loa <- sqrt(3 * ba_stats$abs_sd_diff^2 / n_valid)
ci_loa_lower_low <- ba_stats$abs_loa_lower - qt(0.975, n_valid - 1) * se_loa
ci_loa_lower_high <- ba_stats$abs_loa_lower + qt(0.975, n_valid - 1) * se_loa
ci_loa_upper_low <- ba_stats$abs_loa_upper - qt(0.975, n_valid - 1) * se_loa
ci_loa_upper_high <- ba_stats$abs_loa_upper + qt(0.975, n_valid - 1) * se_loa

cat("\n--- Absolute Difference (ppm) ---\n")
cat("  Mean bias: ", round(ba_stats$abs_mean_diff, 1), " ppm\n")
cat("    95% CI: [", round(ci_bias_lower, 1), ", ", round(ci_bias_upper, 1), "]\n")
cat("  SD: ", round(ba_stats$abs_sd_diff, 1), " ppm\n")
cat("  95% LOA: [", round(ba_stats$abs_loa_lower, 1), ", ",
    round(ba_stats$abs_loa_upper, 1), "] ppm\n")
cat("    Lower LOA 95% CI: [", round(ci_loa_lower_low, 1), ", ", round(ci_loa_lower_high, 1), "]\n")
cat("    Upper LOA 95% CI: [", round(ci_loa_upper_low, 1), ", ", round(ci_loa_upper_high, 1), "]\n")

cat("\n--- Percent Difference (%) ---\n")
cat("  Mean bias: ", round(ba_stats$pct_mean_diff, 1), "%\n")
cat("  SD: ", round(ba_stats$pct_sd_diff, 1), "%\n")
cat("  95% LOA: [", round(ba_stats$pct_loa_lower, 1), "%, ",
    round(ba_stats$pct_loa_upper, 1), "%]\n")

cat("\n--- Ratio (ICP-MS / XRF_calibrated) ---\n")
cat("  Geometric mean ratio: ", round(ba_stats$ratio_geometric_mean, 3), "\n")
cat("  95% LOA: [", round(ba_stats$ratio_loa_lower, 3), ", ",
    round(ba_stats$ratio_loa_upper, 3), "]\n")

# =============================================================================
# 4. Concentration-Dependent Error Analysis
# =============================================================================

cat("\n\n=== Concentration-Dependent Error Analysis ===\n")

# Define concentration bins
df_valid <- df_valid %>%
 mutate(
   conc_bin = cut(Pb_icpms,
                  breaks = c(0, 50, 100, 200, 400, 1000, Inf),
                  labels = c("<50", "50-100", "100-200", "200-400", "400-1000", ">1000"),
                  include.lowest = TRUE)
 )

# Statistics by concentration bin
conc_stats <- df_valid %>%
 group_by(conc_bin) %>%
 summarise(
   n = n(),
   mean_icpms = mean(Pb_icpms),
   mean_pred = mean(Pb_pred_Lb),
   mean_diff = mean(BA_diff),
   sd_diff = sd(BA_diff),
   mean_pct_diff = mean(BA_pct_diff),
   sd_pct_diff = sd(BA_pct_diff),
   mean_abs_error = mean(abs(BA_diff)),
   rmse = sqrt(mean(BA_diff^2)),
   .groups = "drop"
 )

cat("\nError by Concentration Range:\n")
cat("─────────────────────────────────────────────────────────────────────────\n")
cat(sprintf("%-12s %4s %10s %10s %10s %10s %10s\n",
            "Range (ppm)", "n", "Mean ICPMS", "Mean Pred", "Bias", "SD", "RMSE"))
cat("─────────────────────────────────────────────────────────────────────────\n")
for (i in 1:nrow(conc_stats)) {
 cat(sprintf("%-12s %4d %10.1f %10.1f %10.1f %10.1f %10.1f\n",
             conc_stats$conc_bin[i],
             conc_stats$n[i],
             conc_stats$mean_icpms[i],
             conc_stats$mean_pred[i],
             conc_stats$mean_diff[i],
             ifelse(is.na(conc_stats$sd_diff[i]), 0, conc_stats$sd_diff[i]),
             conc_stats$rmse[i]))
}

# =============================================================================
# 5. Threshold-Focused Analysis (Key Decision Points)
# =============================================================================

cat("\n\n=== Threshold-Focused Analysis ===\n")
cat("Evaluating agreement at regulatory decision thresholds\n\n")

thresholds <- c(80, 200, 400, 1000)

threshold_analysis <- function(df, threshold) {
 # Samples near threshold (within ±50% of threshold)
 near_threshold <- df %>%
   filter(Pb_icpms >= threshold * 0.5 & Pb_icpms <= threshold * 1.5)

 # Classification agreement
 df_class <- df %>%
   mutate(
     icpms_above = Pb_icpms >= threshold,
     pred_above = Pb_pred_Lb >= threshold,
     agree = icpms_above == pred_above,
     # Error type
     error_type = case_when(
       icpms_above & !pred_above ~ "False Negative",
       !icpms_above & pred_above ~ "False Positive",
       TRUE ~ "Correct"
     )
   )

 # Confusion matrix
 TP <- sum(df_class$icpms_above & df_class$pred_above)
 TN <- sum(!df_class$icpms_above & !df_class$pred_above)
 FP <- sum(!df_class$icpms_above & df_class$pred_above)
 FN <- sum(df_class$icpms_above & !df_class$pred_above)

 sensitivity <- TP / (TP + FN) * 100
 specificity <- TN / (TN + FP) * 100

 # Error analysis near threshold
 if (nrow(near_threshold) > 0) {
   near_rmse <- sqrt(mean(near_threshold$BA_diff^2))
   near_bias <- mean(near_threshold$BA_diff)
 } else {
   near_rmse <- NA
   near_bias <- NA
 }

 list(
   threshold = threshold,
   n_above_icpms = TP + FN,
   n_below_icpms = TN + FP,
   TP = TP, TN = TN, FP = FP, FN = FN,
   sensitivity = sensitivity,
   specificity = specificity,
   n_near = nrow(near_threshold),
   near_rmse = near_rmse,
   near_bias = near_bias
 )
}

threshold_results <- map(thresholds, ~threshold_analysis(df_valid, .x))

cat("─────────────────────────────────────────────────────────────────────────\n")
cat(sprintf("%-10s %5s %5s %5s %5s %8s %8s %6s %8s\n",
            "Threshold", "TP", "TN", "FP", "FN", "Sens(%)", "Spec(%)", "n_near", "RMSE_near"))
cat("─────────────────────────────────────────────────────────────────────────\n")
for (res in threshold_results) {
 cat(sprintf("%-10d %5d %5d %5d %5d %8.1f %8.1f %6d %8.1f\n",
             res$threshold,
             res$TP, res$TN, res$FP, res$FN,
             res$sensitivity, res$specificity,
             res$n_near,
             ifelse(is.na(res$near_rmse), 0, res$near_rmse)))
}

# =============================================================================
# 6. Proportional Bias Test
# =============================================================================

cat("\n\n=== Proportional Bias Assessment ===\n")
cat("Testing if error scales with concentration\n\n")

# Regress difference on mean (proportional bias test)
prop_bias_model <- lm(BA_diff ~ BA_mean, data = df_valid)
prop_bias_summary <- summary(prop_bias_model)

cat("Regression of (ICP-MS - Pred) on Mean:\n")
cat("  Slope: ", round(coef(prop_bias_model)[2], 4), "\n")
cat("  p-value: ", format.pval(prop_bias_summary$coefficients[2,4], digits = 3), "\n")
cat("  Interpretation: ",
    ifelse(prop_bias_summary$coefficients[2,4] < 0.05,
           "SIGNIFICANT proportional bias (error scales with concentration)",
           "No significant proportional bias"), "\n")

# Also test on percent difference (should be constant if proportional)
prop_bias_pct <- lm(BA_pct_diff ~ BA_mean, data = df_valid)
prop_bias_pct_summary <- summary(prop_bias_pct)

cat("\nRegression of %Difference on Mean:\n")
cat("  Slope: ", round(coef(prop_bias_pct)[2], 4), "\n")
cat("  p-value: ", format.pval(prop_bias_pct_summary$coefficients[2,4], digits = 3), "\n")

# =============================================================================
# 7. Leverage Analysis
# =============================================================================

cat("\n\n=== Leverage Analysis (R² Dominance) ===\n")

# Identify high-concentration points (these dominate R²)
high_conc <- df_valid %>%
 filter(Pb_icpms > 500) %>%
 select(Base_ID, Pb_icpms, Pb_pred_Lb, BA_diff, BA_pct_diff)

cat("High-concentration samples (>500 ppm):\n")
if (nrow(high_conc) > 0) {
 print(high_conc, n = Inf)
} else {
 cat("  No samples >500 ppm in valid dataset\n")
}

# Look at leverage from original model
cat("\nLeverage analysis from full model:\n")
model_diag <- broom::augment(model_Lb)
high_leverage <- model_diag %>%
 filter(.hat > 2 * mean(.hat) | abs(.cooksd) > 4 / nrow(model_diag)) %>%
 arrange(desc(.cooksd))
if (nrow(high_leverage) > 0) {
 cat("High leverage/influence points:\n")
 print(high_leverage %>% select(Pb_icpms, Pb_Lb_sum, .fitted, .resid, .hat, .cooksd), n = 5)
}

# Refit without highest point
df_no_outlier <- df %>% filter(Pb_icpms < max(Pb_icpms))
model_no_outlier <- lm(Pb_icpms ~ Pb_Lb_sum, data = df_no_outlier)

cat("\n\nModel comparison (effect of highest point):\n")
cat("  Full model R²: ", round(summary(model_Lb)$r.squared, 4), "\n")
cat("  Without max (", round(max(df$Pb_icpms), 0), " ppm) R²: ",
    round(summary(model_no_outlier)$r.squared, 4), "\n")
cat("  Change in R²: ",
    round(summary(model_Lb)$r.squared - summary(model_no_outlier)$r.squared, 4), "\n")

# =============================================================================
# 8. Generate Figures
# =============================================================================

cat("\n\n=== Generating Figures ===\n")

# Color palette
cols <- c("steelblue", "firebrick", "grey50")

# --- Figure A: Traditional Bland-Altman (Absolute Difference) ---
p_ba_abs <- ggplot(df_valid, aes(x = BA_mean, y = BA_diff)) +
 geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
 geom_hline(yintercept = ba_stats$abs_mean_diff, color = cols[1], linewidth = 1) +
 geom_hline(yintercept = ba_stats$abs_loa_lower, linetype = "dashed", color = cols[2]) +
 geom_hline(yintercept = ba_stats$abs_loa_upper, linetype = "dashed", color = cols[2]) +
 geom_point(alpha = 0.7, size = 2.5) +
 geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5, alpha = 0.2) +
 scale_x_log10(labels = scales::comma) +
 labs(
   title = "A) Bland-Altman: Absolute Difference",
   subtitle = sprintf("Bias = %.0f ppm; 95%% LOA = [%.0f, %.0f]",
                      ba_stats$abs_mean_diff, ba_stats$abs_loa_lower, ba_stats$abs_loa_upper),
   x = "Mean of ICP-MS and Calibrated XRF (ppm)",
   y = "Difference (ICP-MS − XRF) (ppm)"
 ) +
 annotate("text", x = max(df_valid$BA_mean) * 0.5, y = ba_stats$abs_loa_upper * 0.9,
          label = "Upper 95% LOA", color = cols[2], hjust = 1, size = 3) +
 annotate("text", x = max(df_valid$BA_mean) * 0.5, y = ba_stats$abs_loa_lower * 1.1,
          label = "Lower 95% LOA", color = cols[2], hjust = 1, size = 3) +
 theme_bw(base_size = 11) +
 theme(plot.subtitle = element_text(size = 9))

# --- Figure B: Percent Difference (more interpretable at all concentrations) ---
p_ba_pct <- ggplot(df_valid, aes(x = BA_mean, y = BA_pct_diff)) +
 geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
 geom_hline(yintercept = ba_stats$pct_mean_diff, color = cols[1], linewidth = 1) +
 geom_hline(yintercept = ba_stats$pct_loa_lower, linetype = "dashed", color = cols[2]) +
 geom_hline(yintercept = ba_stats$pct_loa_upper, linetype = "dashed", color = cols[2]) +
 geom_point(alpha = 0.7, size = 2.5) +
 geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5, alpha = 0.2) +
 scale_x_log10(labels = scales::comma) +
 coord_cartesian(ylim = c(-200, 200)) +
 labs(
   title = "B) Bland-Altman: Percent Difference",
   subtitle = sprintf("Bias = %.1f%%; 95%% LOA = [%.1f%%, %.1f%%]",
                      ba_stats$pct_mean_diff, ba_stats$pct_loa_lower, ba_stats$pct_loa_upper),
   x = "Mean of ICP-MS and Calibrated XRF (ppm)",
   y = "Difference (ICP-MS − XRF) / Mean × 100%"
 ) +
 theme_bw(base_size = 11) +
 theme(plot.subtitle = element_text(size = 9))

# --- Figure C: Error by Concentration Bin ---
p_conc_error <- ggplot(df_valid, aes(x = conc_bin, y = BA_diff)) +
 geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
 geom_boxplot(fill = "steelblue", alpha = 0.3, outlier.shape = NA) +
 geom_jitter(width = 0.2, alpha = 0.5, size = 2) +
 labs(
   title = "C) Error Distribution by Concentration Range",
   subtitle = "Boxplot shows median and IQR; points show individual samples",
   x = "ICP-MS Concentration Range (ppm)",
   y = "Difference (ICP-MS − XRF) (ppm)"
 ) +
 theme_bw(base_size = 11) +
 theme(plot.subtitle = element_text(size = 9))

# --- Figure D: Threshold Classification Performance ---
threshold_df <- tibble(
 threshold = factor(sapply(threshold_results, function(x) x$threshold)),
 sensitivity = sapply(threshold_results, function(x) x$sensitivity),
 specificity = sapply(threshold_results, function(x) x$specificity)
) %>%
 pivot_longer(cols = c(sensitivity, specificity), names_to = "metric", values_to = "value")

p_threshold <- ggplot(threshold_df, aes(x = threshold, y = value, fill = metric)) +
 geom_col(position = position_dodge(0.8), width = 0.7, alpha = 0.8) +
 geom_hline(yintercept = 80, linetype = "dashed", color = "grey50") +
 scale_fill_manual(values = c("sensitivity" = "steelblue", "specificity" = "coral"),
                   labels = c("Sensitivity (detect exceedance)", "Specificity (detect compliance)")) +
 scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, 20)) +
 labs(
   title = "D) Classification Performance at Regulatory Thresholds",
   subtitle = "Dashed line = 80% target",
   x = "Threshold (ppm)",
   y = "Performance (%)",
   fill = NULL
 ) +
 theme_bw(base_size = 11) +
 theme(
   legend.position = "bottom",
   plot.subtitle = element_text(size = 9)
 )

# Combine into 4-panel figure
fig_ba_combined <- (p_ba_abs | p_ba_pct) / (p_conc_error | p_threshold) +
 plot_annotation(
   title = "XRF-ICP-MS Method Agreement: Bland-Altman Analysis",
   subtitle = "L-line calibration model vs ICP-MS reference",
   theme = theme(
     plot.title = element_text(face = "bold", size = 14),
     plot.subtitle = element_text(size = 11)
   )
 )

# Save figures
ggsave("Fig_BlandAltman_4panel.pdf", fig_ba_combined, width = 12, height = 10)
ggsave("Fig_BlandAltman_4panel.png", fig_ba_combined, width = 12, height = 10, dpi = 300)
cat("Saved: Fig_BlandAltman_4panel.pdf/png\n")

# =============================================================================
# 9. Summary Table for Manuscript
# =============================================================================

cat("\n\n=== Summary Table for Manuscript ===\n")

summary_table <- tibble(
 Metric = c(
   "Samples analyzed",
   "Mean bias (ppm)",
   "95% LOA (ppm)",
   "Mean bias (%)",
   "95% LOA (%)",
   "Geometric mean ratio",
   "95% LOA (ratio)",
   "Proportional bias",
   "Model R² (all samples)",
   "Model R² (excluding max)"
 ),
 Value = c(
   as.character(nrow(df_valid)),
   sprintf("%.1f", ba_stats$abs_mean_diff),
   sprintf("[%.1f, %.1f]", ba_stats$abs_loa_lower, ba_stats$abs_loa_upper),
   sprintf("%.1f%%", ba_stats$pct_mean_diff),
   sprintf("[%.1f%%, %.1f%%]", ba_stats$pct_loa_lower, ba_stats$pct_loa_upper),
   sprintf("%.3f", ba_stats$ratio_geometric_mean),
   sprintf("[%.3f, %.3f]", ba_stats$ratio_loa_lower, ba_stats$ratio_loa_upper),
   ifelse(prop_bias_summary$coefficients[2,4] < 0.05, "Significant (p < 0.05)", "Not significant"),
   sprintf("%.4f", summary(model_Lb)$r.squared),
   sprintf("%.4f", summary(model_no_outlier)$r.squared)
 )
)

print(summary_table, n = Inf)

# Save summary
write_csv(summary_table, "Table_BlandAltman_summary.csv")
cat("\nSaved: Table_BlandAltman_summary.csv\n")

# Save detailed statistics
write_csv(conc_stats, "Table_error_by_concentration.csv")
cat("Saved: Table_error_by_concentration.csv\n")

# =============================================================================
# 10. Recommendations
# =============================================================================

cat("\n\n", strrep("=", 70), "\n")
cat("RECOMMENDATIONS FOR MANUSCRIPT\n")
cat(strrep("=", 70), "\n\n")

cat("1. REPLACE or SUPPLEMENT R² with Bland-Altman statistics:\n")
cat("   - Mean bias: ", round(ba_stats$abs_mean_diff, 1), " ppm\n")
cat("   - 95% LOA: [", round(ba_stats$abs_loa_lower, 1), ", ",
    round(ba_stats$abs_loa_upper, 1), "] ppm\n\n")

cat("2. REPORT concentration-dependent performance:\n")
for (i in 1:nrow(conc_stats)) {
 cat("   - ", conc_stats$conc_bin[i], " ppm: RMSE = ",
     round(conc_stats$rmse[i], 1), " ppm (n=", conc_stats$n[i], ")\n", sep = "")
}

cat("\n3. EMPHASIZE threshold classification:\n")
for (res in threshold_results) {
 cat("   - At ", res$threshold, " ppm: Sensitivity = ",
     round(res$sensitivity, 1), "%, Specificity = ",
     round(res$specificity, 1), "%\n", sep = "")
}

cat("\n4. ACKNOWLEDGE leverage effects:\n")
cat("   - Removing highest sample (", round(max(df$Pb_icpms), 0),
    " ppm) drops R² from ", round(summary(model_Lb)$r.squared, 3),
    " to ", round(summary(model_no_outlier)$r.squared, 3), "\n", sep = "")

if (prop_bias_summary$coefficients[2,4] < 0.05) {
 cat("\n5. ADDRESS proportional bias:\n")
 cat("   - Error increases with concentration (slope = ",
     round(coef(prop_bias_model)[2], 3), ")\n")
 cat("   - Consider log-scale or ratio-based correction\n")
}

cat("\n", strrep("=", 70), "\n")
cat("Analysis complete.\n")
