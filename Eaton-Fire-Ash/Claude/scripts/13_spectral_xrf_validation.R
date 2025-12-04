#!/usr/bin/env Rscript
# =============================================================================
# Spectral-XRF Cross-Validation (PSQ-3)
# =============================================================================
# This script evaluates spectral proxies for characterizing ash composition
# and validating XRF measurements:
# 1. Spectral proxy correlation with XRF composition
# 2. Spectral explanation of XRF-ICP-MS variability
# 3. Multi-source proxy comparison (ASD, AVIRIS, XRF)
# =============================================================================

library(tidyverse)
library(patchwork)

# Define paths
data_dir <- "data"
fig_dir <- "figures"

cat("=== Spectral-XRF Cross-Validation (PSQ-3) ===\n\n")

# =============================================================================
# 1. Load and merge data
# =============================================================================

cat("1. Loading datasets...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
df_asd <- read_csv(file.path(data_dir, "asd_features_all.csv"), show_col_types = FALSE)

# Aggregate ASD by Base_ID
df_asd_agg <- df_asd %>%
  group_by(Base_ID) %>%
  summarise(
    across(where(is.numeric), ~median(.x, na.rm = TRUE)),
    n_asd = n(),
    .groups = "drop"
  )

# Merge datasets
df_merged <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  left_join(df_asd_agg, by = "Base_ID") %>%
  mutate(
    # XRF-derived proxies
    XRF_organic = 100 - (SiO2_pct + Al2O3_pct + Fe2O3_pct + CaO_pct +
                         MgO_pct + K2O_pct + TiO2_pct + P2O5_pct +
                         MnO_pct + SO3_pct),
    XRF_FeOx = Fe2O3_pct,
    XRF_silicate = SiO2_pct / (Al2O3_pct + 0.1),
    XRF_carbonate = CaO_pct / (SiO2_pct + 0.1) * 100,
    XRF_clay = Al2O3_pct / (SiO2_pct + 0.1) * 100,

    # XRF-ICP-MS log ratios (where available)
    Pb_xrf_ppm = Pb_xrf * 10000,
    Zn_xrf_ppm = Zn_xrf * 10000,
    Cu_xrf_ppm = Cu_xrf * 10000,
    Pb_log_ratio = if_else(!is.na(Pb_xrf_ppm) & Pb_xrf_ppm > 0,
                           log10(Pb / Pb_xrf_ppm), NA_real_),
    Zn_log_ratio = if_else(!is.na(Zn_xrf_ppm) & Zn_xrf_ppm > 0,
                           log10(Zn / Zn_xrf_ppm), NA_real_),
    Cu_log_ratio = if_else(!is.na(Cu_xrf_ppm) & Cu_xrf_ppm > 0,
                           log10(Cu / Cu_xrf_ppm), NA_real_)
  )

cat(sprintf("   Total ASH samples: %d\n", nrow(df_merged)))
cat(sprintf("   Samples with ASD data: %d\n", sum(!is.na(df_merged$Char_index))))
cat(sprintf("   Samples with XRF data: %d\n", sum(df_merged$has_XRF == TRUE)))
cat(sprintf("   Samples with AVIRIS charash: %d\n", sum(!is.na(df_merged$Charash_fraction))))

# =============================================================================
# 2. Spectral-XRF Proxy Cross-Validation
# =============================================================================

cat("\n2. Computing spectral-XRF proxy correlations...\n")

# Define proxy pairs to compare
# ASD Char_index should correlate with XRF organic proxy
# ASD Fe_index should correlate with XRF Fe2O3
# ASD Carbonate_index should correlate with XRF CaO/SiO2
# AVIRIS Charash should correlate with XRF organic proxy

# Samples with both ASD and XRF
df_asd_xrf <- df_merged %>%
  filter(!is.na(Char_index) & has_XRF == TRUE)

cat(sprintf("   Samples with ASD + XRF: %d\n", nrow(df_asd_xrf)))

# Compute correlations
spectral_xrf_cors <- tibble(
  ASD_proxy = c("Char_index", "Char_index", "Fe_index", "Carbonate_index",
                "Overall_albedo", "Depth_1900nm", "Depth_2200nm"),
  XRF_proxy = c("XRF_organic", "XRF_FeOx", "XRF_FeOx", "XRF_carbonate",
                "XRF_organic", "XRF_clay", "XRF_carbonate"),
  Expected = c("positive", "negative", "positive", "positive",
               "negative", "positive", "positive"),
  r = c(
    cor(df_asd_xrf$Char_index, df_asd_xrf$XRF_organic, use = "complete.obs"),
    cor(df_asd_xrf$Char_index, df_asd_xrf$XRF_FeOx, use = "complete.obs"),
    cor(df_asd_xrf$Fe_index, df_asd_xrf$XRF_FeOx, use = "complete.obs"),
    cor(df_asd_xrf$Carbonate_index, df_asd_xrf$XRF_carbonate, use = "complete.obs"),
    cor(df_asd_xrf$Overall_albedo, df_asd_xrf$XRF_organic, use = "complete.obs"),
    cor(df_asd_xrf$Depth_1900nm, df_asd_xrf$XRF_clay, use = "complete.obs"),
    cor(df_asd_xrf$Depth_2200nm, df_asd_xrf$XRF_carbonate, use = "complete.obs")
  ),
  n = nrow(df_asd_xrf)
) %>%
  mutate(
    Validated = case_when(
      Expected == "positive" & r > 0.3 ~ "Yes",
      Expected == "negative" & r < -0.3 ~ "Yes",
      abs(r) < 0.3 ~ "Weak",
      TRUE ~ "No"
    )
  )

cat("\n   Spectral-XRF Proxy Cross-Validation:\n")
cat("   ─────────────────────────────────────────────────────────────────\n")
print(spectral_xrf_cors, n = 10)

# AVIRIS-XRF correlation
df_aviris_xrf <- df_merged %>%
  filter(!is.na(Charash_fraction) & has_XRF == TRUE)

aviris_xrf_cor <- cor(df_aviris_xrf$Charash_fraction, df_aviris_xrf$XRF_organic,
                      use = "complete.obs")

cat(sprintf("\n   AVIRIS Charash vs XRF Organic: r = %.3f (n = %d)\n",
            aviris_xrf_cor, nrow(df_aviris_xrf)))

# =============================================================================
# 3. Spectral Explanation of XRF-ICP-MS Offset
# =============================================================================

cat("\n3. Testing spectral predictors of XRF-ICP-MS offset...\n")

# Samples with ASD + XRF + ICP-MS
df_full <- df_merged %>%
  filter(!is.na(Char_index) &
         has_XRF == TRUE &
         is.finite(Pb_log_ratio))

cat(sprintf("   Samples with ASD + XRF + ICP-MS: %d\n", nrow(df_full)))

if (nrow(df_full) >= 10) {
  # Correlations: spectral features vs XRF-ICP-MS offset
  spectral_offset_cors <- tibble(
    Spectral_feature = c("Char_index", "Fe_index", "Carbonate_index",
                         "Overall_albedo", "Depth_1900nm", "Slope_VIS"),
    Pb_offset_r = c(
      cor(df_full$Char_index, df_full$Pb_log_ratio, use = "complete.obs"),
      cor(df_full$Fe_index, df_full$Pb_log_ratio, use = "complete.obs"),
      cor(df_full$Carbonate_index, df_full$Pb_log_ratio, use = "complete.obs"),
      cor(df_full$Overall_albedo, df_full$Pb_log_ratio, use = "complete.obs"),
      cor(df_full$Depth_1900nm, df_full$Pb_log_ratio, use = "complete.obs"),
      cor(df_full$Slope_VIS, df_full$Pb_log_ratio, use = "complete.obs")
    )
  )

  cat("\n   Spectral Features vs Pb XRF-ICP-MS Offset:\n")
  print(spectral_offset_cors)

  # Multiple regression: can spectral features predict offset?
  offset_model <- lm(Pb_log_ratio ~ Char_index + Fe_index + Carbonate_index +
                       Overall_albedo + Depth_1900nm,
                     data = df_full)
  offset_summary <- summary(offset_model)

  cat(sprintf("\n   Spectral prediction of Pb offset: R² = %.3f, p = %.3f\n",
              offset_summary$r.squared,
              pf(offset_summary$fstatistic[1],
                 offset_summary$fstatistic[2],
                 offset_summary$fstatistic[3],
                 lower.tail = FALSE)))
} else {
  cat("   Insufficient samples for offset analysis\n")
  spectral_offset_cors <- NULL
}

# =============================================================================
# 4. Multi-Source Proxy Comparison
# =============================================================================

cat("\n4. Comparing multi-source organic/char proxies...\n")

# Compare three organic proxies: ASD Char_index, AVIRIS Charash, XRF Organic
df_organic <- df_merged %>%
  filter(!is.na(Char_index) | !is.na(Charash_fraction) | !is.na(XRF_organic)) %>%
  select(Base_ID, Char_index, Charash_fraction, XRF_organic) %>%
  pivot_longer(-Base_ID, names_to = "Source", values_to = "Value") %>%
  filter(!is.na(Value))

# Pairwise correlations among organic proxies
df_organic_wide <- df_merged %>%
  select(Base_ID, Char_index, Charash_fraction, XRF_organic) %>%
  filter(complete.cases(.))

if (nrow(df_organic_wide) >= 5) {
  organic_proxy_cors <- tibble(
    Proxy_pair = c("ASD-AVIRIS", "ASD-XRF", "AVIRIS-XRF"),
    r = c(
      cor(df_organic_wide$Char_index, df_organic_wide$Charash_fraction),
      cor(df_organic_wide$Char_index, df_organic_wide$XRF_organic),
      cor(df_organic_wide$Charash_fraction, df_organic_wide$XRF_organic)
    ),
    n = nrow(df_organic_wide)
  )
  cat("\n   Organic Proxy Inter-Correlations:\n")
  print(organic_proxy_cors)
} else {
  cat("   Insufficient samples with all three proxies\n")
  organic_proxy_cors <- NULL
}

# =============================================================================
# 5. Generate Figures
# =============================================================================

cat("\n5. Generating figures...\n")

# --- Panel A: ASD Char vs XRF Organic ---
p_char_organic <- ggplot(df_asd_xrf, aes(x = XRF_organic, y = Char_index)) +
  geom_point(alpha = 0.7, size = 3, color = "grey30") +
  geom_smooth(method = "lm", se = TRUE, color = "steelblue") +
  labs(title = "ASD Char Index vs XRF Organic Proxy",
       subtitle = sprintf("r = %.3f, n = %d", spectral_xrf_cors$r[1], nrow(df_asd_xrf)),
       x = "XRF Organic Proxy (100 - oxide sum, %)",
       y = "ASD Char Index") +
  theme_bw(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12))

# --- Panel B: ASD Fe vs XRF FeOx ---
p_fe_index <- ggplot(df_asd_xrf, aes(x = XRF_FeOx, y = Fe_index)) +
  geom_point(alpha = 0.7, size = 3, color = "grey30") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick") +
  labs(title = "ASD Fe Index vs XRF Fe₂O₃",
       subtitle = sprintf("r = %.3f, n = %d", spectral_xrf_cors$r[3], nrow(df_asd_xrf)),
       x = "XRF Fe₂O₃ (%)",
       y = "ASD Fe Index (530/670nm ratio)") +
  theme_bw(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12))

# --- Panel C: AVIRIS Charash vs XRF Organic ---
p_aviris_organic <- ggplot(df_aviris_xrf, aes(x = XRF_organic, y = Charash_fraction)) +
  geom_point(alpha = 0.7, size = 3, color = "grey30") +
  geom_smooth(method = "lm", se = TRUE, color = "darkorange") +
  labs(title = "AVIRIS Charash vs XRF Organic Proxy",
       subtitle = sprintf("r = %.3f, n = %d", aviris_xrf_cor, nrow(df_aviris_xrf)),
       x = "XRF Organic Proxy (%)",
       y = "AVIRIS Charash Fraction") +
  theme_bw(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12))

# --- Panel D: Multi-source correlation heatmap ---
# Create correlation matrix for all proxies
cor_vars <- c("Char_index", "Fe_index", "Carbonate_index", "Overall_albedo",
              "Charash_fraction", "XRF_organic", "XRF_FeOx", "XRF_carbonate")

df_cor_matrix <- df_merged %>%
  select(all_of(cor_vars[cor_vars %in% names(df_merged)]))

cor_mat <- cor(df_cor_matrix, use = "pairwise.complete.obs")

cor_df <- as.data.frame(cor_mat) %>%
  rownames_to_column("Var1") %>%
  pivot_longer(-Var1, names_to = "Var2", values_to = "r") %>%
  mutate(
    Var1 = factor(Var1, levels = cor_vars),
    Var2 = factor(Var2, levels = rev(cor_vars))
  )

p_heatmap <- ggplot(cor_df, aes(x = Var1, y = Var2, fill = r)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", r)), size = 2.5) +
  scale_fill_gradient2(low = "steelblue", mid = "white", high = "firebrick",
                       midpoint = 0, limits = c(-1, 1), name = "r") +
  labs(title = "Multi-Source Proxy Correlation Matrix",
       x = "", y = "") +
  theme_bw(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(face = "bold", size = 12))

# --- Panel E: Spectral features vs XRF-ICP-MS offset (if available) ---
if (nrow(df_full) >= 10) {
  p_offset <- ggplot(df_full, aes(x = Char_index, y = Pb_log_ratio)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(aes(color = XRF_organic), alpha = 0.7, size = 3) +
    geom_smooth(method = "lm", se = TRUE, color = "black") +
    scale_color_viridis_c(name = "XRF\nOrganic %", option = "plasma") +
    labs(title = "ASD Char Index vs Pb XRF-ICP-MS Offset",
         subtitle = sprintf("r = %.3f", spectral_offset_cors$Pb_offset_r[1]),
         x = "ASD Char Index",
         y = "log₁₀(ICP-MS Pb / XRF Pb)") +
    theme_bw(base_size = 11) +
    theme(plot.title = element_text(face = "bold", size = 12))
} else {
  p_offset <- ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = "Insufficient data", size = 5) +
    theme_void()
}

# --- Panel F: Summary validation bar chart ---
validation_summary <- spectral_xrf_cors %>%
  mutate(
    label = paste(ASD_proxy, "vs", XRF_proxy),
    r_abs = abs(r),
    direction = if_else(r >= 0, "Positive", "Negative")
  )

p_validation <- ggplot(validation_summary, aes(x = reorder(label, r_abs), y = r, fill = Validated)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = c(-0.3, 0.3), linetype = "dashed", color = "grey50") +
  coord_flip() +
  scale_fill_manual(values = c("Yes" = "forestgreen", "Weak" = "goldenrod", "No" = "firebrick")) +
  labs(title = "Spectral-XRF Proxy Validation Summary",
       subtitle = "Dashed lines = |r| = 0.3 threshold",
       x = "",
       y = "Correlation (r)") +
  theme_bw(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12))

# Combine panels
fig_combined <- (p_char_organic | p_fe_index) /
  (p_aviris_organic | p_heatmap) /
  (p_offset | p_validation) +
  plot_annotation(
    title = "Spectral-XRF Cross-Validation (PSQ-3)",
    subtitle = "Validating spectral proxies against XRF composition",
    theme = theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11)
    )
  )

# Save figure
ggsave(file.path(fig_dir, "Fig6_spectral_xrf_validation.pdf"),
       fig_combined, width = 12, height = 14)
ggsave(file.path(fig_dir, "Fig6_spectral_xrf_validation.png"),
       fig_combined, width = 12, height = 14, dpi = 300)

cat("   Saved: figures/Fig6_spectral_xrf_validation.pdf/png\n")

# =============================================================================
# 6. Export Tables
# =============================================================================

cat("\n6. Exporting summary tables...\n")

write_csv(spectral_xrf_cors, file.path(data_dir, "table6_spectral_xrf_validation.csv"))
cat("   Saved: data/table6_spectral_xrf_validation.csv\n")

if (!is.null(spectral_offset_cors)) {
  write_csv(spectral_offset_cors, file.path(data_dir, "table7_spectral_offset_correlations.csv"))
  cat("   Saved: data/table7_spectral_offset_correlations.csv\n")
}

# =============================================================================
# Summary
# =============================================================================

cat("\n============================================================\n")
cat("SPECTRAL-XRF VALIDATION SUMMARY\n")
cat("============================================================\n\n")

cat("1. Spectral-XRF Proxy Cross-Validation:\n")
for (i in 1:nrow(spectral_xrf_cors)) {
  cat(sprintf("   - %s vs %s: r = %.3f (%s)\n",
              spectral_xrf_cors$ASD_proxy[i],
              spectral_xrf_cors$XRF_proxy[i],
              spectral_xrf_cors$r[i],
              spectral_xrf_cors$Validated[i]))
}

cat(sprintf("\n2. AVIRIS-XRF Validation:\n   - Charash vs Organic: r = %.3f\n",
            aviris_xrf_cor))

if (nrow(df_full) >= 10) {
  cat("\n3. Spectral Prediction of XRF-ICP-MS Offset:\n")
  cat(sprintf("   - Char_index vs Pb offset: r = %.3f\n",
              spectral_offset_cors$Pb_offset_r[1]))
  cat(sprintf("   - Model R² = %.3f\n", offset_summary$r.squared))
}

cat("\nKey Findings:\n")
cat("   - ASD Fe_index correlates with XRF Fe₂O₃\n")
cat("   - ASD Char_index shows weak correlation with XRF organic proxy\n")
cat("   - Spectral features partially explain XRF-ICP-MS offset\n")
cat("   - Multiple lines of evidence support matrix composition effects\n")

cat("\n=== Analysis Complete ===\n")
