#!/usr/bin/env Rscript
# =============================================================================
# 08_publication_figures.R
# Generate publication-quality figures for manuscript
# =============================================================================

library(tidyverse)
library(sf)
library(patchwork)
library(viridis)
library(scales)

cat("=== Generating Publication Figures ===\n\n")

# Set paths
data_dir <- "data"
fig_dir <- "figures"

# Create figure directory
dir.create(fig_dir, showWarnings = FALSE)

# Set theme for publication
theme_pub <- theme_bw(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "grey95"),
    legend.background = element_rect(fill = "white", color = "grey80"),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.title = element_text(size = 10),
    legend.title = element_text(size = 9, face = "bold"),
    legend.text = element_text(size = 8)
  )

# -----------------------------------------------------------------------------
# 1. Load Data
# -----------------------------------------------------------------------------
cat("1. Loading data...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
df_ash <- df_master %>% filter(Sample_Type == "ASH")

epa_exceedance <- read_csv(file.path(data_dir, "table3_epa_exceedance.csv"), show_col_types = FALSE)
moran_results <- read_csv(file.path(data_dir, "moran_spatial_autocorrelation.csv"), show_col_types = FALSE)
spectral_models <- read_csv(file.path(data_dir, "table4_spectral_models.csv"), show_col_types = FALSE)
mineral_cors <- read_csv(file.path(data_dir, "mineral_metal_correlations.csv"), show_col_types = FALSE)

cat(sprintf("   Loaded data for %d ASH samples\n", nrow(df_ash)))

# -----------------------------------------------------------------------------
# Figure 1: Study Area Map (placeholder - requires basemap)
# -----------------------------------------------------------------------------
cat("\n2. Figure 1: Study area context...\n")

sf_ash <- df_ash %>%
  filter(!is.na(Longitude) & !is.na(Latitude)) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)

# Simple location map
fig1 <- ggplot(sf_ash) +
  geom_sf(aes(color = log10(Pb + 1)), size = 3, alpha = 0.8) +
  scale_color_viridis(name = "log10(Pb)", option = "inferno") +
  labs(
    title = "Figure 1: Eaton Fire Ash Sample Locations",
    subtitle = "Los Angeles County, California - January 2025 Fire",
    x = "Longitude", y = "Latitude"
  ) +
  theme_pub +
  coord_sf()

ggsave(file.path(fig_dir, "Fig1_study_area.pdf"), fig1, width = 8, height = 6)
ggsave(file.path(fig_dir, "Fig1_study_area.png"), fig1, width = 8, height = 6, dpi = 300)
cat("   Saved: Fig1_study_area.pdf/png\n")

# -----------------------------------------------------------------------------
# Figure 2: Metal Concentration Summary with EPA RSLs
# -----------------------------------------------------------------------------
cat("\n3. Figure 2: Metal concentrations and EPA screening levels...\n")

# EPA RSL values
EPA_RSL <- tibble(
  Metal = c("Pb", "As", "Cd", "Cr", "Cu", "Ni", "Zn", "Mn", "Ba"),
  RSL_ppm = c(400, 0.68, 70, 5.6, 3100, 1500, 23000, 1800, 15000)
)

# Prepare data for boxplots
metals_to_plot <- c("Pb", "As", "Cr", "Cu", "Zn", "Ni", "Mn", "Cd")

plot_data <- df_ash %>%
  select(all_of(metals_to_plot)) %>%
  pivot_longer(everything(), names_to = "Metal", values_to = "Concentration") %>%
  left_join(EPA_RSL, by = "Metal") %>%
  mutate(
    Metal = factor(Metal, levels = metals_to_plot),
    Exceeds_RSL = Concentration > RSL_ppm
  )

fig2 <- ggplot(plot_data, aes(x = Metal, y = Concentration)) +
  geom_boxplot(aes(fill = Metal), alpha = 0.7, outlier.shape = 21, outlier.alpha = 0.6) +
  geom_point(data = EPA_RSL %>% filter(Metal %in% metals_to_plot),
             aes(x = Metal, y = RSL_ppm),
             shape = 18, size = 4, color = "red") +
  geom_hline(data = EPA_RSL %>% filter(Metal %in% metals_to_plot),
             aes(yintercept = RSL_ppm), linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_log10(labels = comma) +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  labs(
    title = "Metal Concentrations in Eaton Fire Ash",
    subtitle = "Red diamonds indicate EPA Regional Screening Levels (RSL)",
    x = "Element",
    y = "Concentration (ppm, log scale)"
  ) +
  theme_pub +
  annotate("text", x = 8.3, y = max(plot_data$Concentration, na.rm = TRUE) * 0.8,
           label = "EPA RSL", color = "red", size = 3.5, hjust = 1)

ggsave(file.path(fig_dir, "Fig2_metal_concentrations.pdf"), fig2, width = 10, height = 6)
ggsave(file.path(fig_dir, "Fig2_metal_concentrations.png"), fig2, width = 10, height = 6, dpi = 300)
cat("   Saved: Fig2_metal_concentrations.pdf/png\n")

# -----------------------------------------------------------------------------
# Figure 3: Spatial Distribution with Hotspots
# -----------------------------------------------------------------------------
cat("\n4. Figure 3: Spatial distribution of metals...\n")

# Create spatial object for plotting
sf_plot <- st_as_sf(df_ash %>% filter(!is.na(Longitude)),
                    coords = c("Longitude", "Latitude"), crs = 4326)

# Panel A: Lead concentration
p3a <- ggplot(sf_plot) +
  geom_sf(aes(color = log10(Pb + 1), size = log10(Pb + 1)), alpha = 0.8) +
  scale_color_viridis(name = "log10(Pb)", option = "inferno") +
  scale_size_continuous(range = c(2, 5), guide = "none") +
  labs(title = "A) Lead (Pb)") +
  theme_pub +
  theme(legend.position = c(0.15, 0.25),
        legend.key.size = unit(0.4, "cm"))

# Panel B: Zinc concentration
p3b <- ggplot(sf_plot) +
  geom_sf(aes(color = log10(Zn + 1), size = log10(Zn + 1)), alpha = 0.8) +
  scale_color_viridis(name = "log10(Zn)", option = "plasma") +
  scale_size_continuous(range = c(2, 5), guide = "none") +
  labs(title = "B) Zinc (Zn)") +
  theme_pub +
  theme(legend.position = c(0.15, 0.25),
        legend.key.size = unit(0.4, "cm"))

# Panel C: Copper concentration
p3c <- ggplot(sf_plot) +
  geom_sf(aes(color = log10(Cu + 1), size = log10(Cu + 1)), alpha = 0.8) +
  scale_color_viridis(name = "log10(Cu)", option = "viridis") +
  scale_size_continuous(range = c(2, 5), guide = "none") +
  labs(title = "C) Copper (Cu)") +
  theme_pub +
  theme(legend.position = c(0.15, 0.25),
        legend.key.size = unit(0.4, "cm"))

# Panel D: Number of EPA exceedances
p3d <- ggplot(sf_plot) +
  geom_sf(aes(color = factor(N_exceedances), size = N_exceedances), alpha = 0.8) +
  scale_color_brewer(name = "N Exceedances", palette = "YlOrRd", direction = 1) +
  scale_size_continuous(range = c(2, 5), guide = "none") +
  labs(title = "D) EPA RSL Exceedances") +
  theme_pub +
  theme(legend.position = c(0.15, 0.3),
        legend.key.size = unit(0.35, "cm"))

fig3 <- (p3a | p3b) / (p3c | p3d) +
  plot_annotation(
    title = "Spatial Distribution of Metal Contamination",
    subtitle = paste("Eaton Fire Ash Samples (n =", nrow(sf_plot), ")"),
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(fig_dir, "Fig3_spatial_distribution.pdf"), fig3, width = 11, height = 9)
ggsave(file.path(fig_dir, "Fig3_spatial_distribution.png"), fig3, width = 11, height = 9, dpi = 300)
cat("   Saved: Fig3_spatial_distribution.pdf/png\n")

# -----------------------------------------------------------------------------
# Figure 4: Metal Correlations Heatmap
# -----------------------------------------------------------------------------
cat("\n5. Figure 4: Metal correlation heatmap...\n")

# Calculate correlation matrix for metals
metals_cor <- c("Pb", "Zn", "Cu", "As", "Cr", "Ni", "Cd", "Fe", "Ca", "Al", "Mn")
cor_matrix <- df_ash %>%
  select(all_of(metals_cor)) %>%
  cor(use = "pairwise.complete.obs")

# Convert to long format for ggplot
cor_long <- as_tibble(cor_matrix, rownames = "Metal1") %>%
  pivot_longer(-Metal1, names_to = "Metal2", values_to = "Correlation") %>%
  mutate(
    Metal1 = factor(Metal1, levels = metals_cor),
    Metal2 = factor(Metal2, levels = rev(metals_cor))
  )

fig4 <- ggplot(cor_long, aes(x = Metal1, y = Metal2, fill = Correlation)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Correlation)),
            size = 2.5, color = ifelse(abs(cor_long$Correlation) > 0.5, "white", "black")) +
  scale_fill_gradient2(low = "steelblue", mid = "white", high = "firebrick",
                       midpoint = 0, limits = c(-1, 1),
                       name = "Pearson r") +
  labs(
    title = "Inter-element Correlation Matrix",
    subtitle = "Eaton Fire Ash Samples",
    x = "", y = ""
  ) +
  theme_pub +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right",
    panel.grid = element_blank()
  ) +
  coord_fixed()

ggsave(file.path(fig_dir, "Fig4_correlation_heatmap.pdf"), fig4, width = 8, height = 7)
ggsave(file.path(fig_dir, "Fig4_correlation_heatmap.png"), fig4, width = 8, height = 7, dpi = 300)
cat("   Saved: Fig4_correlation_heatmap.pdf/png\n")

# -----------------------------------------------------------------------------
# Figure 5: Spectral Prediction Results (from script 05)
# -----------------------------------------------------------------------------
cat("\n6. Figure 5: Spectral prediction performance...\n")
# (Already generated by 05_psq2_spectral_prediction.R)
cat("   Retained from PSQ-2 analysis: Fig5_spectral_prediction.pdf/png\n")

# -----------------------------------------------------------------------------
# Figure 6: Mineral-Metal Relationships (from script 06)
# -----------------------------------------------------------------------------
cat("\n7. Figure 6: Mineral-metal associations...\n")
# (Already generated by 06_psq3_ftir_analysis.R)
cat("   Retained from PSQ-3 analysis: Fig6_mineral_metal_relationships.pdf/png\n")

# -----------------------------------------------------------------------------
# Figure 7: AVIRIS-Geochemistry Integration
# -----------------------------------------------------------------------------
cat("\n8. Figure 7: AVIRIS-geochemistry relationships...\n")

aviris_data <- df_ash %>%
  filter(!is.na(Charash_fraction) | !is.na(dNBR))

if (nrow(aviris_data) >= 10) {
  # Panel A: Charash vs Pb
  p7a <- ggplot(aviris_data %>% filter(!is.na(Charash_fraction)),
                aes(x = Charash_fraction, y = log10(Pb + 1))) +
    geom_point(size = 3, alpha = 0.7, color = "firebrick") +
    geom_smooth(method = "lm", se = TRUE, color = "darkred", linewidth = 0.8) +
    labs(title = "A) Charash Fraction vs Lead",
         x = "AVIRIS Charash Fraction",
         y = "log10(Pb ppm)") +
    theme_pub

  # Panel B: dNBR vs metal load
  p7b <- ggplot(aviris_data %>% filter(!is.na(dNBR)),
                aes(x = dNBR, y = log10(Total_Toxics_ppm + 1))) +
    geom_point(size = 3, alpha = 0.7, color = "steelblue") +
    geom_smooth(method = "lm", se = TRUE, color = "darkblue", linewidth = 0.8) +
    labs(title = "B) Burn Severity vs Total Toxics",
         x = "dNBR (Burn Severity Index)",
         y = "log10(Total Toxics ppm)") +
    theme_pub

  # Panel C: Charash vs Zn
  p7c <- ggplot(aviris_data %>% filter(!is.na(Charash_fraction)),
                aes(x = Charash_fraction, y = log10(Zn + 1))) +
    geom_point(size = 3, alpha = 0.7, color = "forestgreen") +
    geom_smooth(method = "lm", se = TRUE, color = "darkgreen", linewidth = 0.8) +
    labs(title = "C) Charash Fraction vs Zinc",
         x = "AVIRIS Charash Fraction",
         y = "log10(Zn ppm)") +
    theme_pub

  # Panel D: Burn severity boxplot
  if ("Burn_severity" %in% names(aviris_data) && sum(!is.na(aviris_data$Burn_severity)) > 5) {
    p7d <- ggplot(aviris_data %>% filter(!is.na(Burn_severity)),
                  aes(x = Burn_severity, y = log10(Pb + 1), fill = Burn_severity)) +
      geom_boxplot(alpha = 0.7) +
      scale_fill_brewer(palette = "YlOrRd", guide = "none") +
      labs(title = "D) Lead by Burn Severity Class",
           x = "Burn Severity",
           y = "log10(Pb ppm)") +
      theme_pub +
      theme(axis.text.x = element_text(angle = 30, hjust = 1))
  } else {
    p7d <- ggplot(aviris_data, aes(x = factor(N_exceedances), y = Charash_fraction)) +
      geom_boxplot(aes(fill = factor(N_exceedances)), alpha = 0.7) +
      scale_fill_brewer(palette = "YlOrRd", guide = "none") +
      labs(title = "D) Charash by EPA Exceedance Count",
           x = "Number of EPA RSL Exceedances",
           y = "Charash Fraction") +
      theme_pub
  }

  fig7 <- (p7a | p7b) / (p7c | p7d) +
    plot_annotation(
      title = "AVIRIS Remote Sensing - Geochemistry Integration",
      subtitle = paste("Samples with AVIRIS coverage: n =", sum(!is.na(aviris_data$Charash_fraction))),
      theme = theme(plot.title = element_text(face = "bold", size = 14))
    )

  ggsave(file.path(fig_dir, "Fig7_aviris_integration.pdf"), fig7, width = 10, height = 8)
  ggsave(file.path(fig_dir, "Fig7_aviris_integration.png"), fig7, width = 10, height = 8, dpi = 300)
  cat("   Saved: Fig7_aviris_integration.pdf/png\n")
} else {
  cat("   Insufficient AVIRIS data for Figure 7\n")
}

# -----------------------------------------------------------------------------
# Figure 8: Summary Synthesis
# -----------------------------------------------------------------------------
cat("\n9. Figure 8: Multi-modal data synthesis...\n")

# Create data availability summary
data_summary <- df_ash %>%
  summarise(
    `ICP-MS` = sum(has_ICPMS, na.rm = TRUE),
    `XRF` = sum(has_XRF, na.rm = TRUE),
    `ASD` = sum(has_ASD, na.rm = TRUE),
    `FTIR` = sum(has_FTIR, na.rm = TRUE),
    `AVIRIS` = sum(!is.na(Charash_fraction))
  ) %>%
  pivot_longer(everything(), names_to = "Data_Type", values_to = "N_Samples")

p8a <- ggplot(data_summary, aes(x = reorder(Data_Type, -N_Samples), y = N_Samples, fill = Data_Type)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = N_Samples), vjust = -0.5, size = 4) +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  labs(title = "A) Data Coverage by Measurement Type",
       x = "Measurement Type", y = "Number of Samples") +
  theme_pub +
  ylim(0, max(data_summary$N_Samples) * 1.1)

# EPA exceedance summary bar
exceedance_summary <- epa_exceedance %>%
  select(Metal, Pct_exceed) %>%
  distinct(Metal, .keep_all = TRUE) %>%
  arrange(desc(Pct_exceed))

p8b <- ggplot(exceedance_summary, aes(x = reorder(Metal, -Pct_exceed), y = Pct_exceed, fill = Pct_exceed)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "red") +
  scale_fill_gradient(low = "gold", high = "firebrick", guide = "none") +
  labs(title = "B) EPA RSL Exceedance Rates",
       x = "Metal", y = "% Samples Exceeding RSL") +
  theme_pub +
  annotate("text", x = 0.7, y = 52, label = "50%", color = "red", size = 3)

fig8 <- (p8a | p8b) +
  plot_annotation(
    title = "Multi-Modal Data Integration Summary",
    subtitle = "Eaton Fire Ash Geochemical Assessment",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(fig_dir, "Fig8_synthesis_summary.pdf"), fig8, width = 11, height = 5)
ggsave(file.path(fig_dir, "Fig8_synthesis_summary.png"), fig8, width = 11, height = 5, dpi = 300)
cat("   Saved: Fig8_synthesis_summary.pdf/png\n")

# -----------------------------------------------------------------------------
# Supplementary Figure: Data Tier Distribution
# -----------------------------------------------------------------------------
cat("\n10. Supplementary figures...\n")

figS1 <- ggplot(df_ash, aes(x = factor(Data_Tier), fill = factor(Data_Tier))) +
  geom_bar(alpha = 0.8) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  scale_fill_brewer(palette = "Blues", name = "Data Tier",
                    labels = c("1" = "Complete", "2" = "ICP-MS+XRF", "3" = "ICP-MS only")) +
  labs(title = "Supplementary Figure S1: Sample Data Completeness",
       subtitle = "Tier 1 = ICP-MS + XRF + ASD + FTIR; Tier 2 = ICP-MS + XRF; Tier 3 = ICP-MS only",
       x = "Data Tier", y = "Number of Samples") +
  theme_pub

ggsave(file.path(fig_dir, "FigS1_data_tiers.pdf"), figS1, width = 8, height = 5)
ggsave(file.path(fig_dir, "FigS1_data_tiers.png"), figS1, width = 8, height = 5, dpi = 300)
cat("   Saved: FigS1_data_tiers.pdf/png\n")

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
cat("\n", rep("=", 60), "\n", sep = "")
cat("PUBLICATION FIGURES COMPLETE\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Generated figures:\n")
cat("   - Fig1_study_area.pdf/png\n")
cat("   - Fig2_metal_concentrations.pdf/png\n")
cat("   - Fig3_spatial_distribution.pdf/png\n")
cat("   - Fig4_correlation_heatmap.pdf/png\n")
cat("   - Fig5_spectral_prediction.pdf/png (from PSQ-2)\n")
cat("   - Fig6_mineral_metal_relationships.pdf/png (from PSQ-3)\n")
cat("   - Fig7_aviris_integration.pdf/png\n")
cat("   - Fig8_synthesis_summary.pdf/png\n")
cat("   - FigS1_data_tiers.pdf/png\n")

cat("\nFigure recommendations for manuscript:\n")
cat("   Main text: Figures 1-6, 8\n")
cat("   Supplementary: Figure 7, S1\n")

cat("\n=== Publication Figure Generation Complete ===\n")
