#!/usr/bin/env Rscript
# =============================================================================
# 10_enrichment_factor_analysis.R
# Enrichment factor calculations and elemental ratio analysis
# Neutral presentation of geochemical data without source attribution
# =============================================================================

library(tidyverse)
library(patchwork)

cat("=== Enrichment Factor and Elemental Ratio Analysis ===\n\n")

# Set paths
data_dir <- "data"
fig_dir <- "figures"

# -----------------------------------------------------------------------------
# 1. Load Datasets
# -----------------------------------------------------------------------------
cat("1. Loading datasets...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
df_ef <- read_csv(file.path(data_dir, "elemental_ratios_ef.csv"), show_col_types = FALSE)
df_mineral <- read_csv(file.path(data_dir, "mineral_metal_correlations.csv"), show_col_types = FALSE)

# Join enrichment data to master
df_full <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  left_join(df_ef, by = "Base_ID")

cat(sprintf("   Total ASH samples: %d\n", nrow(df_full)))
cat(sprintf("   Samples with EF data: %d\n", sum(!is.na(df_full$EF_Pb))))

# -----------------------------------------------------------------------------
# 2. Enrichment Factor Summary Statistics
# -----------------------------------------------------------------------------
cat("\n2. Calculating enrichment factor statistics...\n")

ef_stats <- df_full %>%
  summarise(
    across(c(EF_Pb, EF_Zn, EF_Cu, EF_Cr, EF_Ni),
           list(
             median = ~median(., na.rm = TRUE),
             iqr_low = ~quantile(., 0.25, na.rm = TRUE),
             iqr_high = ~quantile(., 0.75, na.rm = TRUE),
             min = ~min(., na.rm = TRUE),
             max = ~max(., na.rm = TRUE),
             pct_gt2 = ~100 * sum(. > 2, na.rm = TRUE) / sum(!is.na(.)),
             cv = ~100 * sd(., na.rm = TRUE) / mean(., na.rm = TRUE)
           ))
  )

cat("\nEnrichment Factor Summary (Al-normalized, UCC reference):\n")
cat("\n  Metal    Median    IQR           Range           %EF>2   CV(%)\n")
cat("  ----------------------------------------------------------------\n")
cat(sprintf("  Pb       %6.1f    %5.1f-%5.1f    %5.1f-%7.1f   %5.0f   %5.0f\n",
            ef_stats$EF_Pb_median, ef_stats$EF_Pb_iqr_low, ef_stats$EF_Pb_iqr_high,
            ef_stats$EF_Pb_min, ef_stats$EF_Pb_max, ef_stats$EF_Pb_pct_gt2, ef_stats$EF_Pb_cv))
cat(sprintf("  Zn       %6.1f    %5.1f-%5.1f    %5.1f-%7.1f   %5.0f   %5.0f\n",
            ef_stats$EF_Zn_median, ef_stats$EF_Zn_iqr_low, ef_stats$EF_Zn_iqr_high,
            ef_stats$EF_Zn_min, ef_stats$EF_Zn_max, ef_stats$EF_Zn_pct_gt2, ef_stats$EF_Zn_cv))
cat(sprintf("  Cu       %6.1f    %5.1f-%5.1f    %5.1f-%7.1f   %5.0f   %5.0f\n",
            ef_stats$EF_Cu_median, ef_stats$EF_Cu_iqr_low, ef_stats$EF_Cu_iqr_high,
            ef_stats$EF_Cu_min, ef_stats$EF_Cu_max, ef_stats$EF_Cu_pct_gt2, ef_stats$EF_Cu_cv))
cat(sprintf("  Cr       %6.1f    %5.1f-%5.1f    %5.1f-%7.1f   %5.0f   %5.0f\n",
            ef_stats$EF_Cr_median, ef_stats$EF_Cr_iqr_low, ef_stats$EF_Cr_iqr_high,
            ef_stats$EF_Cr_min, ef_stats$EF_Cr_max, ef_stats$EF_Cr_pct_gt2, ef_stats$EF_Cr_cv))
cat(sprintf("  Ni       %6.1f    %5.1f-%5.1f    %5.1f-%7.1f   %5.0f   %5.0f\n",
            ef_stats$EF_Ni_median, ef_stats$EF_Ni_iqr_low, ef_stats$EF_Ni_iqr_high,
            ef_stats$EF_Ni_min, ef_stats$EF_Ni_max, ef_stats$EF_Ni_pct_gt2, ef_stats$EF_Ni_cv))

cat("\n  Note: High CV values (>100%) indicate substantial sample heterogeneity.\n")
cat("  Extreme max values likely reflect matrix effects or localized heterogeneity.\n")

# -----------------------------------------------------------------------------
# 3. Elemental Ratio Summary
# -----------------------------------------------------------------------------
cat("\n3. Calculating elemental ratio statistics...\n")

ratio_stats <- df_full %>%
  summarise(
    across(c(Pb_Zn, Cu_Zn, Pb_Cu, Ca_Mg),
           list(
             median = ~median(., na.rm = TRUE),
             iqr_low = ~quantile(., 0.25, na.rm = TRUE),
             iqr_high = ~quantile(., 0.75, na.rm = TRUE),
             min = ~min(., na.rm = TRUE),
             max = ~max(., na.rm = TRUE)
           ), .names = "{.col}_{.fn}")
  )

cat("\nElemental Ratio Summary:\n")
cat("\n  Ratio    Median    IQR             Range\n")
cat("  --------------------------------------------------\n")
cat(sprintf("  Pb/Zn    %6.3f    %5.3f-%5.3f     %5.3f-%6.2f\n",
            ratio_stats$Pb_Zn_median, ratio_stats$Pb_Zn_iqr_low, ratio_stats$Pb_Zn_iqr_high,
            ratio_stats$Pb_Zn_min, ratio_stats$Pb_Zn_max))
cat(sprintf("  Cu/Zn    %6.3f    %5.3f-%5.3f     %5.3f-%6.2f\n",
            ratio_stats$Cu_Zn_median, ratio_stats$Cu_Zn_iqr_low, ratio_stats$Cu_Zn_iqr_high,
            ratio_stats$Cu_Zn_min, ratio_stats$Cu_Zn_max))
cat(sprintf("  Pb/Cu    %6.2f    %5.2f-%5.2f     %5.2f-%6.1f\n",
            ratio_stats$Pb_Cu_median, ratio_stats$Pb_Cu_iqr_low, ratio_stats$Pb_Cu_iqr_high,
            ratio_stats$Pb_Cu_min, ratio_stats$Pb_Cu_max))
cat(sprintf("  Ca/Mg    %6.1f    %5.1f-%5.1f     %5.1f-%6.1f\n",
            ratio_stats$Ca_Mg_median, ratio_stats$Ca_Mg_iqr_low, ratio_stats$Ca_Mg_iqr_high,
            ratio_stats$Ca_Mg_min, ratio_stats$Ca_Mg_max))

cat("\n  Note: Wide ranges reflect compositional heterogeneity among samples.\n")

# -----------------------------------------------------------------------------
# 4. Inter-Metal Correlations
# -----------------------------------------------------------------------------
cat("\n4. Calculating inter-metal correlations...\n")

df_metals <- df_full %>%
  select(Pb, Zn, Cu, As, Cr, Ni, Fe) %>%
  drop_na()

cor_matrix <- cor(df_metals, use = "complete.obs")

cat("\nInter-metal correlation matrix:\n")
cat(sprintf("  Pb-Zn: r = %.3f\n", cor_matrix["Pb", "Zn"]))
cat(sprintf("  Pb-Cu: r = %.3f\n", cor_matrix["Pb", "Cu"]))
cat(sprintf("  Zn-Cu: r = %.3f\n", cor_matrix["Zn", "Cu"]))
cat(sprintf("  Cr-Ni: r = %.3f\n", cor_matrix["Cr", "Ni"]))
cat(sprintf("  Pb-Fe: r = %.3f\n", cor_matrix["Pb", "Fe"]))
cat(sprintf("  Cr-Fe: r = %.3f\n", cor_matrix["Cr", "Fe"]))

# -----------------------------------------------------------------------------
# 5. Generate Neutral Figure
# -----------------------------------------------------------------------------
cat("\n5. Generating figure...\n")

# Panel A: EF distribution by metal (no color coding by "source type")
ef_long <- df_full %>%
  select(Base_ID, EF_Pb, EF_Zn, EF_Cu, EF_Cr, EF_Ni) %>%
  pivot_longer(-Base_ID, names_to = "Metal", values_to = "EF") %>%
  mutate(
    Metal = str_remove(Metal, "EF_"),
    Metal = factor(Metal, levels = c("Pb", "Zn", "Cu", "Cr", "Ni"))
  ) %>%
  filter(!is.na(EF))

p_ef <- ggplot(ef_long, aes(x = Metal, y = EF)) +
  geom_boxplot(fill = "grey70", alpha = 0.7, outlier.shape = 21) +
  geom_hline(yintercept = c(2, 5, 20), linetype = "dashed",
             color = "grey40", linewidth = 0.5) +
  scale_y_log10(limits = c(0.1, 3000)) +
  labs(title = "A) Enrichment Factor Distributions",
       subtitle = "Al-normalized, UCC reference",
       x = NULL, y = "Enrichment Factor (log scale)") +
  theme_bw(base_size = 11) +
  annotate("text", x = 5.4, y = 2.5, label = "EF=2", size = 2.5, color = "grey40") +
  annotate("text", x = 5.4, y = 6, label = "EF=5", size = 2.5, color = "grey40") +
  annotate("text", x = 5.4, y = 25, label = "EF=20", size = 2.5, color = "grey40")

# Panel B: Pb/Zn vs Cu/Zn scatter (no colored source regions)
df_ratios <- df_full %>%
  filter(!is.na(Pb_Zn) & !is.na(Cu_Zn))

p_ratios <- ggplot(df_ratios, aes(x = Pb_Zn, y = Cu_Zn)) +
  geom_point(aes(size = log10(EF_Pb + 1)), alpha = 0.6, color = "grey30") +
  scale_x_log10(limits = c(0.001, 15)) +
  scale_y_log10(limits = c(0.001, 3)) +
  labs(title = "B) Elemental Ratio Variability",
       subtitle = "Point size proportional to log(Pb EF)",
       x = "Pb/Zn ratio", y = "Cu/Zn ratio",
       size = "log(EF+1)") +
  theme_bw(base_size = 11) +
  theme(legend.position = "right")

# Panel C: Mineral proxy correlations (no source type labeling)
mineral_cor_data <- df_mineral %>%
  filter(Metal %in% c("Pb", "Zn", "Cu", "Cr", "Ni")) %>%
  pivot_longer(-Metal, names_to = "Mineral", values_to = "Correlation") %>%
  mutate(
    Metal = factor(Metal, levels = c("Pb", "Zn", "Cu", "Cr", "Ni")),
    Mineral = str_remove(Mineral, "_proxy")
  )

p_mineral <- ggplot(mineral_cor_data, aes(x = Mineral, y = Metal, fill = Correlation)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", Correlation)), size = 2.5) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(title = "C) Metal-Mineral Proxy Correlations",
       subtitle = "XRF-derived indices",
       x = NULL, y = NULL, fill = "r") +
  theme_bw(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Panel D: EF vs concentration (showing heterogeneity)
p_heterogeneity <- ggplot(df_full %>% filter(!is.na(EF_Pb) & !is.na(Total_Toxics_ppm)),
                          aes(x = EF_Pb, y = Total_Toxics_ppm)) +
  geom_point(alpha = 0.6, color = "grey30", size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  scale_x_log10() +
  scale_y_log10() +
  labs(title = "D) Pb Enrichment vs Total Metal Load",
       subtitle = "Illustrating sample heterogeneity",
       x = "Pb Enrichment Factor",
       y = "Total Metals (ppm)") +
  theme_bw(base_size = 11)

# Combine panels
fig_ef <- (p_ef | p_ratios) / (p_mineral | p_heterogeneity) +
  plot_annotation(
    title = "Enrichment Factors and Elemental Ratios in Eaton Fire Ash",
    subtitle = "Compositional variability across samples",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(fig_dir, "Fig7_enrichment_ratios.pdf"), fig_ef,
       width = 12, height = 10)
ggsave(file.path(fig_dir, "Fig7_enrichment_ratios.png"), fig_ef,
       width = 12, height = 10, dpi = 300)
cat("   Saved: figures/Fig7_enrichment_ratios.pdf/png\n")

# -----------------------------------------------------------------------------
# 6. Export Summary Table
# -----------------------------------------------------------------------------
cat("\n6. Exporting summary table...\n")

ef_summary_table <- tibble(
  Metal = c("Pb", "Zn", "Cu", "Cr", "Ni"),
  Median_EF = c(ef_stats$EF_Pb_median, ef_stats$EF_Zn_median, ef_stats$EF_Cu_median,
                ef_stats$EF_Cr_median, ef_stats$EF_Ni_median),
  IQR = c(paste0(round(ef_stats$EF_Pb_iqr_low,1), "-", round(ef_stats$EF_Pb_iqr_high,1)),
          paste0(round(ef_stats$EF_Zn_iqr_low,1), "-", round(ef_stats$EF_Zn_iqr_high,1)),
          paste0(round(ef_stats$EF_Cu_iqr_low,1), "-", round(ef_stats$EF_Cu_iqr_high,1)),
          paste0(round(ef_stats$EF_Cr_iqr_low,1), "-", round(ef_stats$EF_Cr_iqr_high,1)),
          paste0(round(ef_stats$EF_Ni_iqr_low,1), "-", round(ef_stats$EF_Ni_iqr_high,1))),
  Min = c(ef_stats$EF_Pb_min, ef_stats$EF_Zn_min, ef_stats$EF_Cu_min,
          ef_stats$EF_Cr_min, ef_stats$EF_Ni_min),
  Max = c(ef_stats$EF_Pb_max, ef_stats$EF_Zn_max, ef_stats$EF_Cu_max,
          ef_stats$EF_Cr_max, ef_stats$EF_Ni_max),
  Pct_EF_gt_2 = c(ef_stats$EF_Pb_pct_gt2, ef_stats$EF_Zn_pct_gt2, ef_stats$EF_Cu_pct_gt2,
                  ef_stats$EF_Cr_pct_gt2, ef_stats$EF_Ni_pct_gt2),
  CV_pct = c(ef_stats$EF_Pb_cv, ef_stats$EF_Zn_cv, ef_stats$EF_Cu_cv,
             ef_stats$EF_Cr_cv, ef_stats$EF_Ni_cv)
)

write_csv(ef_summary_table, file.path(data_dir, "enrichment_factor_summary_neutral.csv"))
cat("   Saved: data/enrichment_factor_summary_neutral.csv\n")

# -----------------------------------------------------------------------------
# 7. Summary
# -----------------------------------------------------------------------------
cat("\n", rep("=", 60), "\n", sep = "")
cat("ANALYSIS SUMMARY\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Enrichment factor distributions:\n")
cat(sprintf("  - Pb, Zn, Cu show median EF values of %.1f, %.1f, %.1f\n",
            ef_stats$EF_Pb_median, ef_stats$EF_Zn_median, ef_stats$EF_Cu_median))
cat(sprintf("  - Cr, Ni show median EF values of %.1f, %.1f\n",
            ef_stats$EF_Cr_median, ef_stats$EF_Ni_median))
cat(sprintf("  - High CV values (%.0f-%.0f%%) indicate substantial heterogeneity\n",
            min(ef_stats$EF_Pb_cv, ef_stats$EF_Cr_cv), max(ef_stats$EF_Pb_cv, ef_stats$EF_Zn_cv)))

cat("\nElemental ratios:\n")
cat(sprintf("  - Pb/Zn median = %.3f (range: %.3f-%.1f)\n",
            ratio_stats$Pb_Zn_median, ratio_stats$Pb_Zn_min, ratio_stats$Pb_Zn_max))
cat(sprintf("  - Cu/Zn median = %.3f (range: %.3f-%.1f)\n",
            ratio_stats$Cu_Zn_median, ratio_stats$Cu_Zn_min, ratio_stats$Cu_Zn_max))
cat("  - Wide ranges reflect compositional heterogeneity\n")

cat("\nInter-metal relationships:\n")
cat(sprintf("  - Strong Pb-Cu correlation (r = %.2f)\n", cor_matrix["Pb", "Cu"]))
cat(sprintf("  - Weak Pb-Zn correlation (r = %.2f)\n", cor_matrix["Pb", "Zn"]))
cat(sprintf("  - Moderate Cr-Ni correlation (r = %.2f)\n", cor_matrix["Cr", "Ni"]))

cat("\nNote: Interpretation of enrichment factors is limited by:\n")
cat("  - Uncertainty in local background composition\n")
cat("  - Al normalization assumptions\n")
cat("  - Sample heterogeneity (high CV values)\n")
cat("  - Arbitrary nature of EF thresholds\n")

cat("\n=== Analysis Complete ===\n")
