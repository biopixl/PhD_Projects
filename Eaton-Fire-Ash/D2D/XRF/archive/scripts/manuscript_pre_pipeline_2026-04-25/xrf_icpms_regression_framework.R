#!/usr/bin/env Rscript
# XRF vs ICP-MS Regression Framework for Eaton Fire Ash Study
# Statistical Framework: Comparing Pb quantification methods
#
# H0: XRF wt% (Lα-based FP) predicts ICP-MS Pb (ppm)
# H1: Pb Lβ1 + Lβ2 (counts) predict ICP-MS Pb (ppm) - avoids As Kα interference

library(tidyverse)
library(broom)

# =============================================================================
# STEP 0: Configuration — XRF preparation method
# =============================================================================
# 3_XRF-cts.csv now carries a Method column (pellet vs powder). Pellet is the
# canonical arm of the 4-model comparison (D2D/XRF/README.md): r=0.998,
# RMSE=213 ppm. Set XRF_METHOD = "powder" to regenerate the powder-arm
# calibration; downstream consumers of harmonized_xrf_icpms_Lb_paired.csv will
# see the method stamped into a Method column.
XRF_METHOD <- "pellet"

# =============================================================================
# STEP 1: Data Harmonization
# =============================================================================

# Load master dataset (already has ICP-MS and XRF merged)
df_master <- read_csv(
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Claude/data/df_master.csv",
  show_col_types = FALSE
)

# Load XRF counts data with individual Pb emission lines
df_counts_long <- read_csv(
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/3_XRF-cts.csv",
  show_col_types = FALSE
)

# Filter to the configured preparation method BEFORE any aggregation, so
# pellet and powder measurements never get silently averaged together.
df_counts_long <- df_counts_long %>% filter(Method == XRF_METHOD)

cat("=== XRF Method Filter ===\n")
cat("XRF_METHOD =", XRF_METHOD, "\n")
cat("Rows after filter:", nrow(df_counts_long), "\n")

# Pivot counts data to wide format (one row per sample within the chosen method)
df_counts_wide <- df_counts_long %>%
  filter(Element == "Pb") %>%
  group_by(Sample, Method, Line) %>%
  summarise(
    Intensity_Cnts = mean(Intensity_Cnts, na.rm = TRUE),
    Error_int = mean(Error_int, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = Line,
    values_from = c(Intensity_Cnts, Error_int),
    names_sep = "_"
  ) %>%
  rename(
    Pb_La1_cts = Intensity_Cnts_La1,
    Pb_La2_cts = Intensity_Cnts_La2,
    Pb_Lb1_cts = Intensity_Cnts_Lb1,
    Pb_Lb2_cts = Intensity_Cnts_Lb2,
    Pb_Lb3_cts = Intensity_Cnts_Lb3,
    Pb_Lb4_cts = Intensity_Cnts_Lb4
  )

cat("=== XRF Counts Data Summary ===\n")
cat("Samples with Pb line data:", nrow(df_counts_wide), "\n")

# Filter to samples with both ICP-MS and XRF data
df_paired <- df_master %>%
  filter(has_ICPMS == TRUE, has_XRF == TRUE) %>%
  select(
    Base_ID,
    Sample_Type,
    Latitude,
    Longitude,
    # ICP-MS (gold standard) - ppm
    Pb_icpms = Pb,
    Zn_icpms = Zn,
    Cu_icpms = Cu,
    As_icpms = As,
    # XRF wt%
    Pb_xrf_wt = Pb_xrf,
    Zn_xrf_wt = Zn_xrf,
    Cu_xrf_wt = Cu_xrf
  ) %>%
  # Convert XRF wt% to ppm for direct comparison
  mutate(
    Pb_xrf_ppm = Pb_xrf_wt * 10000,
    Zn_xrf_ppm = Zn_xrf_wt * 10000,
    Cu_xrf_ppm = Cu_xrf_wt * 10000
  ) %>%
  # Remove samples with missing Pb data
  filter(!is.na(Pb_icpms), !is.na(Pb_xrf_wt))

cat("=== Data Harmonization Summary ===\n")
cat("XRF preparation method:", XRF_METHOD, "\n")
cat("Total paired samples (ICP-MS + XRF):", nrow(df_paired), "\n")
cat("Sample types:\n")
print(table(df_paired$Sample_Type))

# =============================================================================
# STEP 2: H0 Model - Standard XRF (Lα-based) vs ICP-MS
# =============================================================================

cat("\n=== H0: XRF wt% vs ICP-MS ppm (Pb) ===\n")

# Model: ICP-MS Pb (ppm) ~ XRF Pb (wt%)
# Note: Using wt% directly; slope will incorporate the 10,000 conversion factor
model_H0 <- lm(Pb_icpms ~ Pb_xrf_wt, data = df_paired)

# Model summary
cat("\nModel Summary:\n")
print(summary(model_H0))

# Extract key statistics
H0_stats <- glance(model_H0)
H0_coefs <- tidy(model_H0)

cat("\n--- Key Statistics ---\n")
cat("R²:", round(H0_stats$r.squared, 4), "\n")
cat("Adjusted R²:", round(H0_stats$adj.r.squared, 4), "\n")
cat("RMSE:", round(sqrt(mean(model_H0$residuals^2)), 2), "ppm\n")
cat("Intercept:", round(H0_coefs$estimate[1], 2), "ppm\n")
cat("Slope:", round(H0_coefs$estimate[2], 2), "ppm per wt%\n")
cat("  (Expected slope for perfect agreement: 10,000)\n")

# Bias assessment
df_paired <- df_paired %>%
  mutate(
    Pb_predicted_H0 = predict(model_H0, .),
    Pb_residual_H0 = Pb_icpms - Pb_predicted_H0,
    Pb_bias_H0 = Pb_xrf_ppm - Pb_icpms  # Direct comparison after unit conversion
  )

cat("\n--- Bias Assessment (XRF - ICP-MS) ---\n")
cat("Mean bias:", round(mean(df_paired$Pb_bias_H0), 2), "ppm\n
")
cat("SD of bias:", round(sd(df_paired$Pb_bias_H0), 2), "ppm\n")
cat("Mean % bias:", round(mean(df_paired$Pb_bias_H0 / df_paired$Pb_icpms * 100), 1), "%\n")

# =============================================================================
# STEP 3: H1 Model - Pb Lβ lines (interference-free) vs ICP-MS
# =============================================================================

cat("\n=== H1: Pb Lβ1 + Lβ2 (counts) vs ICP-MS ppm ===\n")

# Merge counts data with ICP-MS data
# Need to match sample IDs between datasets. Method comes along so the
# harmonized output records which preparation arm fed the calibration.
df_H1 <- df_paired %>%
  left_join(
    df_counts_wide %>% select(Sample, Method, Pb_La1_cts, Pb_Lb1_cts, Pb_Lb2_cts),
    by = c("Base_ID" = "Sample")
  ) %>%
  filter(!is.na(Pb_Lb1_cts), !is.na(Pb_Lb2_cts))

cat("Samples with matched ICP-MS + Lβ counts:", nrow(df_H1), "\n")

# Model H1a: Using only Lβ1 (most intense interference-free line)
model_H1a <- lm(Pb_icpms ~ Pb_Lb1_cts, data = df_H1)

# Model H1b: Using Lβ1 + Lβ2 combined
df_H1 <- df_H1 %>%
  mutate(Pb_Lb_sum = Pb_Lb1_cts + Pb_Lb2_cts)

model_H1b <- lm(Pb_icpms ~ Pb_Lb_sum, data = df_H1)

# Model H1c: Using Lβ1 and Lβ2 as separate predictors
model_H1c <- lm(Pb_icpms ~ Pb_Lb1_cts + Pb_Lb2_cts, data = df_H1)

cat("\n--- H1a: Pb Lβ1 only ---\n")
print(summary(model_H1a))

cat("\n--- H1b: Pb Lβ1 + Lβ2 (summed) ---\n")
print(summary(model_H1b))

# Extract H1b statistics (primary alternative model)
H1b_stats <- glance(model_H1b)
H1b_coefs <- tidy(model_H1b)

cat("\n--- H1b Key Statistics ---\n")
cat("R²:", round(H1b_stats$r.squared, 4), "\n")
cat("Adjusted R²:", round(H1b_stats$adj.r.squared, 4), "\n")
cat("RMSE:", round(sqrt(mean(model_H1b$residuals^2)), 2), "ppm\n")
cat("Intercept:", round(H1b_coefs$estimate[1], 2), "ppm\n")
cat("Slope:", round(H1b_coefs$estimate[2], 4), "ppm per count\n")

# Predictions and residuals for H1b
df_H1 <- df_H1 %>%
  mutate(
    Pb_predicted_H1b = predict(model_H1b, .),
    Pb_residual_H1b = Pb_icpms - Pb_predicted_H1b
  )

# =============================================================================
# STEP 4: Model Comparison - H0 vs H1
# =============================================================================

cat("\n=== MODEL COMPARISON: H0 (Lα wt%) vs H1 (Lβ counts) ===\n")

# For fair comparison, need to use same samples
# Re-fit H0 on the subset that has Lβ data
model_H0_subset <- lm(Pb_icpms ~ Pb_xrf_wt, data = df_H1)
H0_subset_stats <- glance(model_H0_subset)

# Also compare against Lα counts directly
model_La_counts <- lm(Pb_icpms ~ Pb_La1_cts, data = df_H1)
La_stats <- glance(model_La_counts)

comparison_table <- tibble(
  Model = c(
    "H0: XRF wt% (Lα-based FP)",
    "Lα1 counts (raw)",
    "H1a: Lβ1 counts only",
    "H1b: Lβ1 + Lβ2 counts"
  ),
  N = nrow(df_H1),
  R_squared = c(
    H0_subset_stats$r.squared,
    La_stats$r.squared,
    glance(model_H1a)$r.squared,
    H1b_stats$r.squared
  ),
  Adj_R_squared = c(
    H0_subset_stats$adj.r.squared,
    La_stats$adj.r.squared,
    glance(model_H1a)$adj.r.squared,
    H1b_stats$adj.r.squared
  ),
  RMSE_ppm = c(
    sqrt(mean(model_H0_subset$residuals^2)),
    sqrt(mean(model_La_counts$residuals^2)),
    sqrt(mean(model_H1a$residuals^2)),
    sqrt(mean(model_H1b$residuals^2))
  ),
  AIC = c(
    AIC(model_H0_subset),
    AIC(model_La_counts),
    AIC(model_H1a),
    AIC(model_H1b)
  ),
  BIC = c(
    BIC(model_H0_subset),
    BIC(model_La_counts),
    BIC(model_H1a),
    BIC(model_H1b)
  )
)

cat("\n")
print(comparison_table, n = Inf)

# Statistical test: Are the models significantly different?
cat("\n--- Comparison of Lα vs Lβ counts (same samples) ---\n")
cat("Lα1 R²:", round(La_stats$r.squared, 4), "\n")
cat("Lβ sum R²:", round(H1b_stats$r.squared, 4), "\n")
cat("Difference:", round(H1b_stats$r.squared - La_stats$r.squared, 4), "\n")

# Vuong test or AIC comparison
cat("\nΔAIC (Lα - Lβ):", round(AIC(model_La_counts) - AIC(model_H1b), 2), "\n")
cat("  (Negative = Lβ is better; >2 is meaningful)\n")

# =============================================================================
# STEP 5: Save Results
# =============================================================================

# Save harmonized data with all predictions
write_csv(
  df_H1,
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/harmonized_xrf_icpms_Lb_paired.csv"
)

cat("\n=== Output Files ===\n")
cat("Harmonized data saved to: harmonized_xrf_icpms_Lb_paired.csv\n")

# Combined model comparison table for manuscript
write_csv(
  comparison_table,
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/model_comparison_H0_H1.csv"
)
cat("Model comparison saved to: model_comparison_H0_H1.csv\n")

# Detailed coefficients for both models
coef_table <- bind_rows(
  tidy(model_H0_subset) %>% mutate(Model = "H0: XRF wt%"),
  tidy(model_H1b) %>% mutate(Model = "H1b: Lβ1+Lβ2")
)

write_csv(
  coef_table,
  "/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/model_coefficients.csv"
)
cat("Model coefficients saved to: model_coefficients.csv\n")

# =============================================================================
# STEP 6: Summary Statistics for Manuscript
# =============================================================================

cat("\n" , strrep("=", 60), "\n")
cat("MANUSCRIPT SUMMARY: XRF Calibration for Pb in Wildfire Ash\n")
cat(strrep("=", 60), "\n\n")

cat("METHODS:\n")
cat("  - Gold standard: ICP-MS (ppm)\n")
cat("  - XRF preparation:", XRF_METHOD, "\n")
cat("  - H0: XRF fundamental parameters (Lα-based quantification)\n")
cat("  - H1: Direct Lβ line intensity (avoids As Kα interference)\n\n")

cat("RESULTS:\n")
cat("  Samples analyzed:", nrow(df_H1), "\n\n")

cat("  Model Performance:\n")
cat("  ┌─────────────────────┬─────────┬───────────┐\n")
cat("  │ Model               │   R²    │ RMSE(ppm) │\n")
cat("  ├─────────────────────┼─────────┼───────────┤\n")
cat(sprintf("  │ H0: XRF wt%% (Lα FP) │ %.4f  │   %6.1f  │\n",
            H0_subset_stats$r.squared, sqrt(mean(model_H0_subset$residuals^2))))
cat(sprintf("  │ H1: Lβ1+Lβ2 counts  │ %.4f  │   %6.1f  │\n",
            H1b_stats$r.squared, sqrt(mean(model_H1b$residuals^2))))
cat("  └─────────────────────┴─────────┴───────────┘\n\n")

cat("CONCLUSION:\n")
if (H1b_stats$r.squared > H0_subset_stats$r.squared) {
  cat("  Lβ lines provide BETTER prediction of ICP-MS Pb\n")
  cat("  Supports hypothesis that As Kα interference affects Lα quantification\n")
} else {
  cat("  XRF FP quantification (Lα) provides comparable or better fit\n")
  cat("  Matrix correction in FP algorithm compensates for interference\n")
}

cat("\n", strrep("=", 60), "\n")
