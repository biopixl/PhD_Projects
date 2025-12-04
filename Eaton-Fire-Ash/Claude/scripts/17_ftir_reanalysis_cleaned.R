#!/usr/bin/env Rscript
# =============================================================================
# FTIR Re-analysis with Cleaned Dataset (XPAH26 removed)
# =============================================================================
# XPAH26 excluded due to anomalous spectral intensity (~15x higher than other
# samples), likely due to sample preparation differences rather than true
# compositional variation.
# =============================================================================

library(tidyverse)
library(patchwork)

# Define paths
data_dir <- "data"
fig_dir <- "figures"

cat("=== FTIR Re-analysis (Cleaned Dataset) ===\n\n")

# =============================================================================
# 1. Load and Clean Data
# =============================================================================

cat("1. Loading and cleaning data...\n")

ftir_features <- read_csv(file.path(data_dir, "ftir_organic_features.csv"), show_col_types = FALSE)
df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
asd_organic <- read_csv(file.path(data_dir, "asd_organic_features.csv"), show_col_types = FALSE)

# Exclude XPAH26 - anomalous spectral intensity
excluded_samples <- c("XPAH26")
cat(sprintf("   Excluding samples: %s\n", paste(excluded_samples, collapse = ", ")))
cat("   Reason: Anomalous FTIR intensity (~15x higher than other samples)\n")

# Merge and prepare cleaned dataset
df_clean <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  filter(!Base_ID %in% excluded_samples) %>%
  left_join(ftir_features %>% filter(!Base_ID %in% excluded_samples), by = "Base_ID") %>%
  left_join(asd_organic %>% select(Base_ID, Vis_slope, Char_darkness, Organic_index_1),
            by = "Base_ID") %>%
  filter(!is.na(CH_total) & has_XRF == TRUE) %>%
  mutate(
    # XRF trace metals in ppm
    Pb_xrf_ppm = Pb_xrf * 10000,
    Zn_xrf_ppm = Zn_xrf * 10000,
    Cu_xrf_ppm = Cu_xrf * 10000,

    # XRF-ICPMS log ratios
    Pb_log_ratio = if_else(Pb_xrf_ppm > 0, log10(Pb / Pb_xrf_ppm), NA_real_),
    Zn_log_ratio = if_else(Zn_xrf_ppm > 0, log10(Zn / Zn_xrf_ppm), NA_real_),
    Cu_log_ratio = if_else(Cu_xrf_ppm > 0, log10(Cu / Cu_xrf_ppm), NA_real_),

    # XRF organic proxy
    XRF_organic = 100 - (SiO2_pct + Al2O3_pct + Fe2O3_pct + CaO_pct +
                         MgO_pct + K2O_pct + TiO2_pct + P2O5_pct +
                         MnO_pct + SO3_pct),

    # Matrix-normalized FTIR proxies (using silicate as internal standard)
    CH_norm_Si = CH_total / (Silicate_1080 + 0.001),
    Aromatic_norm_Si = abs(Aromatic_1600) / (Silicate_1080 + 0.001),
    CO_norm_Si = abs(CO_carbonyl_1720) / (Silicate_1080 + 0.001),
    NH_norm_Si = NH_stretch / (Silicate_1080 + 0.001),

    # Organic/Mineral ratio normalized
    Organic_mineral_norm = (CH_total + abs(Aromatic_1600)) / (Silicate_1080 + abs(Carbonate_1420) + 0.001)
  ) %>%
  filter(is.finite(Pb_log_ratio))

cat(sprintf("   Cleaned dataset: n = %d samples\n", nrow(df_clean)))

# =============================================================================
# 2. Correlations with Cleaned Data
# =============================================================================

cat("\n2. Calculating correlations (cleaned data)...\n")

# Define proxy sets
ftir_raw <- c("CH_total", "CH_stretch_2920", "CO_carbonyl_1720", "Aromatic_1600",
              "NH_stretch", "Total_organic_C", "Total_organic_CNSP")

ftir_normalized <- c("CH_norm_Si", "Aromatic_norm_Si", "CO_norm_Si", "NH_norm_Si",
                     "Organic_mineral_norm", "Organic_mineral_ratio", "Char_index_FTIR")

asd_proxies <- c("Vis_slope", "Char_darkness", "Organic_index_1")

# Calculate correlations for all proxies
calc_cors <- function(df, vars, source_name) {
  available_vars <- vars[vars %in% names(df)]

  tibble(
    Proxy = available_vars,
    Source = source_name,
    Pb_r = sapply(available_vars, function(v) {
      if (sum(!is.na(df[[v]])) >= 5) cor(df[[v]], df$Pb_log_ratio, use = "complete.obs")
      else NA
    }),
    Zn_r = sapply(available_vars, function(v) {
      if (sum(!is.na(df[[v]])) >= 5) cor(df[[v]], df$Zn_log_ratio, use = "complete.obs")
      else NA
    }),
    Cu_r = sapply(available_vars, function(v) {
      if (sum(!is.na(df[[v]]) & !is.na(df$Cu_log_ratio)) >= 5) {
        cor(df[[v]], df$Cu_log_ratio, use = "complete.obs")
      } else NA
    }),
    n = sapply(available_vars, function(v) sum(!is.na(df[[v]])))
  ) %>%
    mutate(Mean_abs_r = (abs(Pb_r) + abs(Zn_r) + abs(Cu_r)) / 3)
}

# Get correlations for each proxy type
cors_ftir_raw <- calc_cors(df_clean, ftir_raw, "FTIR_raw")
cors_ftir_norm <- calc_cors(df_clean, ftir_normalized, "FTIR_normalized")
cors_asd <- calc_cors(df_clean, asd_proxies, "ASD")
cors_xrf <- tibble(
  Proxy = "XRF_organic",
  Source = "XRF",
  Pb_r = cor(df_clean$XRF_organic, df_clean$Pb_log_ratio, use = "complete.obs"),
  Zn_r = cor(df_clean$XRF_organic, df_clean$Zn_log_ratio, use = "complete.obs"),
  Cu_r = cor(df_clean$XRF_organic, df_clean$Cu_log_ratio, use = "complete.obs"),
  n = sum(!is.na(df_clean$XRF_organic))
) %>%
  mutate(Mean_abs_r = (abs(Pb_r) + abs(Zn_r) + abs(Cu_r)) / 3)

# Combine all
all_cors_clean <- bind_rows(cors_ftir_raw, cors_ftir_norm, cors_asd, cors_xrf) %>%
  filter(!is.na(Pb_r)) %>%
  arrange(desc(Mean_abs_r))

cat("\n   All Proxy Correlations (XPAH26 excluded):\n")
print(all_cors_clean, n = 20)

# =============================================================================
# 3. Compare Raw vs Normalized FTIR Proxies
# =============================================================================

cat("\n3. Comparing raw vs normalized FTIR proxies...\n")

comparison <- tibble(
  Type = c("Raw", "Normalized"),
  Best_Proxy = c(
    cors_ftir_raw$Proxy[which.max(cors_ftir_raw$Mean_abs_r)],
    cors_ftir_norm$Proxy[which.max(cors_ftir_norm$Mean_abs_r)]
  ),
  Pb_r = c(
    max(abs(cors_ftir_raw$Pb_r), na.rm = TRUE),
    max(abs(cors_ftir_norm$Pb_r), na.rm = TRUE)
  ),
  Zn_r = c(
    max(abs(cors_ftir_raw$Zn_r), na.rm = TRUE),
    max(abs(cors_ftir_norm$Zn_r), na.rm = TRUE)
  ),
  Cu_r = c(
    max(abs(cors_ftir_norm$Cu_r), na.rm = TRUE),
    max(abs(cors_ftir_norm$Cu_r), na.rm = TRUE)
  )
)

cat("\n   Raw vs Normalized FTIR Performance:\n")
print(comparison)

# =============================================================================
# 4. Best Proxy by Element
# =============================================================================

cat("\n4. Best proxy by element (cleaned data)...\n")

best_by_element <- tibble(
  Element = c("Pb", "Zn", "Cu"),
  Best_Proxy = c(
    all_cors_clean$Proxy[which.max(abs(all_cors_clean$Pb_r))],
    all_cors_clean$Proxy[which.max(abs(all_cors_clean$Zn_r))],
    all_cors_clean$Proxy[which.max(abs(all_cors_clean$Cu_r))]
  ),
  Source = c(
    all_cors_clean$Source[which.max(abs(all_cors_clean$Pb_r))],
    all_cors_clean$Source[which.max(abs(all_cors_clean$Zn_r))],
    all_cors_clean$Source[which.max(abs(all_cors_clean$Cu_r))]
  ),
  r = c(
    all_cors_clean$Pb_r[which.max(abs(all_cors_clean$Pb_r))],
    all_cors_clean$Zn_r[which.max(abs(all_cors_clean$Zn_r))],
    all_cors_clean$Cu_r[which.max(abs(all_cors_clean$Cu_r))]
  )
)

cat("\n   Best Proxy by Element:\n")
print(best_by_element)

# =============================================================================
# 5. Best Proxy by Source
# =============================================================================

cat("\n5. Best proxy by source (cleaned data)...\n")

best_by_source <- all_cors_clean %>%
  group_by(Source) %>%
  slice_max(Mean_abs_r, n = 1) %>%
  ungroup() %>%
  select(Source, Proxy, Pb_r, Zn_r, Cu_r, Mean_abs_r)

cat("\n   Best Proxy by Source:\n")
print(best_by_source)

# =============================================================================
# 6. Statistical Significance Tests
# =============================================================================

cat("\n6. Statistical significance (p-values)...\n")

# Test top proxies
test_significance <- function(df, proxy, element_col) {
  if (!proxy %in% names(df)) return(NA)
  test <- cor.test(df[[proxy]], df[[element_col]], use = "complete.obs")
  test$p.value
}

sig_tests <- all_cors_clean %>%
  head(10) %>%
  rowwise() %>%
  mutate(
    Pb_p = test_significance(df_clean, Proxy, "Pb_log_ratio"),
    Zn_p = test_significance(df_clean, Proxy, "Zn_log_ratio"),
    Cu_p = test_significance(df_clean, Proxy, "Cu_log_ratio")
  ) %>%
  ungroup() %>%
  mutate(
    Pb_sig = case_when(Pb_p < 0.001 ~ "***", Pb_p < 0.01 ~ "**", Pb_p < 0.05 ~ "*", TRUE ~ "ns"),
    Zn_sig = case_when(Zn_p < 0.001 ~ "***", Zn_p < 0.01 ~ "**", Zn_p < 0.05 ~ "*", TRUE ~ "ns"),
    Cu_sig = case_when(Cu_p < 0.001 ~ "***", Cu_p < 0.01 ~ "**", Cu_p < 0.05 ~ "*", TRUE ~ "ns")
  )

cat("\n   Top 10 Proxies with Significance:\n")
print(sig_tests %>% select(Proxy, Source, Pb_r, Pb_sig, Zn_r, Zn_sig, Cu_r, Cu_sig))

# =============================================================================
# 7. Generate Cleaned Analysis Figure
# =============================================================================

cat("\n7. Generating figures...\n")

# Panel A: Correlation heatmap
heatmap_data <- all_cors_clean %>%
  head(15) %>%
  select(Proxy, Source, Pb_r, Zn_r, Cu_r) %>%
  pivot_longer(cols = c(Pb_r, Zn_r, Cu_r), names_to = "Element", values_to = "r") %>%
  mutate(
    Element = str_replace(Element, "_r", ""),
    Proxy_label = paste0(Proxy, " (", Source, ")")
  )

p_heatmap <- ggplot(heatmap_data,
                    aes(x = Element, y = reorder(Proxy_label, abs(r)), fill = r)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", r)), size = 3) +
  scale_fill_gradient2(low = "steelblue", mid = "white", high = "firebrick",
                       midpoint = 0, limits = c(-0.6, 0.6)) +
  labs(title = "A) Proxy Correlations (XPAH26 excluded)",
       subtitle = sprintf("Top 15 proxies, n = %d samples", nrow(df_clean)),
       x = "Element", y = "Proxy", fill = "r") +
  theme_bw(base_size = 10) +
  theme(axis.text.y = element_text(size = 8))

# Panel B: Scatter plot - Best FTIR proxy vs Pb
best_ftir_proxy <- cors_ftir_norm$Proxy[which.max(cors_ftir_norm$Mean_abs_r)]
best_ftir_r <- cors_ftir_norm$Pb_r[which.max(cors_ftir_norm$Mean_abs_r)]

p_pb <- ggplot(df_clean, aes(x = .data[[best_ftir_proxy]], y = Pb_log_ratio)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(alpha = 0.7, size = 3, color = "firebrick") +
  geom_smooth(method = "lm", se = TRUE, color = "black") +
  labs(title = sprintf("B) %s vs Pb Offset", best_ftir_proxy),
       subtitle = sprintf("r = %.3f, n = %d", best_ftir_r, nrow(df_clean)),
       x = best_ftir_proxy, y = "log10(ICP-MS Pb / XRF Pb)") +
  theme_bw(base_size = 10)

# Panel C: Best proxy by source comparison
p_source <- ggplot(best_by_source, aes(x = reorder(Source, Mean_abs_r), y = Mean_abs_r, fill = Source)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = Proxy), hjust = -0.1, size = 3) +
  geom_hline(yintercept = 0.3, linetype = "dashed", color = "grey50") +
  coord_flip() +
  scale_fill_manual(values = c("FTIR_raw" = "firebrick", "FTIR_normalized" = "darkred",
                               "ASD" = "steelblue", "XRF" = "grey50")) +
  labs(title = "C) Best Proxy by Source",
       subtitle = "Mean |r| across Pb, Zn, Cu",
       x = "Source", y = "Mean |Correlation|") +
  theme_bw(base_size = 10) +
  theme(legend.position = "none")

# Panel D: Element-specific best proxies
element_plot_data <- tibble(
  Element = c("Pb", "Pb", "Pb", "Zn", "Zn", "Zn", "Cu", "Cu", "Cu"),
  Source = rep(c("FTIR", "ASD", "XRF"), 3),
  r = c(
    # Pb
    max(abs(c(cors_ftir_raw$Pb_r, cors_ftir_norm$Pb_r)), na.rm = TRUE),
    max(abs(cors_asd$Pb_r), na.rm = TRUE),
    abs(cors_xrf$Pb_r),
    # Zn
    max(abs(c(cors_ftir_raw$Zn_r, cors_ftir_norm$Zn_r)), na.rm = TRUE),
    max(abs(cors_asd$Zn_r), na.rm = TRUE),
    abs(cors_xrf$Zn_r),
    # Cu
    max(abs(c(cors_ftir_raw$Cu_r, cors_ftir_norm$Cu_r)), na.rm = TRUE),
    max(abs(cors_asd$Cu_r), na.rm = TRUE),
    abs(cors_xrf$Cu_r)
  )
)

p_element <- ggplot(element_plot_data, aes(x = Element, y = r, fill = Source)) +
  geom_col(position = "dodge", alpha = 0.8) +
  geom_hline(yintercept = 0.3, linetype = "dashed", color = "grey50") +
  scale_fill_manual(values = c("FTIR" = "firebrick", "ASD" = "steelblue", "XRF" = "grey50")) +
  labs(title = "D) Best |r| by Element and Source",
       subtitle = "Comparing FTIR, ASD, and XRF",
       x = "Element", y = "Best |Correlation|") +
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom")

# Combine
fig_clean <- (p_heatmap | p_pb) / (p_source | p_element) +
  plot_annotation(
    title = "Organic Proxy Analysis (Cleaned Dataset - XPAH26 Excluded)",
    subtitle = "Evaluating FTIR, ASD, and XRF proxies for XRF-ICPMS offset prediction",
    theme = theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11)
    )
  )

ggsave(file.path(fig_dir, "Fig11_organic_proxies_cleaned.pdf"),
       fig_clean, width = 12, height = 10)
ggsave(file.path(fig_dir, "Fig11_organic_proxies_cleaned.png"),
       fig_clean, width = 12, height = 10, dpi = 300)

cat("   Saved: figures/Fig11_organic_proxies_cleaned.pdf/png\n")

# =============================================================================
# 8. Export Results
# =============================================================================

cat("\n8. Exporting results...\n")

write_csv(all_cors_clean, file.path(data_dir, "table11_proxy_correlations_cleaned.csv"))
cat("   Saved: data/table11_proxy_correlations_cleaned.csv\n")

# =============================================================================
# Summary
# =============================================================================

cat("\n============================================================\n")
cat("CLEANED ANALYSIS SUMMARY (XPAH26 excluded)\n")
cat("============================================================\n\n")

cat(sprintf("Dataset: n = %d samples (XPAH26 excluded)\n\n", nrow(df_clean)))

cat("BEST PROXY BY ELEMENT:\n")
for (i in 1:nrow(best_by_element)) {
  cat(sprintf("  %s: %s (%s), r = %.3f\n",
              best_by_element$Element[i],
              best_by_element$Best_Proxy[i],
              best_by_element$Source[i],
              best_by_element$r[i]))
}

cat("\nBEST PROXY BY SOURCE (Mean |r|):\n")
for (i in 1:nrow(best_by_source)) {
  cat(sprintf("  %s: %s (Mean |r| = %.3f)\n",
              best_by_source$Source[i],
              best_by_source$Proxy[i],
              best_by_source$Mean_abs_r[i]))
}

cat("\nKEY FINDINGS:\n")
cat("  1. With XPAH26 removed, correlations are more moderate but realistic\n")
cat("  2. Matrix-normalized FTIR ratios may provide better standardization\n")
cat("  3. Different proxies perform best for different elements\n")
cat("  4. No single proxy works optimally across all elements\n")

cat("\n=== Analysis Complete ===\n")
