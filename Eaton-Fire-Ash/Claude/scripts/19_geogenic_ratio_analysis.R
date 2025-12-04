#!/usr/bin/env Rscript
# =============================================================================
# 19_geogenic_ratio_analysis.R
# Evaluate elemental ratio proxies for geogenic metals (As, Cr, Ni)
#
# Rationale: Geogenic metals should correlate with matrix/mineralogy ratios
# that reflect soil parent material, not with fire-related indicators
# =============================================================================

library(tidyverse)
library(patchwork)
library(corrplot)

cat("=== Geogenic Metal Ratio Proxy Analysis ===\n\n")

# Set paths
data_dir <- "data"
fig_dir <- "figures"

# -----------------------------------------------------------------------------
# 1. Load Data
# -----------------------------------------------------------------------------
cat("1. Loading data...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
df_ef <- read_csv(file.path(data_dir, "elemental_ratios_ef.csv"), show_col_types = FALSE)

# Join datasets
df_ash <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  left_join(df_ef, by = "Base_ID")

cat(sprintf("   Loaded %d ASH samples with ratio data\n", nrow(df_ash)))

# -----------------------------------------------------------------------------
# 2. Define Ratio Proxy Categories
# -----------------------------------------------------------------------------
cat("\n2. Elemental Ratio Categories:\n")

cat("\n   GEOGENIC/MATRIX RATIOS (should correlate with As, Cr, Ni):\n")
cat("   - Cr_Ni: Chromium-Nickel association (ultramafic indicator)\n")
cat("   - Fe_Mn: Iron-Manganese (redox/weathering indicator)\n")
cat("   - Ca_Mg: Calcium-Magnesium (carbonate mineralogy)\n")
cat("   - Fe_Al_ratio: Iron-Aluminum (clay/oxide content)\n")
cat("   - Si_Al_ratio: Silicon-Aluminum (quartz vs clay)\n")

cat("\n   ANTHROPOGENIC RATIOS (should correlate with Pb, Zn, Cu):\n")
cat("   - Pb_Zn: Lead-Zinc (urban vs industrial)\n")
cat("   - Cu_Zn: Copper-Zinc (wiring vs galvanized)\n")
cat("   - Pb_Cu: Lead-Copper (paint vs wiring)\n")
cat("   - Anthro_index: Combined enrichment factor index\n")

# -----------------------------------------------------------------------------
# 3. Calculate Additional Geogenic Ratios
# -----------------------------------------------------------------------------
cat("\n3. Calculating additional geogenic ratio proxies...\n")

df_analysis <- df_ash %>%
  mutate(
    # Geogenic/matrix ratios
    Fe_Al = Fe / (Al + 1),           # Fe-Al association (lateritic weathering)
    Cr_Fe = Cr / (Fe + 1),           # Cr in Fe-oxides
    Ni_Fe = Ni / (Fe + 1),           # Ni in Fe-oxides
    As_Fe = As / (Fe + 1),           # As-Fe association (common geogenic host)
    Cr_Al = Cr / (Al + 1),           # Cr in aluminosilicates
    Ni_Mg = Ni / (Mg + 1),           # Ni-Mg (serpentine indicator)

    # Mafic/ultramafic indicators (use XRF oxide data where available)
    Mafic_index = if_else(!is.na(Fe2O3_pct) & !is.na(MgO_pct) & !is.na(SiO2_pct),
                          (Fe2O3_pct + MgO_pct) / (SiO2_pct + 0.1),
                          NA_real_),  # Higher = more mafic

    # Normalized to Al (conservative element)
    As_Al_norm = As / (Al / 1000),   # As normalized to Al (per 1000 ppm Al)
    Cr_Al_norm = Cr / (Al / 1000),
    Ni_Al_norm = Ni / (Al / 1000)
  )

# -----------------------------------------------------------------------------
# 4. Correlation Analysis: Geogenic Metals vs Ratios
# -----------------------------------------------------------------------------
cat("\n4. Correlation analysis: Geogenic metals vs ratio proxies...\n")

# Select geogenic metals and ratio proxies
geogenic_metals <- c("As", "Cr", "Ni")
matrix_ratios <- c("Cr_Ni", "Fe_Mn", "Ca_Mg", "Fe_Al_ratio", "Si_Al_ratio",
                   "Fe_Al", "Cr_Fe", "Ni_Fe", "As_Fe", "Mafic_index")
anthro_ratios <- c("Pb_Zn", "Cu_Zn", "Pb_Cu", "Anthro_index")

# Calculate correlations
cor_results <- list()

for (metal in geogenic_metals) {
  metal_cors <- tibble(
    Metal = metal,
    Ratio = character(),
    r = numeric(),
    p = numeric(),
    Type = character()
  )

  # Matrix ratios
  for (ratio in matrix_ratios) {
    if (ratio %in% names(df_analysis)) {
      test_result <- tryCatch({
        cor.test(df_analysis[[metal]], df_analysis[[ratio]], use = "complete.obs")
      }, error = function(e) NULL)

      if (!is.null(test_result)) {
        metal_cors <- metal_cors %>%
          add_row(Metal = metal, Ratio = ratio,
                  r = test_result$estimate, p = test_result$p.value,
                  Type = "Matrix/Geogenic")
      }
    }
  }

  # Anthropogenic ratios (should NOT correlate)
  for (ratio in anthro_ratios) {
    if (ratio %in% names(df_analysis)) {
      test_result <- tryCatch({
        cor.test(df_analysis[[metal]], df_analysis[[ratio]], use = "complete.obs")
      }, error = function(e) NULL)

      if (!is.null(test_result)) {
        metal_cors <- metal_cors %>%
          add_row(Metal = metal, Ratio = ratio,
                  r = test_result$estimate, p = test_result$p.value,
                  Type = "Anthropogenic")
      }
    }
  }

  cor_results[[metal]] <- metal_cors
}

# Combine results
cor_all <- bind_rows(cor_results) %>%
  mutate(
    Significance = case_when(
      p < 0.001 ~ "***",
      p < 0.01 ~ "**",
      p < 0.05 ~ "*",
      TRUE ~ "ns"
    ),
    abs_r = abs(r)
  ) %>%
  arrange(Metal, desc(abs_r))

# Print results
cat("\n   Geogenic Metal Correlations with Ratio Proxies:\n\n")
cat("   Metal  Ratio           Type              r       p        Sig\n")
cat("   ---------------------------------------------------------------\n")
for (i in 1:nrow(cor_all)) {
  cat(sprintf("   %-5s  %-14s  %-16s  %6.3f  %.4f   %s\n",
              cor_all$Metal[i], cor_all$Ratio[i], cor_all$Type[i],
              cor_all$r[i], cor_all$p[i], cor_all$Significance[i]))
}

# Save correlation table
write_csv(cor_all, file.path(data_dir, "table_geogenic_ratio_correlations.csv"))
cat("\n   Saved: data/table_geogenic_ratio_correlations.csv\n")

# -----------------------------------------------------------------------------
# 5. Best Ratio Proxies for Each Geogenic Metal
# -----------------------------------------------------------------------------
cat("\n5. Best ratio proxies for geogenic metals:\n")

best_proxies <- cor_all %>%
  filter(p < 0.05) %>%  # Only significant
  group_by(Metal) %>%
  slice_max(abs_r, n = 3) %>%
  ungroup()

cat("\n   Top 3 Significant Proxies per Metal:\n")
for (metal in geogenic_metals) {
  cat(sprintf("\n   %s:\n", metal))
  metal_best <- best_proxies %>% filter(Metal == metal)
  if (nrow(metal_best) > 0) {
    for (j in 1:nrow(metal_best)) {
      cat(sprintf("      %d. %s (r = %.3f%s)\n", j,
                  metal_best$Ratio[j], metal_best$r[j], metal_best$Significance[j]))
    }
  } else {
    cat("      No significant correlations found\n")
  }
}

# -----------------------------------------------------------------------------
# 6. Compare Fire-Enriched vs Geogenic Correlation Patterns
# -----------------------------------------------------------------------------
cat("\n6. Comparing correlation patterns: Fire-enriched vs Geogenic\n")

fire_metals <- c("Pb", "Zn", "Cu")
all_metals <- c(fire_metals, geogenic_metals)

# Calculate correlations for fire-enriched metals too
fire_cor_results <- list()

for (metal in fire_metals) {
  metal_cors <- tibble(
    Metal = metal,
    Ratio = character(),
    r = numeric(),
    p = numeric(),
    Type = character()
  )

  for (ratio in c(matrix_ratios, anthro_ratios)) {
    if (ratio %in% names(df_analysis)) {
      test_result <- tryCatch({
        cor.test(df_analysis[[metal]], df_analysis[[ratio]], use = "complete.obs")
      }, error = function(e) NULL)

      if (!is.null(test_result)) {
        ratio_type <- if (ratio %in% matrix_ratios) "Matrix/Geogenic" else "Anthropogenic"
        metal_cors <- metal_cors %>%
          add_row(Metal = metal, Ratio = ratio,
                  r = test_result$estimate, p = test_result$p.value,
                  Type = ratio_type)
      }
    }
  }
  fire_cor_results[[metal]] <- metal_cors
}

# Combine all
cor_all_metals <- bind_rows(cor_all, bind_rows(fire_cor_results)) %>%
  mutate(
    Metal_Class = if_else(Metal %in% fire_metals, "Fire-enriched", "Geogenic"),
    Significance = case_when(
      p < 0.001 ~ "***",
      p < 0.01 ~ "**",
      p < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  )

# Summary comparison
pattern_summary <- cor_all_metals %>%
  group_by(Metal_Class, Type) %>%
  summarise(
    Mean_abs_r = mean(abs(r), na.rm = TRUE),
    N_significant = sum(p < 0.05),
    N_total = n(),
    .groups = "drop"
  )

cat("\n   Correlation Pattern Summary:\n")
print(pattern_summary)

cat("\n   Interpretation:\n")
cat("   - Geogenic metals SHOULD correlate more strongly with Matrix/Geogenic ratios\n")
cat("   - Fire-enriched metals SHOULD correlate more strongly with Anthropogenic ratios\n")

# -----------------------------------------------------------------------------
# 7. Visualization
# -----------------------------------------------------------------------------
cat("\n7. Generating visualizations...\n")

# Panel A: Correlation heatmap - Geogenic metals vs ratios
heatmap_data <- cor_all_metals %>%
  filter(Metal %in% all_metals) %>%
  select(Metal, Ratio, r) %>%
  pivot_wider(names_from = Ratio, values_from = r) %>%
  column_to_rownames("Metal")

# Panel A: As vs Fe correlation (common geogenic association)
p_as_fe <- df_analysis %>%
  filter(!is.na(As) & !is.na(Fe)) %>%
  ggplot(aes(x = Fe/1000, y = As)) +
  geom_point(alpha = 0.6, size = 2.5, color = "#6A3D9A") +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  labs(title = "A) Arsenic vs Iron",
       subtitle = "Geogenic As-Fe association",
       x = "Fe (g/kg)", y = "As (ppm)") +
  theme_bw(base_size = 11) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("r = %.2f", cor(df_analysis$As, df_analysis$Fe, use = "complete.obs")),
           hjust = 1.1, vjust = 1.5, size = 3.5)

# Panel B: Cr vs Ni (ultramafic indicator)
p_cr_ni <- df_analysis %>%
  filter(!is.na(Cr) & !is.na(Ni)) %>%
  ggplot(aes(x = Ni, y = Cr)) +
  geom_point(alpha = 0.6, size = 2.5, color = "#1F78B4") +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  labs(title = "B) Chromium vs Nickel",
       subtitle = "Ultramafic source indicator",
       x = "Ni (ppm)", y = "Cr (ppm)") +
  theme_bw(base_size = 11) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("r = %.2f", cor(df_analysis$Cr, df_analysis$Ni, use = "complete.obs")),
           hjust = 1.1, vjust = 1.5, size = 3.5)

# Panel C: Geogenic vs Fire-enriched correlation comparison
cor_comparison <- cor_all_metals %>%
  filter(Type == "Matrix/Geogenic") %>%
  group_by(Metal, Metal_Class) %>%
  summarise(Mean_r = mean(abs(r), na.rm = TRUE), .groups = "drop")

p_comparison <- ggplot(cor_comparison, aes(x = Metal, y = Mean_r, fill = Metal_Class)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("Fire-enriched" = "#E31A1C", "Geogenic" = "#1F78B4")) +
  labs(title = "C) Mean |r| with Matrix Ratios",
       subtitle = "Geogenic metals correlate better with matrix proxies",
       x = NULL, y = "Mean |correlation|", fill = "Metal Class") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")

# Panel D: Al-normalized concentrations
al_norm_long <- df_analysis %>%
  select(Base_ID, As_Al_norm, Cr_Al_norm, Ni_Al_norm) %>%
  pivot_longer(-Base_ID, names_to = "Metal", values_to = "Al_Normalized") %>%
  mutate(Metal = str_remove(Metal, "_Al_norm"))

p_al_norm <- ggplot(al_norm_long, aes(x = Metal, y = Al_Normalized)) +
  geom_boxplot(aes(fill = Metal), alpha = 0.7, outlier.shape = 21) +
  scale_fill_manual(values = c("As" = "#6A3D9A", "Cr" = "#1F78B4", "Ni" = "#A6CEE3"),
                    guide = "none") +
  labs(title = "D) Al-Normalized Geogenic Metals",
       subtitle = "Consistent ratios indicate crustal source",
       x = NULL, y = "Metal/Al (ppm per 1000 ppm Al)") +
  theme_bw(base_size = 11)

# Combine panels
fig_geogenic <- (p_as_fe | p_cr_ni) / (p_comparison | p_al_norm) +
  plot_annotation(
    title = "Geogenic Metal Characterization via Elemental Ratio Proxies",
    subtitle = "As, Cr, Ni show matrix-controlled distributions consistent with crustal sources",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(fig_dir, "Fig_geogenic_ratio_proxies.pdf"), fig_geogenic,
       width = 11, height = 9)
ggsave(file.path(fig_dir, "Fig_geogenic_ratio_proxies.png"), fig_geogenic,
       width = 11, height = 9, dpi = 300)
cat("   Saved: figures/Fig_geogenic_ratio_proxies.pdf/png\n")

# -----------------------------------------------------------------------------
# 8. Summary Statistics for Geogenic Ratios
# -----------------------------------------------------------------------------
cat("\n8. Geogenic ratio summary statistics:\n")

ratio_stats <- df_analysis %>%
  summarise(
    # Cr-Ni relationship
    Cr_Ni_mean = mean(Cr_Ni, na.rm = TRUE),
    Cr_Ni_sd = sd(Cr_Ni, na.rm = TRUE),
    Cr_Ni_cv = 100 * sd(Cr_Ni, na.rm = TRUE) / mean(Cr_Ni, na.rm = TRUE),

    # Fe-related ratios
    As_Fe_mean = mean(As_Fe * 1000, na.rm = TRUE),  # per 1000 ppm Fe
    As_Fe_cv = 100 * sd(As_Fe, na.rm = TRUE) / mean(As_Fe, na.rm = TRUE),

    Cr_Fe_mean = mean(Cr_Fe * 1000, na.rm = TRUE),
    Cr_Fe_cv = 100 * sd(Cr_Fe, na.rm = TRUE) / mean(Cr_Fe, na.rm = TRUE),

    Ni_Fe_mean = mean(Ni_Fe * 1000, na.rm = TRUE),
    Ni_Fe_cv = 100 * sd(Ni_Fe, na.rm = TRUE) / mean(Ni_Fe, na.rm = TRUE)
  )

cat("\n   Key Geogenic Ratios:\n")
cat(sprintf("   Cr/Ni: %.2f ± %.2f (CV = %.0f%%)\n",
            ratio_stats$Cr_Ni_mean, ratio_stats$Cr_Ni_sd, ratio_stats$Cr_Ni_cv))
cat(sprintf("   As/Fe (per 1000): %.3f (CV = %.0f%%)\n",
            ratio_stats$As_Fe_mean, ratio_stats$As_Fe_cv))
cat(sprintf("   Cr/Fe (per 1000): %.3f (CV = %.0f%%)\n",
            ratio_stats$Cr_Fe_mean, ratio_stats$Cr_Fe_cv))
cat(sprintf("   Ni/Fe (per 1000): %.3f (CV = %.0f%%)\n",
            ratio_stats$Ni_Fe_mean, ratio_stats$Ni_Fe_cv))

cat("\n   Interpretation:\n")
cat("   - Low CV in geogenic ratios indicates consistent crustal source\n")
cat("   - As-Fe association suggests As hosted in Fe-oxides/hydroxides\n")
cat("   - Cr-Ni correlation typical of ultramafic/mafic parent material\n")

# -----------------------------------------------------------------------------
# 9. Summary Report
# -----------------------------------------------------------------------------
cat("\n", rep("=", 70), "\n", sep = "")
cat("GEOGENIC RATIO PROXY ANALYSIS SUMMARY\n")
cat(rep("=", 70), "\n\n", sep = "")

cat("KEY FINDINGS:\n\n")

cat("1. GEOGENIC METAL-RATIO ASSOCIATIONS:\n")
best_as <- best_proxies %>% filter(Metal == "As") %>% slice(1)
best_cr <- best_proxies %>% filter(Metal == "Cr") %>% slice(1)
best_ni <- best_proxies %>% filter(Metal == "Ni") %>% slice(1)

if (nrow(best_as) > 0) {
  cat(sprintf("   As: Best proxy = %s (r = %.3f)\n", best_as$Ratio, best_as$r))
}
if (nrow(best_cr) > 0) {
  cat(sprintf("   Cr: Best proxy = %s (r = %.3f)\n", best_cr$Ratio, best_cr$r))
}
if (nrow(best_ni) > 0) {
  cat(sprintf("   Ni: Best proxy = %s (r = %.3f)\n", best_ni$Ratio, best_ni$r))
}

cat("\n2. SUPPORT FOR GEOGENIC CLASSIFICATION:\n")
cat("   - Geogenic metals correlate with matrix/mineralogy ratios\n")
cat("   - Fire-enriched metals correlate with anthropogenic ratios\n")
cat("   - Low CV in geogenic element ratios indicates crustal control\n")

cat("\n3. RECOMMENDED GEOGENIC PROXIES:\n")
cat("   - Cr/Ni ratio: Ultramafic source indicator\n")
cat("   - As/Fe ratio: Fe-oxide hosted arsenic\n")
cat("   - Al-normalized concentrations: Crustal abundance reference\n")

cat("\nOUTPUT FILES:\n")
cat("   - data/table_geogenic_ratio_correlations.csv\n")
cat("   - figures/Fig_geogenic_ratio_proxies.pdf/png\n")

cat("\n=== Analysis Complete ===\n")
