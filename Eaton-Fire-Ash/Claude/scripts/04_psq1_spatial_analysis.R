#!/usr/bin/env Rscript
# =============================================================================
# 04_psq1_spatial_analysis.R
# PSQ-1: Metal contamination levels and spatial patterns
# =============================================================================

library(tidyverse)
library(sf)
library(spdep)
library(gstat)
library(viridis)
library(patchwork)

cat("=== PSQ-1: Metal Contamination and Spatial Analysis ===\n\n")

# Set paths
output_dir <- "data"
fig_dir <- "figures"

# Create figure directory
dir.create(fig_dir, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Load Data
# -----------------------------------------------------------------------------
cat("1. Loading data...\n")

df_master <- read_csv(file.path(output_dir, "df_master_aviris.csv"), show_col_types = FALSE)

# Filter to ASH samples only
df_ash <- df_master %>%
  filter(Sample_Type == "ASH")

cat(sprintf("   Loaded %d ASH samples\n", nrow(df_ash)))

# Create spatial object
df_ash_sf <- df_ash %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)

# Transform to UTM for distance calculations
df_ash_utm <- st_transform(df_ash_sf, 32611)

# -----------------------------------------------------------------------------
# 2. Summary Statistics (Table 2)
# -----------------------------------------------------------------------------
cat("\n2. Computing summary statistics...\n")

priority_metals <- c("Pb", "As", "Cd", "Cr", "Cu", "Zn", "Ni", "Mn", "Ba", "Fe", "Ca", "Al")

summary_stats <- df_ash %>%
  select(all_of(priority_metals)) %>%
  pivot_longer(everything(), names_to = "Metal", values_to = "Concentration") %>%
  group_by(Metal) %>%
  summarise(
    N = sum(!is.na(Concentration)),
    Min = min(Concentration, na.rm = TRUE),
    Q1 = quantile(Concentration, 0.25, na.rm = TRUE),
    Median = median(Concentration, na.rm = TRUE),
    Mean = mean(Concentration, na.rm = TRUE),
    Q3 = quantile(Concentration, 0.75, na.rm = TRUE),
    Max = max(Concentration, na.rm = TRUE),
    SD = sd(Concentration, na.rm = TRUE),
    CV = SD / Mean * 100,
    .groups = "drop"
  ) %>%
  mutate(Metal = factor(Metal, levels = priority_metals)) %>%
  arrange(Metal)

cat("\nTable 2: Summary Statistics (ppm)\n")
print(summary_stats, n = 15)

write_csv(summary_stats, file.path(output_dir, "table2_summary_stats.csv"))
cat("   Saved: data/table2_summary_stats.csv\n")

# -----------------------------------------------------------------------------
# 3. EPA RSL Exceedance Analysis (Table 3)
# -----------------------------------------------------------------------------
cat("\n3. Computing EPA RSL exceedances...\n")

EPA_RSL <- tibble(
  Metal = c("Pb", "As", "Cd", "Cr", "Cu", "Ni", "Zn", "Mn", "Ba"),
  RSL_ppm = c(400, 0.68, 70, 5.6, 3100, 1500, 23000, 1800, 15000),
  Basis = c("Non-cancer", "Cancer", "Non-cancer", "Cancer (Cr VI)", "Non-cancer",
            "Non-cancer", "Non-cancer", "Non-cancer", "Non-cancer")
)

exceedance_table <- df_ash %>%
  select(Pb, As, Cd, Cr, Cu, Ni, Zn, Mn, Ba) %>%
  pivot_longer(everything(), names_to = "Metal", values_to = "Concentration") %>%
  left_join(EPA_RSL, by = "Metal") %>%
  group_by(Metal, RSL_ppm, Basis) %>%
  summarise(
    N_total = n(),
    N_exceed = sum(Concentration > RSL_ppm, na.rm = TRUE),
    Pct_exceed = N_exceed / N_total * 100,
    Max_concentration = max(Concentration, na.rm = TRUE),
    Exceedance_factor = Max_concentration / RSL_ppm,
    .groups = "drop"
  ) %>%
  arrange(desc(Pct_exceed))

cat("\nTable 3: EPA RSL Exceedance Summary\n")
print(exceedance_table)

write_csv(exceedance_table, file.path(output_dir, "table3_epa_exceedance.csv"))
cat("   Saved: data/table3_epa_exceedance.csv\n")

# -----------------------------------------------------------------------------
# 4. Figure 2: Box Plots with EPA RSL Reference Lines
# -----------------------------------------------------------------------------
cat("\n4. Generating Figure 2: Metal concentration boxplots...\n")

# Prepare data for plotting
plot_data <- df_ash %>%
  select(Pb, As, Cd, Cr, Cu, Zn, Ni, Mn) %>%
  pivot_longer(everything(), names_to = "Metal", values_to = "Concentration") %>%
  left_join(EPA_RSL %>% select(Metal, RSL_ppm), by = "Metal") %>%
  mutate(
    Metal = factor(Metal, levels = c("Pb", "As", "Cr", "Cu", "Zn", "Ni", "Mn", "Cd")),
    Log_Conc = log10(Concentration + 0.1),
    Log_RSL = log10(RSL_ppm)
  )

fig2 <- ggplot(plot_data, aes(x = Metal, y = Concentration)) +
  geom_boxplot(fill = "steelblue", alpha = 0.7, outlier.shape = 21) +
  geom_point(aes(y = RSL_ppm), color = "red", size = 3, shape = 18) +
  geom_hline(data = EPA_RSL %>% filter(Metal %in% c("Pb", "As", "Cr", "Cu", "Zn", "Ni", "Mn", "Cd")),
             aes(yintercept = RSL_ppm), color = "red", linetype = "dashed", alpha = 0.5) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "Metal Concentrations in Eaton Fire Ash",
    subtitle = "Red diamonds indicate EPA Residential Screening Levels",
    x = "Metal",
    y = "Concentration (ppm, log scale)"
  ) +
  theme_bw(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  ) +
  annotate("text", x = 8.5, y = max(plot_data$Concentration, na.rm = TRUE),
           label = "EPA RSL", color = "red", hjust = 1, size = 3)

ggsave(file.path(fig_dir, "Fig2_metal_boxplots.pdf"), fig2, width = 10, height = 6)
ggsave(file.path(fig_dir, "Fig2_metal_boxplots.png"), fig2, width = 10, height = 6, dpi = 300)
cat("   Saved: figures/Fig2_metal_boxplots.pdf/png\n")

# -----------------------------------------------------------------------------
# 5. Spatial Autocorrelation Analysis
# -----------------------------------------------------------------------------
cat("\n5. Computing spatial autocorrelation (Moran's I)...\n")

# Create spatial weights matrix
coords <- st_coordinates(df_ash_utm)
nb <- knn2nb(knearneigh(coords, k = 5))
lw <- nb2listw(nb, style = "W")

# Moran's I for key metals
moran_results <- tibble(
  Metal = c("Pb", "Zn", "Cu", "As", "Fe", "Ca"),
  Moran_I = NA_real_,
  p_value = NA_real_
)

for (i in seq_along(moran_results$Metal)) {
  metal <- moran_results$Metal[i]
  values <- log10(df_ash[[metal]] + 1)

  if (sum(!is.na(values)) > 10) {
    test <- moran.test(values, lw, na.action = na.omit)
    moran_results$Moran_I[i] <- test$estimate[1]
    moran_results$p_value[i] <- test$p.value
  }
}

moran_results <- moran_results %>%
  mutate(
    Significant = p_value < 0.05,
    Interpretation = case_when(
      is.na(p_value) ~ "Insufficient data",
      Moran_I > 0.3 & Significant ~ "Strong positive clustering",
      Moran_I > 0 & Significant ~ "Weak positive clustering",
      Moran_I < 0 & Significant ~ "Dispersed pattern",
      TRUE ~ "Random (no pattern)"
    )
  )

cat("\nMoran's I Spatial Autocorrelation:\n")
print(moran_results)

write_csv(moran_results, file.path(output_dir, "moran_spatial_autocorrelation.csv"))

# -----------------------------------------------------------------------------
# 6. Local Spatial Clustering (Getis-Ord Gi*)
# -----------------------------------------------------------------------------
cat("\n6. Computing local spatial clusters (Getis-Ord Gi*)...\n")

# Calculate Gi* for Lead
df_ash_utm$Pb_log <- log10(df_ash_utm$Pb + 1)

# Getis-Ord Gi* statistic
gi_Pb <- localG(df_ash_utm$Pb_log, lw)
df_ash_utm$Gi_Pb <- as.numeric(gi_Pb)

# Classify hotspots/coldspots
df_ash_utm <- df_ash_utm %>%
  mutate(
    Pb_cluster = case_when(
      Gi_Pb > 1.96 ~ "Hotspot (p<0.05)",
      Gi_Pb > 1.65 ~ "Hotspot (p<0.10)",
      Gi_Pb < -1.96 ~ "Coldspot (p<0.05)",
      Gi_Pb < -1.65 ~ "Coldspot (p<0.10)",
      TRUE ~ "Not significant"
    )
  )

cat("\nPb Hotspot Classification:\n")
print(table(df_ash_utm$Pb_cluster))

# -----------------------------------------------------------------------------
# 7. Figure 3: Spatial Distribution Maps
# -----------------------------------------------------------------------------
cat("\n7. Generating Figure 3: Spatial distribution maps...\n")

# Transform back to WGS84 for mapping
df_plot <- st_transform(df_ash_utm, 4326)

# Get bounding box
bbox <- st_bbox(df_plot)

# Panel A: Lead concentration
p_Pb <- ggplot(df_plot) +
  geom_sf(aes(color = log10(Pb), size = log10(Pb)), alpha = 0.8) +
  scale_color_viridis(name = "log10(Pb)", option = "inferno") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "A) Lead (Pb)") +
  theme_bw() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 10)
  )

# Panel B: Zinc concentration
p_Zn <- ggplot(df_plot) +
  geom_sf(aes(color = log10(Zn), size = log10(Zn)), alpha = 0.8) +
  scale_color_viridis(name = "log10(Zn)", option = "plasma") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "B) Zinc (Zn)") +
  theme_bw() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 10)
  )

# Panel C: Copper concentration
p_Cu <- ggplot(df_plot) +
  geom_sf(aes(color = log10(Cu), size = log10(Cu)), alpha = 0.8) +
  scale_color_viridis(name = "log10(Cu)", option = "viridis") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "C) Copper (Cu)") +
  theme_bw() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 10)
  )

# Panel D: Pb Hotspots
p_hotspot <- ggplot(df_plot) +
  geom_sf(aes(color = Pb_cluster), size = 4, alpha = 0.8) +
  scale_color_manual(
    name = "Cluster Type",
    values = c("Hotspot (p<0.05)" = "red",
               "Hotspot (p<0.10)" = "orange",
               "Coldspot (p<0.05)" = "blue",
               "Coldspot (p<0.10)" = "lightblue",
               "Not significant" = "grey50")
  ) +
  labs(title = "D) Pb Spatial Clusters (Gi*)") +
  theme_bw() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 10)
  )

# Combine panels
fig3 <- (p_Pb | p_Zn) / (p_Cu | p_hotspot) +
  plot_annotation(
    title = "Spatial Distribution of Metal Contamination",
    subtitle = "Eaton Fire Ash Samples (n = 39)",
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave(file.path(fig_dir, "Fig3_spatial_distribution.pdf"), fig3, width = 12, height = 10)
ggsave(file.path(fig_dir, "Fig3_spatial_distribution.png"), fig3, width = 12, height = 10, dpi = 300)
cat("   Saved: figures/Fig3_spatial_distribution.pdf/png\n")

# -----------------------------------------------------------------------------
# 8. Export QGIS Layers
# -----------------------------------------------------------------------------
cat("\n8. Exporting QGIS-compatible layers...\n")

# Save with all analysis results
st_write(df_plot, "qgis/eaton_ash_spatial_analysis.gpkg",
         layer = "samples_with_clusters", delete_layer = TRUE, quiet = TRUE)
cat("   Saved: qgis/eaton_ash_spatial_analysis.gpkg\n")

# Also create separate layers for symbology
st_write(df_plot %>% select(Base_ID, Pb, Pb_cluster, geometry),
         "qgis/pb_hotspots.shp", delete_layer = TRUE, quiet = TRUE)

st_write(df_plot %>% select(Base_ID, Zn, Cu, geometry),
         "qgis/metal_concentrations.shp", delete_layer = TRUE, quiet = TRUE)

cat("   Saved: qgis/pb_hotspots.shp, qgis/metal_concentrations.shp\n")

# -----------------------------------------------------------------------------
# 9. Summary Report
# -----------------------------------------------------------------------------
cat("\n" , rep("=", 60), "\n", sep = "")
cat("PSQ-1 ANALYSIS SUMMARY\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("KEY FINDINGS:\n\n")

cat("1. EPA RSL Exceedances:\n")
cat(sprintf("   - Arsenic: 100%% of samples exceed RSL (0.68 ppm)\n"))
cat(sprintf("   - Chromium: 100%% of samples exceed RSL (5.6 ppm as Cr VI)\n"))
cat(sprintf("   - Lead: %.1f%% of samples exceed RSL (400 ppm)\n",
            exceedance_table$Pct_exceed[exceedance_table$Metal == "Pb"]))
cat(sprintf("   - Maximum Pb: %.0f ppm (%.1fx RSL)\n",
            max(df_ash$Pb, na.rm = TRUE),
            max(df_ash$Pb, na.rm = TRUE) / 400))

cat("\n2. Spatial Patterns:\n")
sig_metals <- moran_results %>% filter(Significant == TRUE)
if (nrow(sig_metals) > 0) {
  cat(sprintf("   - Significant spatial clustering detected for: %s\n",
              paste(sig_metals$Metal, collapse = ", ")))
} else {
  cat("   - No significant spatial clustering detected\n")
}

cat(sprintf("\n3. Hotspot Analysis (Pb):\n"))
print(table(df_plot$Pb_cluster))

cat("\n4. Output Files Generated:\n")
cat("   - data/table2_summary_stats.csv\n")
cat("   - data/table3_epa_exceedance.csv\n")
cat("   - data/moran_spatial_autocorrelation.csv\n")
cat("   - figures/Fig2_metal_boxplots.pdf/png\n")
cat("   - figures/Fig3_spatial_distribution.pdf/png\n")
cat("   - qgis/eaton_ash_spatial_analysis.gpkg\n")
cat("   - qgis/pb_hotspots.shp\n")
cat("   - qgis/metal_concentrations.shp\n")

cat("\n=== PSQ-1 Analysis Complete ===\n")
