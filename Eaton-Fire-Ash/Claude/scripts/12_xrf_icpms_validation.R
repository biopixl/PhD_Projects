#!/usr/bin/env Rscript
# =============================================================================
# XRF-ICP-MS Method Comparison and Validation (PSQ-2)
# =============================================================================
# This script evaluates XRF as a field-deployable proxy for ICP-MS:
# 1. Correlation and regression statistics
# 2. Bland-Altman method agreement analysis
# 3. Matrix effect quantification
# 4. Correction factor development
# =============================================================================

library(tidyverse)
library(patchwork)

# Define paths
data_dir <- "data"
fig_dir <- "figures"

cat("=== XRF-ICP-MS Method Comparison (PSQ-2) ===\n\n")

# =============================================================================
# 1. Load and prepare data
# =============================================================================

cat("1. Loading datasets...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)

# Filter to ASH samples with both XRF and ICP-MS
df_paired <- df_master %>%
  filter(Sample_Type == "ASH" & has_XRF == TRUE & !is.na(Pb_xrf)) %>%
  mutate(
    # XRF values appear to be in weight percent - convert to ppm
    # Pb_xrf of 0.0395 = 0.0395% = 395 ppm
    Pb_xrf_ppm = Pb_xrf * 10000,
    Zn_xrf_ppm = Zn_xrf * 10000,
    Cu_xrf_ppm = Cu_xrf * 10000,

    # Calculate means and differences for Bland-Altman
    Pb_mean = (Pb + Pb_xrf_ppm) / 2,
    Pb_diff = Pb - Pb_xrf_ppm,
    Pb_pct_diff = (Pb - Pb_xrf_ppm) / Pb_mean * 100,

    Zn_mean = (Zn + Zn_xrf_ppm) / 2,
    Zn_diff = Zn - Zn_xrf_ppm,
    Zn_pct_diff = (Zn - Zn_xrf_ppm) / Zn_mean * 100,

    Cu_mean = (Cu + Cu_xrf_ppm) / 2,
    Cu_diff = Cu - Cu_xrf_ppm,
    Cu_pct_diff = (Cu - Cu_xrf_ppm) / Cu_mean * 100,

    # Log ratios for analysis
    Pb_log_ratio = log10(Pb / Pb_xrf_ppm),
    Zn_log_ratio = log10(Zn / Zn_xrf_ppm),
    Cu_log_ratio = log10(Cu / Cu_xrf_ppm),

    # Matrix composition proxies
    Organic_proxy = 100 - (SiO2_pct + Al2O3_pct + Fe2O3_pct + CaO_pct +
                           MgO_pct + K2O_pct + TiO2_pct + P2O5_pct +
                           MnO_pct + SO3_pct),
    FeOx_proxy = Fe2O3_pct,
    Silicate_proxy = SiO2_pct / (Al2O3_pct + 0.1),
    Clay_proxy = Al2O3_pct / (SiO2_pct + 0.1) * 100,
    Carbonate_proxy = CaO_pct / (SiO2_pct + 0.1) * 100
  )

cat(sprintf("   Paired XRF-ICP-MS samples: %d\n", nrow(df_paired)))

# =============================================================================
# 2. Correlation and Regression Statistics
# =============================================================================

cat("\n2. Computing correlation and regression statistics...\n")

# Function to compute regression stats
compute_regression_stats <- function(x, y, metal_name) {
  valid <- complete.cases(x, y) & is.finite(x) & is.finite(y) & x > 0 & y > 0
  x_valid <- x[valid]
  y_valid <- y[valid]

  # Pearson correlation
  r <- cor(x_valid, y_valid)

  # Linear regression (ICP-MS ~ XRF)
  model <- lm(y_valid ~ x_valid)
  slope <- coef(model)[2]
  intercept <- coef(model)[1]
  r_squared <- summary(model)$r.squared

  # Log-scale regression for multiplicative bias
  log_model <- lm(log10(y_valid) ~ log10(x_valid))
  log_slope <- coef(log_model)[2]
  log_intercept <- coef(log_model)[1]

  # Bias statistics
  ratio <- y_valid / x_valid
  mean_ratio <- mean(ratio)
  median_ratio <- median(ratio)

  tibble(
    Metal = metal_name,
    n = length(x_valid),
    r = r,
    R_squared = r_squared,
    Slope = slope,
    Intercept = intercept,
    Log_slope = log_slope,
    Log_intercept = log_intercept,
    Mean_ratio_ICPMS_XRF = mean_ratio,
    Median_ratio_ICPMS_XRF = median_ratio
  )
}

regression_stats <- bind_rows(
  compute_regression_stats(df_paired$Pb_xrf_ppm, df_paired$Pb, "Pb"),
  compute_regression_stats(df_paired$Zn_xrf_ppm, df_paired$Zn, "Zn"),
  compute_regression_stats(df_paired$Cu_xrf_ppm, df_paired$Cu, "Cu")
)

cat("\n   XRF-ICP-MS Regression Statistics:\n")
cat("   ─────────────────────────────────────────────────────────────────\n")
cat(sprintf("   %-6s %4s %6s %6s %8s %10s %12s\n",
            "Metal", "n", "r", "R²", "Slope", "Intercept", "Median Ratio"))
cat("   ─────────────────────────────────────────────────────────────────\n")
for (i in 1:nrow(regression_stats)) {
  cat(sprintf("   %-6s %4d %6.3f %6.3f %8.4f %10.2f %12.3f\n",
              regression_stats$Metal[i],
              regression_stats$n[i],
              regression_stats$r[i],
              regression_stats$R_squared[i],
              regression_stats$Slope[i],
              regression_stats$Intercept[i],
              regression_stats$Median_ratio_ICPMS_XRF[i]))
}

# =============================================================================
# 3. Bland-Altman Analysis
# =============================================================================

cat("\n3. Computing Bland-Altman statistics...\n")

# Function to compute Bland-Altman stats
compute_ba_stats <- function(diff, metal_name) {
  valid <- is.finite(diff)
  diff_valid <- diff[valid]

  mean_diff <- mean(diff_valid)
  sd_diff <- sd(diff_valid)
  loa_upper <- mean_diff + 1.96 * sd_diff
  loa_lower <- mean_diff - 1.96 * sd_diff

  tibble(
    Metal = metal_name,
    n = length(diff_valid),
    Mean_diff = mean_diff,
    SD_diff = sd_diff,
    LOA_lower = loa_lower,
    LOA_upper = loa_upper,
    CV_pct = abs(sd_diff / mean_diff) * 100
  )
}

ba_stats <- bind_rows(
  compute_ba_stats(df_paired$Pb_pct_diff, "Pb"),
  compute_ba_stats(df_paired$Zn_pct_diff, "Zn"),
  compute_ba_stats(df_paired$Cu_pct_diff, "Cu")
)

cat("\n   Bland-Altman Statistics (% difference):\n")
cat("   ─────────────────────────────────────────────────────────────────\n")
cat(sprintf("   %-6s %4s %10s %8s %12s %12s\n",
            "Metal", "n", "Mean Diff", "SD", "LOA Lower", "LOA Upper"))
cat("   ─────────────────────────────────────────────────────────────────\n")
for (i in 1:nrow(ba_stats)) {
  cat(sprintf("   %-6s %4d %10.1f%% %8.1f %12.1f%% %12.1f%%\n",
              ba_stats$Metal[i],
              ba_stats$n[i],
              ba_stats$Mean_diff[i],
              ba_stats$SD_diff[i],
              ba_stats$LOA_lower[i],
              ba_stats$LOA_upper[i]))
}

# =============================================================================
# 4. Matrix Effect Analysis
# =============================================================================

cat("\n4. Analyzing matrix effects on XRF-ICP-MS agreement...\n")

# Filter for complete matrix data
df_matrix <- df_paired %>%
  filter(!is.na(Organic_proxy) &
         is.finite(Pb_log_ratio) &
         is.finite(Zn_log_ratio) &
         is.finite(Cu_log_ratio))

cat(sprintf("   Samples with matrix data: %d\n", nrow(df_matrix)))

# Correlation of log ratio with matrix components
matrix_cors <- tibble(
  Metal = c("Pb", "Pb", "Pb", "Pb", "Pb",
            "Zn", "Zn", "Zn", "Zn", "Zn",
            "Cu", "Cu", "Cu", "Cu", "Cu"),
  Matrix_component = rep(c("Organic", "Fe2O3", "SiO2/Al2O3", "Al2O3/SiO2", "CaO/SiO2"), 3),
  r = c(
    cor(df_matrix$Pb_log_ratio, df_matrix$Organic_proxy, use = "complete.obs"),
    cor(df_matrix$Pb_log_ratio, df_matrix$FeOx_proxy, use = "complete.obs"),
    cor(df_matrix$Pb_log_ratio, df_matrix$Silicate_proxy, use = "complete.obs"),
    cor(df_matrix$Pb_log_ratio, df_matrix$Clay_proxy, use = "complete.obs"),
    cor(df_matrix$Pb_log_ratio, df_matrix$Carbonate_proxy, use = "complete.obs"),
    cor(df_matrix$Zn_log_ratio, df_matrix$Organic_proxy, use = "complete.obs"),
    cor(df_matrix$Zn_log_ratio, df_matrix$FeOx_proxy, use = "complete.obs"),
    cor(df_matrix$Zn_log_ratio, df_matrix$Silicate_proxy, use = "complete.obs"),
    cor(df_matrix$Zn_log_ratio, df_matrix$Clay_proxy, use = "complete.obs"),
    cor(df_matrix$Zn_log_ratio, df_matrix$Carbonate_proxy, use = "complete.obs"),
    cor(df_matrix$Cu_log_ratio, df_matrix$Organic_proxy, use = "complete.obs"),
    cor(df_matrix$Cu_log_ratio, df_matrix$FeOx_proxy, use = "complete.obs"),
    cor(df_matrix$Cu_log_ratio, df_matrix$Silicate_proxy, use = "complete.obs"),
    cor(df_matrix$Cu_log_ratio, df_matrix$Clay_proxy, use = "complete.obs"),
    cor(df_matrix$Cu_log_ratio, df_matrix$Carbonate_proxy, use = "complete.obs")
  )
)

cat("\n   Matrix Effect Correlations (log ratio vs matrix component):\n")
matrix_cors_wide <- matrix_cors %>%
  pivot_wider(names_from = Matrix_component, values_from = r)
print(matrix_cors_wide, n = 5)

# =============================================================================
# 5. Correction Factor Development
# =============================================================================

cat("\n5. Developing XRF correction models...\n")

# Model: ICP-MS = f(XRF, matrix components)
# Using log-transformed values for multiplicative correction

# Pb correction model
pb_model <- lm(log10(Pb) ~ log10(Pb_xrf_ppm) + Organic_proxy + FeOx_proxy + Silicate_proxy,
               data = df_matrix)
pb_model_summary <- summary(pb_model)

# Zn correction model
zn_model <- lm(log10(Zn) ~ log10(Zn_xrf_ppm) + Organic_proxy + FeOx_proxy + Silicate_proxy,
               data = df_matrix)
zn_model_summary <- summary(zn_model)

# Cu correction model
cu_model <- lm(log10(Cu) ~ log10(Cu_xrf_ppm) + Organic_proxy + FeOx_proxy + Silicate_proxy,
               data = df_matrix)
cu_model_summary <- summary(cu_model)

cat("\n   Pb Correction Model:\n")
cat(sprintf("   R² = %.3f, Adj R² = %.3f, p = %.2e\n",
            pb_model_summary$r.squared,
            pb_model_summary$adj.r.squared,
            pf(pb_model_summary$fstatistic[1],
               pb_model_summary$fstatistic[2],
               pb_model_summary$fstatistic[3],
               lower.tail = FALSE)))
cat("   Coefficients:\n")
print(round(coef(pb_model), 4))

cat("\n   Zn Correction Model:\n")
cat(sprintf("   R² = %.3f, Adj R² = %.3f, p = %.2e\n",
            zn_model_summary$r.squared,
            zn_model_summary$adj.r.squared,
            pf(zn_model_summary$fstatistic[1],
               zn_model_summary$fstatistic[2],
               zn_model_summary$fstatistic[3],
               lower.tail = FALSE)))

cat("\n   Cu Correction Model:\n")
cat(sprintf("   R² = %.3f, Adj R² = %.3f, p = %.2e\n",
            cu_model_summary$r.squared,
            cu_model_summary$adj.r.squared,
            pf(cu_model_summary$fstatistic[1],
               cu_model_summary$fstatistic[2],
               cu_model_summary$fstatistic[3],
               lower.tail = FALSE)))

# Calculate corrected predictions
df_matrix <- df_matrix %>%
  mutate(
    Pb_corrected = 10^predict(pb_model, newdata = .),
    Zn_corrected = 10^predict(zn_model, newdata = .),
    Cu_corrected = 10^predict(cu_model, newdata = .)
  )

# Compare uncorrected vs corrected RMSE
rmse_uncorrected <- c(
  Pb = sqrt(mean((df_matrix$Pb - df_matrix$Pb_xrf_ppm)^2, na.rm = TRUE)),
  Zn = sqrt(mean((df_matrix$Zn - df_matrix$Zn_xrf_ppm)^2, na.rm = TRUE)),
  Cu = sqrt(mean((df_matrix$Cu - df_matrix$Cu_xrf_ppm)^2, na.rm = TRUE))
)

rmse_corrected <- c(
  Pb = sqrt(mean((df_matrix$Pb - df_matrix$Pb_corrected)^2, na.rm = TRUE)),
  Zn = sqrt(mean((df_matrix$Zn - df_matrix$Zn_corrected)^2, na.rm = TRUE)),
  Cu = sqrt(mean((df_matrix$Cu - df_matrix$Cu_corrected)^2, na.rm = TRUE))
)

cat("\n   RMSE Comparison (ppm):\n")
cat(sprintf("   Pb: Uncorrected = %.1f, Corrected = %.1f (%.0f%% reduction)\n",
            rmse_uncorrected["Pb"], rmse_corrected["Pb"],
            (1 - rmse_corrected["Pb"]/rmse_uncorrected["Pb"]) * 100))
cat(sprintf("   Zn: Uncorrected = %.1f, Corrected = %.1f (%.0f%% reduction)\n",
            rmse_uncorrected["Zn"], rmse_corrected["Zn"],
            (1 - rmse_corrected["Zn"]/rmse_uncorrected["Zn"]) * 100))
cat(sprintf("   Cu: Uncorrected = %.1f, Corrected = %.1f (%.0f%% reduction)\n",
            rmse_uncorrected["Cu"], rmse_corrected["Cu"],
            (1 - rmse_corrected["Cu"]/rmse_uncorrected["Cu"]) * 100))

# =============================================================================
# 6. Generate Figures
# =============================================================================

cat("\n6. Generating figures...\n")

# --- Panel A: XRF vs ICP-MS scatter plots ---
p_scatter_pb <- ggplot(df_paired, aes(x = Pb_xrf_ppm, y = Pb)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "steelblue") +
  scale_x_log10() + scale_y_log10() +
  labs(title = "Pb", x = "XRF (ppm)", y = "ICP-MS (ppm)") +
  annotate("text", x = min(df_paired$Pb_xrf_ppm, na.rm = TRUE) * 1.5,
           y = max(df_paired$Pb, na.rm = TRUE) * 0.7,
           label = sprintf("r = %.3f", regression_stats$r[1]), hjust = 0, size = 3) +
  theme_bw(base_size = 10)

p_scatter_zn <- ggplot(df_paired, aes(x = Zn_xrf_ppm, y = Zn)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "steelblue") +
  scale_x_log10() + scale_y_log10() +
  labs(title = "Zn", x = "XRF (ppm)", y = "ICP-MS (ppm)") +
  annotate("text", x = min(df_paired$Zn_xrf_ppm, na.rm = TRUE) * 1.5,
           y = max(df_paired$Zn, na.rm = TRUE) * 0.7,
           label = sprintf("r = %.3f", regression_stats$r[2]), hjust = 0, size = 3) +
  theme_bw(base_size = 10)

p_scatter_cu <- ggplot(df_paired, aes(x = Cu_xrf_ppm, y = Cu)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "steelblue") +
  scale_x_log10() + scale_y_log10() +
  labs(title = "Cu", x = "XRF (ppm)", y = "ICP-MS (ppm)") +
  annotate("text", x = min(df_paired$Cu_xrf_ppm, na.rm = TRUE) * 1.5,
           y = max(df_paired$Cu, na.rm = TRUE) * 0.7,
           label = sprintf("r = %.3f", regression_stats$r[3]), hjust = 0, size = 3) +
  theme_bw(base_size = 10)

p_scatter <- (p_scatter_pb | p_scatter_zn | p_scatter_cu) +
  plot_annotation(title = "A) XRF vs ICP-MS Correlation",
                  subtitle = "Dashed line = 1:1; Blue line = linear fit",
                  theme = theme(plot.title = element_text(face = "bold", size = 12)))

# --- Panel B: Bland-Altman plots ---
ba_pb_stats <- ba_stats %>% filter(Metal == "Pb")
p_ba_pb <- ggplot(df_paired %>% filter(is.finite(Pb_pct_diff)),
                  aes(x = Pb_mean, y = Pb_pct_diff)) +
  geom_hline(yintercept = ba_pb_stats$Mean_diff, color = "steelblue", linewidth = 0.8) +
  geom_hline(yintercept = ba_pb_stats$LOA_upper, linetype = "dashed", color = "firebrick") +
  geom_hline(yintercept = ba_pb_stats$LOA_lower, linetype = "dashed", color = "firebrick") +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  geom_point(alpha = 0.6, size = 2) +
  scale_x_log10() +
  labs(title = "Pb", x = "Mean (ppm)", y = "Difference (%)") +
  annotate("text", x = max(df_paired$Pb_mean, na.rm = TRUE) * 0.8,
           y = ba_pb_stats$Mean_diff + 5,
           label = sprintf("Bias = %.0f%%", ba_pb_stats$Mean_diff),
           hjust = 1, size = 2.5, color = "steelblue") +
  theme_bw(base_size = 10)

ba_zn_stats <- ba_stats %>% filter(Metal == "Zn")
p_ba_zn <- ggplot(df_paired %>% filter(is.finite(Zn_pct_diff)),
                  aes(x = Zn_mean, y = Zn_pct_diff)) +
  geom_hline(yintercept = ba_zn_stats$Mean_diff, color = "steelblue", linewidth = 0.8) +
  geom_hline(yintercept = ba_zn_stats$LOA_upper, linetype = "dashed", color = "firebrick") +
  geom_hline(yintercept = ba_zn_stats$LOA_lower, linetype = "dashed", color = "firebrick") +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  geom_point(alpha = 0.6, size = 2) +
  scale_x_log10() +
  labs(title = "Zn", x = "Mean (ppm)", y = "Difference (%)") +
  annotate("text", x = max(df_paired$Zn_mean, na.rm = TRUE) * 0.8,
           y = ba_zn_stats$Mean_diff + 5,
           label = sprintf("Bias = %.0f%%", ba_zn_stats$Mean_diff),
           hjust = 1, size = 2.5, color = "steelblue") +
  theme_bw(base_size = 10)

ba_cu_stats <- ba_stats %>% filter(Metal == "Cu")
p_ba_cu <- ggplot(df_paired %>% filter(is.finite(Cu_pct_diff)),
                  aes(x = Cu_mean, y = Cu_pct_diff)) +
  geom_hline(yintercept = ba_cu_stats$Mean_diff, color = "steelblue", linewidth = 0.8) +
  geom_hline(yintercept = ba_cu_stats$LOA_upper, linetype = "dashed", color = "firebrick") +
  geom_hline(yintercept = ba_cu_stats$LOA_lower, linetype = "dashed", color = "firebrick") +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  geom_point(alpha = 0.6, size = 2) +
  scale_x_log10() +
  labs(title = "Cu", x = "Mean (ppm)", y = "Difference (%)") +
  annotate("text", x = max(df_paired$Cu_mean, na.rm = TRUE) * 0.8,
           y = ba_cu_stats$Mean_diff + 5,
           label = sprintf("Bias = %.0f%%", ba_cu_stats$Mean_diff),
           hjust = 1, size = 2.5, color = "steelblue") +
  theme_bw(base_size = 10)

p_ba <- (p_ba_pb | p_ba_zn | p_ba_cu) +
  plot_annotation(title = "B) Bland-Altman Method Agreement",
                  subtitle = "Blue = mean bias; Red dashed = 95% limits of agreement",
                  theme = theme(plot.title = element_text(face = "bold", size = 12)))

# --- Panel C: Matrix effects on offset ---
p_matrix_pb <- ggplot(df_matrix, aes(x = Organic_proxy, y = Pb_log_ratio)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(color = FeOx_proxy), alpha = 0.7, size = 2.5) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
  scale_color_viridis_c(name = "Fe₂O₃ %", option = "plasma") +
  labs(title = "Pb",
       x = "Organic proxy (%)",
       y = "log₁₀(ICP-MS/XRF)") +
  annotate("text", x = min(df_matrix$Organic_proxy, na.rm = TRUE) + 2,
           y = max(df_matrix$Pb_log_ratio, na.rm = TRUE) * 0.9,
           label = sprintf("r = %.2f", matrix_cors$r[matrix_cors$Metal == "Pb" &
                                                       matrix_cors$Matrix_component == "Organic"]),
           hjust = 0, size = 3) +
  theme_bw(base_size = 10) +
  theme(legend.position = "right")

p_matrix_zn <- ggplot(df_matrix, aes(x = Organic_proxy, y = Zn_log_ratio)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(color = FeOx_proxy), alpha = 0.7, size = 2.5) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
  scale_color_viridis_c(name = "Fe₂O₃ %", option = "plasma") +
  labs(title = "Zn",
       x = "Organic proxy (%)",
       y = "log₁₀(ICP-MS/XRF)") +
  annotate("text", x = min(df_matrix$Organic_proxy, na.rm = TRUE) + 2,
           y = max(df_matrix$Zn_log_ratio, na.rm = TRUE) * 0.9,
           label = sprintf("r = %.2f", matrix_cors$r[matrix_cors$Metal == "Zn" &
                                                       matrix_cors$Matrix_component == "Organic"]),
           hjust = 0, size = 3) +
  theme_bw(base_size = 10) +
  theme(legend.position = "right")

p_matrix <- (p_matrix_pb | p_matrix_zn) +
  plot_annotation(title = "C) Matrix Effects on XRF-ICP-MS Agreement",
                  subtitle = "Point color = Fe₂O₃ content; Positive values = ICP-MS higher",
                  theme = theme(plot.title = element_text(face = "bold", size = 12)))

# --- Panel D: Corrected vs uncorrected ---
p_correct_pb <- ggplot(df_matrix) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(x = Pb, y = Pb_xrf_ppm, color = "Uncorrected XRF"), alpha = 0.5, size = 2) +
  geom_point(aes(x = Pb, y = Pb_corrected, color = "Matrix-corrected"), alpha = 0.7, size = 2) +
  scale_x_log10() + scale_y_log10() +
  scale_color_manual(values = c("Uncorrected XRF" = "grey50", "Matrix-corrected" = "steelblue"),
                     name = "") +
  labs(title = "Pb", x = "ICP-MS (ppm)", y = "Predicted (ppm)") +
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom")

p_correct_zn <- ggplot(df_matrix) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(x = Zn, y = Zn_xrf_ppm, color = "Uncorrected XRF"), alpha = 0.5, size = 2) +
  geom_point(aes(x = Zn, y = Zn_corrected, color = "Matrix-corrected"), alpha = 0.7, size = 2) +
  scale_x_log10() + scale_y_log10() +
  scale_color_manual(values = c("Uncorrected XRF" = "grey50", "Matrix-corrected" = "steelblue"),
                     name = "") +
  labs(title = "Zn", x = "ICP-MS (ppm)", y = "Predicted (ppm)") +
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom")

p_correct <- (p_correct_pb | p_correct_zn) +
  plot_annotation(title = "D) Effect of Matrix Correction",
                  subtitle = "Dashed line = 1:1 agreement",
                  theme = theme(plot.title = element_text(face = "bold", size = 12)))

# Combine all panels
fig_combined <- (p_scatter / p_ba / p_matrix / p_correct) +
  plot_annotation(
    title = "XRF-ICP-MS Method Comparison and Matrix Effects",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

# Save figure
ggsave(file.path(fig_dir, "Fig5_xrf_validation.pdf"),
       fig_combined, width = 12, height = 14)
ggsave(file.path(fig_dir, "Fig5_xrf_validation.png"),
       fig_combined, width = 12, height = 14, dpi = 300)

cat("   Saved: figures/Fig5_xrf_validation.pdf/png\n")

# =============================================================================
# 7. Export Tables
# =============================================================================

cat("\n7. Exporting summary tables...\n")

# Table 4: Regression statistics
write_csv(regression_stats, file.path(data_dir, "table4_xrf_regression.csv"))
cat("   Saved: data/table4_xrf_regression.csv\n")

# Table 5: Bland-Altman statistics
write_csv(ba_stats, file.path(data_dir, "table5_bland_altman.csv"))
cat("   Saved: data/table5_bland_altman.csv\n")

# Table: Matrix correlations
write_csv(matrix_cors, file.path(data_dir, "table_matrix_effect_correlations.csv"))
cat("   Saved: data/table_matrix_effect_correlations.csv\n")

# Correction model coefficients
correction_coefs <- tibble(
  Metal = c("Pb", "Zn", "Cu"),
  Intercept = c(coef(pb_model)[1], coef(zn_model)[1], coef(cu_model)[1]),
  log10_XRF = c(coef(pb_model)[2], coef(zn_model)[2], coef(cu_model)[2]),
  Organic = c(coef(pb_model)[3], coef(zn_model)[3], coef(cu_model)[3]),
  Fe2O3 = c(coef(pb_model)[4], coef(zn_model)[4], coef(cu_model)[4]),
  Silicate = c(coef(pb_model)[5], coef(zn_model)[5], coef(cu_model)[5]),
  R_squared = c(pb_model_summary$r.squared, zn_model_summary$r.squared, cu_model_summary$r.squared),
  Adj_R_squared = c(pb_model_summary$adj.r.squared, zn_model_summary$adj.r.squared, cu_model_summary$adj.r.squared)
)
write_csv(correction_coefs, file.path(data_dir, "table_xrf_correction_model.csv"))
cat("   Saved: data/table_xrf_correction_model.csv\n")

# =============================================================================
# Summary
# =============================================================================

cat("\n============================================================\n")
cat("XRF-ICP-MS VALIDATION SUMMARY\n")
cat("============================================================\n\n")

cat("1. Correlation Analysis:\n")
cat(sprintf("   - Pb: r = %.3f (R² = %.3f)\n", regression_stats$r[1], regression_stats$R_squared[1]))
cat(sprintf("   - Zn: r = %.3f (R² = %.3f)\n", regression_stats$r[2], regression_stats$R_squared[2]))
cat(sprintf("   - Cu: r = %.3f (R² = %.3f)\n", regression_stats$r[3], regression_stats$R_squared[3]))

cat("\n2. Systematic Bias (ICP-MS vs XRF):\n")
cat(sprintf("   - Pb: ICP-MS is %.0f%% lower (median ratio = %.2f)\n",
            abs(ba_stats$Mean_diff[1]), regression_stats$Median_ratio_ICPMS_XRF[1]))
cat(sprintf("   - Zn: ICP-MS is %.0f%% lower (median ratio = %.2f)\n",
            abs(ba_stats$Mean_diff[2]), regression_stats$Median_ratio_ICPMS_XRF[2]))
cat(sprintf("   - Cu: ICP-MS is %.0f%% lower (median ratio = %.2f)\n",
            abs(ba_stats$Mean_diff[3]), regression_stats$Median_ratio_ICPMS_XRF[3]))

cat("\n3. Matrix Effects:\n")
cat("   - Higher organic content → smaller XRF-ICP-MS offset\n")
cat("   - Higher Fe₂O₃ content → larger XRF-ICP-MS offset\n")
cat(sprintf("   - Pb-Organic correlation: r = %.2f\n",
            matrix_cors$r[matrix_cors$Metal == "Pb" & matrix_cors$Matrix_component == "Organic"]))
cat(sprintf("   - Pb-Fe₂O₃ correlation: r = %.2f\n",
            matrix_cors$r[matrix_cors$Metal == "Pb" & matrix_cors$Matrix_component == "Fe2O3"]))

cat("\n4. Correction Model Performance:\n")
cat(sprintf("   - Pb: R² = %.3f, RMSE reduced by %.0f%%\n",
            pb_model_summary$r.squared, (1 - rmse_corrected["Pb"]/rmse_uncorrected["Pb"]) * 100))
cat(sprintf("   - Zn: R² = %.3f, RMSE reduced by %.0f%%\n",
            zn_model_summary$r.squared, (1 - rmse_corrected["Zn"]/rmse_uncorrected["Zn"]) * 100))
cat(sprintf("   - Cu: R² = %.3f, RMSE reduced by %.0f%%\n",
            cu_model_summary$r.squared, (1 - rmse_corrected["Cu"]/rmse_uncorrected["Cu"]) * 100))

cat("\n=== Analysis Complete ===\n")
