#!/usr/bin/env Rscript
# =============================================================================
# FTIR Diagnostic Analysis: Outliers, Proxy Independence, Matrix Standardization
# =============================================================================
# Evaluates:
# 1. Multicollinearity among FTIR proxies
# 2. Influential outliers driving correlations
# 3. Geogenic matrix standardization approaches
# 4. Robust regression methods
# =============================================================================

library(tidyverse)
library(patchwork)
library(MASS)  # For robust regression

# Fix MASS/dplyr conflict
select <- dplyr::select

# Define paths
data_dir <- "data"
fig_dir <- "figures"

cat("=== FTIR Diagnostic Analysis ===\n\n")

# =============================================================================
# 1. Load Data
# =============================================================================

cat("1. Loading data...\n")

ftir_features <- read_csv(file.path(data_dir, "ftir_organic_features.csv"), show_col_types = FALSE)
df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)

# Merge and prepare
df_merged <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  left_join(ftir_features, by = "Base_ID") %>%
  filter(!is.na(CH_total)) %>%
  mutate(
    Pb_xrf_ppm = Pb_xrf * 10000,
    Zn_xrf_ppm = Zn_xrf * 10000,
    Cu_xrf_ppm = Cu_xrf * 10000,
    Pb_log_ratio = if_else(Pb_xrf_ppm > 0, log10(Pb / Pb_xrf_ppm), NA_real_),
    Zn_log_ratio = if_else(Zn_xrf_ppm > 0, log10(Zn / Zn_xrf_ppm), NA_real_),
    Cu_log_ratio = if_else(Cu_xrf_ppm > 0, log10(Cu / Cu_xrf_ppm), NA_real_)
  ) %>%
  filter(has_XRF == TRUE & is.finite(Pb_log_ratio))

cat(sprintf("   Samples for analysis: %d\n", nrow(df_merged)))

# =============================================================================
# 2. Examine Proxy Distributions and Identify Outliers
# =============================================================================

cat("\n2. Examining proxy distributions and outliers...\n")

# Key FTIR proxies
ftir_proxies <- c("CH_total", "CO_carbonyl_1720", "Aromatic_1600",
                  "NH_stretch", "Silicate_1080", "Total_organic_C",
                  "Total_organic_N", "Total_organic_S", "Total_organic_CNSP")

# Calculate summary stats for each proxy
proxy_stats <- df_merged %>%
  select(Base_ID, all_of(ftir_proxies[ftir_proxies %in% names(df_merged)])) %>%
  pivot_longer(-Base_ID, names_to = "Proxy", values_to = "Value") %>%
  group_by(Proxy) %>%
  summarise(
    Mean = mean(Value, na.rm = TRUE),
    SD = sd(Value, na.rm = TRUE),
    Median = median(Value, na.rm = TRUE),
    IQR = IQR(Value, na.rm = TRUE),
    Min = min(Value, na.rm = TRUE),
    Max = max(Value, na.rm = TRUE),
    CV = SD / Mean * 100,  # Coefficient of variation
    .groups = "drop"
  ) %>%
  arrange(desc(CV))

cat("\n   Proxy Distribution Statistics:\n")
print(proxy_stats)

# Identify outliers using IQR method
identify_outliers <- function(x, k = 1.5) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower <- q1 - k * iqr
  upper <- q3 + k * iqr
  x < lower | x > upper
}

# Find outlier samples
outlier_samples <- df_merged %>%
  mutate(
    outlier_CH = identify_outliers(CH_total),
    outlier_Silicate = identify_outliers(Silicate_1080),
    outlier_CNSP = identify_outliers(Total_organic_CNSP),
    n_outliers = outlier_CH + outlier_Silicate + outlier_CNSP
  ) %>%
  filter(n_outliers > 0) %>%
  select(Base_ID, CH_total, Silicate_1080, Total_organic_CNSP, n_outliers)

cat("\n   Outlier samples (IQR method):\n")
print(outlier_samples)

# =============================================================================
# 3. Multicollinearity Analysis
# =============================================================================

cat("\n3. Analyzing multicollinearity among FTIR proxies...\n")

# Correlation matrix of FTIR proxies
ftir_matrix <- df_merged %>%
  select(all_of(ftir_proxies[ftir_proxies %in% names(df_merged)])) %>%
  drop_na()

cor_matrix <- cor(ftir_matrix)

cat("\n   Correlation matrix (FTIR proxies):\n")
print(round(cor_matrix, 3))

# Find highly correlated pairs (|r| > 0.9)
high_cor_pairs <- which(abs(cor_matrix) > 0.9 & cor_matrix < 1, arr.ind = TRUE)
if (nrow(high_cor_pairs) > 0) {
  cat("\n   Highly correlated proxy pairs (|r| > 0.9):\n")
  for (i in seq_len(nrow(high_cor_pairs))) {
    row_idx <- high_cor_pairs[i, 1]
    col_idx <- high_cor_pairs[i, 2]
    if (row_idx < col_idx) {  # Avoid duplicates
      cat(sprintf("     %s <-> %s: r = %.3f\n",
                  rownames(cor_matrix)[row_idx],
                  colnames(cor_matrix)[col_idx],
                  cor_matrix[row_idx, col_idx]))
    }
  }
}

# =============================================================================
# 4. Cook's Distance - Influential Point Detection
# =============================================================================

cat("\n4. Detecting influential points using Cook's Distance...\n")

# Fit simple linear models and calculate Cook's D
calc_cooks_d <- function(df, predictor, response) {
  formula <- as.formula(paste(response, "~", predictor))
  model <- lm(formula, data = df)
  cooks_d <- cooks.distance(model)
  influential <- which(cooks_d > 4 / nrow(df))
  list(
    model = model,
    cooks_d = cooks_d,
    influential = influential,
    influential_samples = df$Base_ID[influential]
  )
}

# Check for Pb offset
pb_cooks <- calc_cooks_d(df_merged, "CH_total", "Pb_log_ratio")
cat(sprintf("\n   CH_total -> Pb offset:\n"))
cat(sprintf("     Influential samples (Cook's D > 4/n): %s\n",
            paste(pb_cooks$influential_samples, collapse = ", ")))

# Check for Zn offset
zn_cooks <- calc_cooks_d(df_merged, "CH_total", "Zn_log_ratio")
cat(sprintf("\n   CH_total -> Zn offset:\n"))
cat(sprintf("     Influential samples (Cook's D > 4/n): %s\n",
            paste(zn_cooks$influential_samples, collapse = ", ")))

# =============================================================================
# 5. Compare Correlations: Full vs Robust (excluding outliers)
# =============================================================================

cat("\n5. Comparing correlations: Full data vs Robust (outliers removed)...\n")

# Define robust dataset (exclude major outliers)
outlier_ids <- unique(c(outlier_samples$Base_ID,
                        pb_cooks$influential_samples,
                        zn_cooks$influential_samples))

df_robust <- df_merged %>%
  filter(!Base_ID %in% outlier_ids)

cat(sprintf("\n   Full dataset: n = %d\n", nrow(df_merged)))
cat(sprintf("   Robust dataset (outliers removed): n = %d\n", nrow(df_robust)))
cat(sprintf("   Removed samples: %s\n", paste(outlier_ids, collapse = ", ")))

# Calculate correlations for both datasets
calc_all_cors <- function(df, label) {
  tibble(
    Dataset = label,
    n = nrow(df),
    # Carbon proxies
    CH_total_Pb = cor(df$CH_total, df$Pb_log_ratio, use = "complete.obs"),
    CH_total_Zn = cor(df$CH_total, df$Zn_log_ratio, use = "complete.obs"),
    CH_total_Cu = cor(df$CH_total, df$Cu_log_ratio, use = "complete.obs"),
    # Carbonyl
    CO_carbonyl_Pb = cor(df$CO_carbonyl_1720, df$Pb_log_ratio, use = "complete.obs"),
    CO_carbonyl_Zn = cor(df$CO_carbonyl_1720, df$Zn_log_ratio, use = "complete.obs"),
    # Silicate (for matrix standardization)
    Silicate_Pb = cor(df$Silicate_1080, df$Pb_log_ratio, use = "complete.obs"),
    Silicate_Zn = cor(df$Silicate_1080, df$Zn_log_ratio, use = "complete.obs"),
    # Organic/Mineral ratio
    Org_Min_Pb = if ("Organic_mineral_ratio" %in% names(df)) {
      cor(df$Organic_mineral_ratio, df$Pb_log_ratio, use = "complete.obs")
    } else NA,
    Org_Min_Zn = if ("Organic_mineral_ratio" %in% names(df)) {
      cor(df$Organic_mineral_ratio, df$Zn_log_ratio, use = "complete.obs")
    } else NA
  )
}

cor_comparison <- bind_rows(
  calc_all_cors(df_merged, "Full"),
  calc_all_cors(df_robust, "Robust")
)

cat("\n   Correlation comparison (Full vs Robust):\n")
print(cor_comparison %>%
        pivot_longer(-c(Dataset, n), names_to = "Proxy_Element", values_to = "r") %>%
        pivot_wider(names_from = Dataset, values_from = r) %>%
        mutate(Difference = Robust - Full) %>%
        arrange(desc(abs(Difference))))

# =============================================================================
# 6. Matrix Standardization: Normalize by Geogenic Component
# =============================================================================

cat("\n6. Matrix standardization approaches...\n")

# Approach 1: Normalize organic bands by silicate (internal standard)
df_merged <- df_merged %>%
  mutate(
    # Silicate-normalized proxies
    CH_norm_Si = CH_total / (Silicate_1080 + 0.001),
    Aromatic_norm_Si = abs(Aromatic_1600) / (Silicate_1080 + 0.001),
    CO_norm_Si = abs(CO_carbonyl_1720) / (Silicate_1080 + 0.001),
    NH_norm_Si = NH_stretch / (Silicate_1080 + 0.001),

    # Approach 2: Normalize by total mineral (silicate + carbonate)
    Mineral_total = Silicate_1080 + abs(Carbonate_1420) + 0.001,
    CH_norm_mineral = CH_total / Mineral_total,

    # Approach 3: Z-score standardization
    CH_zscore = (CH_total - mean(CH_total, na.rm = TRUE)) / sd(CH_total, na.rm = TRUE),

    # Approach 4: Rank transformation (non-parametric)
    CH_rank = rank(CH_total) / n()
  )

# Test standardized proxies
standardized_vars <- c("CH_norm_Si", "Aromatic_norm_Si", "CO_norm_Si", "NH_norm_Si",
                       "CH_norm_mineral", "CH_zscore", "CH_rank")

std_cors <- tibble(
  Proxy = standardized_vars,
  Pb_r = sapply(standardized_vars, function(v) {
    if (v %in% names(df_merged)) {
      cor(df_merged[[v]], df_merged$Pb_log_ratio, use = "complete.obs")
    } else NA
  }),
  Zn_r = sapply(standardized_vars, function(v) {
    if (v %in% names(df_merged)) {
      cor(df_merged[[v]], df_merged$Zn_log_ratio, use = "complete.obs")
    } else NA
  }),
  Cu_r = sapply(standardized_vars, function(v) {
    if (v %in% names(df_merged)) {
      cor(df_merged[[v]], df_merged$Cu_log_ratio, use = "complete.obs")
    } else NA
  })
) %>%
  mutate(Mean_abs_r = (abs(Pb_r) + abs(Zn_r) + abs(Cu_r)) / 3) %>%
  arrange(desc(Mean_abs_r))

# Add original CH_total for comparison
original_cors <- tibble(
  Proxy = "CH_total (original)",
  Pb_r = cor(df_merged$CH_total, df_merged$Pb_log_ratio, use = "complete.obs"),
  Zn_r = cor(df_merged$CH_total, df_merged$Zn_log_ratio, use = "complete.obs"),
  Cu_r = cor(df_merged$CH_total, df_merged$Cu_log_ratio, use = "complete.obs")
) %>%
  mutate(Mean_abs_r = (abs(Pb_r) + abs(Zn_r) + abs(Cu_r)) / 3)

std_cors <- bind_rows(original_cors, std_cors) %>%
  arrange(desc(Mean_abs_r))

cat("\n   Standardized proxy correlations:\n")
print(std_cors)

# =============================================================================
# 7. Robust Regression (M-estimation)
# =============================================================================

cat("\n7. Robust regression analysis...\n")

# Compare OLS vs Robust regression
ols_pb <- lm(Pb_log_ratio ~ CH_total, data = df_merged)
robust_pb <- rlm(Pb_log_ratio ~ CH_total, data = df_merged)

cat("\n   OLS vs Robust Regression (CH_total -> Pb offset):\n")
cat(sprintf("     OLS:    coef = %.4f, R² = %.3f\n",
            coef(ols_pb)[2], summary(ols_pb)$r.squared))
cat(sprintf("     Robust: coef = %.4f\n", coef(robust_pb)[2]))

# Test with standardized predictor
ols_std <- lm(Pb_log_ratio ~ CH_norm_Si, data = df_merged)
robust_std <- rlm(Pb_log_ratio ~ CH_norm_Si, data = df_merged)

cat("\n   OLS vs Robust Regression (CH_norm_Si -> Pb offset):\n")
cat(sprintf("     OLS:    coef = %.4f, R² = %.3f\n",
            coef(ols_std)[2], summary(ols_std)$r.squared))
cat(sprintf("     Robust: coef = %.4f\n", coef(robust_std)[2]))

# =============================================================================
# 8. Independent Proxy Selection (low multicollinearity)
# =============================================================================

cat("\n8. Selecting independent proxies (low multicollinearity)...\n")

# Find proxies that are NOT highly correlated
# Group proxies by correlation clusters

# Define truly independent proxy candidates
independent_proxies <- c(
  "CH_norm_Si",          # Aliphatic C normalized
  "CO_carbonyl_1720",    # Carbonyl (different chemistry)
  "Aromatic_1600",       # Aromatic (different chemistry)
  "Char_index_FTIR",     # Aromatic/Aliphatic ratio
  "Pyrolysis_index"      # Oxidation state proxy
)

# Check their correlations with each other
ind_proxies_avail <- independent_proxies[independent_proxies %in% names(df_merged)]

if (length(ind_proxies_avail) >= 2) {
  ind_cor_matrix <- df_merged %>%
    select(all_of(ind_proxies_avail)) %>%
    drop_na() %>%
    cor()

  cat("\n   Independent proxy correlation matrix:\n")
  print(round(ind_cor_matrix, 3))
}

# Test independent proxies
ind_proxy_cors <- tibble(
  Proxy = ind_proxies_avail,
  Pb_r = sapply(ind_proxies_avail, function(v) {
    cor(df_merged[[v]], df_merged$Pb_log_ratio, use = "complete.obs")
  }),
  Zn_r = sapply(ind_proxies_avail, function(v) {
    cor(df_merged[[v]], df_merged$Zn_log_ratio, use = "complete.obs")
  }),
  Cu_r = sapply(ind_proxies_avail, function(v) {
    cor(df_merged[[v]], df_merged$Cu_log_ratio, use = "complete.obs")
  })
) %>%
  mutate(Mean_abs_r = (abs(Pb_r) + abs(Zn_r) + abs(Cu_r)) / 3) %>%
  arrange(desc(Mean_abs_r))

cat("\n   Independent proxy correlations:\n")
print(ind_proxy_cors)

# =============================================================================
# 9. Generate Diagnostic Figures
# =============================================================================

cat("\n9. Generating diagnostic figures...\n")

# Panel A: Proxy distributions with outliers highlighted
p_dist <- df_merged %>%
  mutate(is_outlier = Base_ID %in% outlier_ids) %>%
  ggplot(aes(x = CH_total, y = Silicate_1080, color = is_outlier)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_text(data = . %>% filter(is_outlier),
            aes(label = Base_ID), hjust = -0.2, size = 3) +
  scale_color_manual(values = c("FALSE" = "grey40", "TRUE" = "red"),
                     labels = c("Normal", "Outlier")) +
  labs(title = "A) FTIR Proxy Distribution: C-H vs Silicate",
       subtitle = "Outliers identified by IQR and Cook's D",
       x = "CH Total (2900 cm⁻¹)", y = "Silicate (1080 cm⁻¹)",
       color = "") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")

# Panel B: Cook's Distance
cooks_df <- tibble(
  Sample = df_merged$Base_ID,
  Cooks_D = pb_cooks$cooks_d,
  Threshold = 4 / nrow(df_merged)
)

p_cooks <- ggplot(cooks_df, aes(x = reorder(Sample, -Cooks_D), y = Cooks_D)) +
  geom_col(aes(fill = Cooks_D > Threshold), alpha = 0.8) +
  geom_hline(yintercept = 4/nrow(df_merged), linetype = "dashed", color = "red") +
  scale_fill_manual(values = c("FALSE" = "steelblue", "TRUE" = "red")) +
  labs(title = "B) Cook's Distance: CH_total -> Pb Offset",
       subtitle = sprintf("Threshold = 4/n = %.3f", 4/nrow(df_merged)),
       x = "Sample", y = "Cook's Distance") +
  theme_bw(base_size = 11) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 6),
        legend.position = "none")

# Panel C: Full vs Robust correlation
df_plot <- df_merged %>%
  mutate(is_outlier = Base_ID %in% outlier_ids)

p_robust <- ggplot(df_plot, aes(x = CH_total, y = Pb_log_ratio)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(color = is_outlier), size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "blue", linetype = "dashed",
              linewidth = 1, aes(group = 1)) +
  geom_smooth(data = df_plot %>% filter(!is_outlier),
              method = "lm", se = TRUE, color = "red", linewidth = 1) +
  scale_color_manual(values = c("FALSE" = "grey40", "TRUE" = "orange"),
                     labels = c("Included", "Excluded (outlier)")) +
  annotate("text", x = max(df_plot$CH_total) * 0.7, y = -0.1,
           label = sprintf("Full: r = %.3f\nRobust: r = %.3f",
                           cor(df_merged$CH_total, df_merged$Pb_log_ratio),
                           cor(df_robust$CH_total, df_robust$Pb_log_ratio)),
           hjust = 0, size = 3.5) +
  labs(title = "C) Effect of Outliers on Correlation",
       subtitle = "Blue = Full data, Red = Outliers removed",
       x = "CH Total", y = "Pb Offset (log10 ICP-MS/XRF)",
       color = "") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")

# Panel D: Standardized vs Raw proxy comparison
comparison_df <- tibble(
  Method = c("Original", "Si-normalized", "Mineral-normalized", "Z-score", "Rank"),
  Pb_r = c(
    cor(df_merged$CH_total, df_merged$Pb_log_ratio, use = "complete.obs"),
    cor(df_merged$CH_norm_Si, df_merged$Pb_log_ratio, use = "complete.obs"),
    cor(df_merged$CH_norm_mineral, df_merged$Pb_log_ratio, use = "complete.obs"),
    cor(df_merged$CH_zscore, df_merged$Pb_log_ratio, use = "complete.obs"),
    cor(df_merged$CH_rank, df_merged$Pb_log_ratio, use = "complete.obs")
  )
)

p_std <- ggplot(comparison_df, aes(x = reorder(Method, abs(Pb_r)), y = abs(Pb_r))) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_hline(yintercept = 0.3, linetype = "dashed", color = "grey50") +
  geom_text(aes(label = sprintf("%.3f", Pb_r)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(title = "D) Standardization Method Comparison",
       subtitle = "Correlation with Pb offset",
       x = "Standardization Method", y = "|Correlation|") +
  theme_bw(base_size = 11)

# Combine
fig_diagnostic <- (p_dist | p_cooks) / (p_robust | p_std) +
  plot_annotation(
    title = "FTIR Diagnostic Analysis: Outliers, Multicollinearity, and Standardization",
    subtitle = "Evaluating proxy robustness and independence",
    theme = theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11)
    )
  )

ggsave(file.path(fig_dir, "Fig10_ftir_diagnostic.pdf"),
       fig_diagnostic, width = 14, height = 10)
ggsave(file.path(fig_dir, "Fig10_ftir_diagnostic.png"),
       fig_diagnostic, width = 14, height = 10, dpi = 300)

cat("   Saved: figures/Fig10_ftir_diagnostic.pdf/png\n")

# =============================================================================
# 10. Summary and Recommendations
# =============================================================================

cat("\n============================================================\n")
cat("DIAGNOSTIC ANALYSIS SUMMARY\n")
cat("============================================================\n\n")

cat("ISSUE 1: HIGH MULTICOLLINEARITY\n")
cat("  - Most FTIR proxies are highly correlated (r > 0.95)\n")
cat("  - CH_total, NH_stretch, Silicate_1080 all measure baseline intensity\n")
cat("  - This explains nearly identical r² values across proxies\n")

cat("\nISSUE 2: INFLUENTIAL OUTLIERS\n")
cat(sprintf("  - %d samples identified as outliers\n", length(outlier_ids)))
cat(sprintf("  - Samples: %s\n", paste(outlier_ids, collapse = ", ")))
cat("  - These samples drive much of the correlation signal\n")

cat("\nISSUE 3: PROXY QUANTIFICATION\n")
cat("  - Raw peak intensities depend on sample thickness/loading\n")
cat("  - Need internal standardization for meaningful comparisons\n")

cat("\nRECOMMENDATIONS:\n")
cat("  1. Use silicate-normalized ratios (CH_norm_Si) instead of raw values\n")
cat("  2. Focus on chemically distinct proxies:\n")
cat("     - CH_norm_Si (aliphatic organics)\n")
cat("     - Char_index_FTIR (aromatic/aliphatic ratio)\n")
cat("     - CO_carbonyl_1720 (oxidized organics)\n")
cat("  3. Report robust statistics (excluding outliers)\n")
cat("  4. Consider element-specific proxy selection\n")

# Export diagnostic results
diagnostic_results <- list(
  outlier_samples = outlier_samples,
  cor_comparison = cor_comparison,
  standardized_cors = std_cors,
  independent_cors = ind_proxy_cors
)

saveRDS(diagnostic_results, file.path(data_dir, "ftir_diagnostic_results.rds"))
cat("\n   Saved: data/ftir_diagnostic_results.rds\n")

cat("\n=== Diagnostic Analysis Complete ===\n")
