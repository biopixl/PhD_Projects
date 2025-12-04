#!/usr/bin/env Rscript
# =============================================================================
# 09_elemental_ratios_enrichment.R
# Calculate enrichment factors and diagnostic elemental ratios
# For XRF data calibration validation and source apportionment
# =============================================================================

library(tidyverse)

cat("=== Elemental Ratios and Enrichment Factor Analysis ===\n\n")

# Set paths
data_dir <- "data"
fig_dir <- "figures"

# -----------------------------------------------------------------------------
# 1. Load Data
# -----------------------------------------------------------------------------
cat("1. Loading data...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
df_ash <- df_master %>% filter(Sample_Type == "ASH")

cat(sprintf("   Loaded %d ASH samples\n", nrow(df_ash)))

# -----------------------------------------------------------------------------
# 2. Define Geochemical Background Values
# -----------------------------------------------------------------------------
cat("\n2. Defining geochemical background reference values...\n")

# Upper Continental Crust (UCC) values from Taylor & McLennan (1995), Rudnick & Gao (2003)
# Used for enrichment factor calculations
UCC <- tibble(
  Element = c("Pb", "Zn", "Cu", "As", "Cr", "Ni", "Cd", "Fe", "Al", "Mn", "Ba", "Ca", "Ti", "V"),
  UCC_ppm = c(17, 67, 28, 4.8, 92, 47, 0.09, 39200, 81500, 774, 624, 25300, 3840, 97)
)

# California soil background (approximate from USGS studies)
CA_background <- tibble(
  Element = c("Pb", "Zn", "Cu", "As", "Cr", "Ni"),
  CA_bg_ppm = c(22, 75, 35, 6.5, 85, 40)
)

cat("   Reference values:\n")
cat("   - Upper Continental Crust (UCC): Taylor & McLennan 1995\n")
cat("   - California soil background: USGS regional estimates\n")

# -----------------------------------------------------------------------------
# 3. Calculate Enrichment Factors (EF)
# -----------------------------------------------------------------------------
cat("\n3. Calculating enrichment factors normalized to Al...\n")

# EF = (X/Al)_sample / (X/Al)_reference
# Using Al as normalizing element (conservative, low anthropogenic input)

Al_UCC <- UCC$UCC_ppm[UCC$Element == "Al"]  # 81500 ppm

df_ef <- df_ash %>%
  mutate(
    # Enrichment factors relative to UCC, normalized to Al
    EF_Pb = (Pb / Al) / (UCC$UCC_ppm[UCC$Element == "Pb"] / Al_UCC),
    EF_Zn = (Zn / Al) / (UCC$UCC_ppm[UCC$Element == "Zn"] / Al_UCC),
    EF_Cu = (Cu / Al) / (UCC$UCC_ppm[UCC$Element == "Cu"] / Al_UCC),
    EF_As = (As / Al) / (UCC$UCC_ppm[UCC$Element == "As"] / Al_UCC),
    EF_Cr = (Cr / Al) / (UCC$UCC_ppm[UCC$Element == "Cr"] / Al_UCC),
    EF_Ni = (Ni / Al) / (UCC$UCC_ppm[UCC$Element == "Ni"] / Al_UCC),
    EF_Mn = (Mn / Al) / (UCC$UCC_ppm[UCC$Element == "Mn"] / Al_UCC),
    EF_Ba = (Ba / Al) / (UCC$UCC_ppm[UCC$Element == "Ba"] / Al_UCC),

    # Enrichment classification (Sutherland 2000)
    # EF < 2: deficiency to minimal enrichment
    # 2-5: moderate enrichment
    # 5-20: significant enrichment
    # 20-40: very high enrichment
    # > 40: extremely high enrichment

    Pb_enrich_class = case_when(
      EF_Pb < 2 ~ "Minimal",
      EF_Pb < 5 ~ "Moderate",
      EF_Pb < 20 ~ "Significant",
      EF_Pb < 40 ~ "Very High",
      TRUE ~ "Extreme"
    ),
    Zn_enrich_class = case_when(
      EF_Zn < 2 ~ "Minimal",
      EF_Zn < 5 ~ "Moderate",
      EF_Zn < 20 ~ "Significant",
      EF_Zn < 40 ~ "Very High",
      TRUE ~ "Extreme"
    )
  )

# Summary statistics for enrichment factors
ef_summary <- df_ef %>%
  summarise(
    across(starts_with("EF_"),
           list(mean = ~mean(., na.rm = TRUE),
                median = ~median(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  ) %>%
  pivot_longer(everything(), names_to = "Metric", values_to = "Value") %>%
  separate(Metric, into = c("EF", "Element", "Stat"), sep = "_") %>%
  unite("Element", EF, Element) %>%
  pivot_wider(names_from = Stat, values_from = Value)

cat("\nEnrichment Factor Summary (Al-normalized, UCC reference):\n")
print(ef_summary)

write_csv(ef_summary, file.path(data_dir, "enrichment_factors_summary.csv"))

# -----------------------------------------------------------------------------
# 4. Calculate Diagnostic Elemental Ratios
# -----------------------------------------------------------------------------
cat("\n4. Calculating diagnostic elemental ratios...\n")

df_ratios <- df_ef %>%
  mutate(
    # Source identification ratios
    Pb_Zn = Pb / Zn,                    # Urban vs industrial source
    Cu_Zn = Cu / Zn,                    # Smelting signature
    Pb_Cu = Pb / Cu,                    # Paint vs wiring
    Zn_Cd = Zn / (Cd + 0.01),           # Galvanized material indicator
    As_Pb = As / (Pb + 1),              # Wood preservative vs paint
    Cr_Ni = Cr / (Ni + 1),              # Stainless steel vs other sources

    # Matrix/mineralogy ratios
    Ca_Mg = Ca / (Mg + 1),              # Calcite vs dolomite
    Ca_Sr = Ca / (Sr + 1),              # Carbonate discrimination
    Fe_Mn = Fe / (Mn + 1),              # Redox conditions
    K_Na = K / (Na + 1),                # Feldspar type / combustion indicator
    Si_Al = if_else(!is.na(SiO2_pct) & !is.na(Al2O3_pct),
                    SiO2_pct / (Al2O3_pct + 0.1), NA_real_),  # Clay vs quartz

    # Combustion indicators (from XRF)
    Ca_K = if_else(!is.na(CaO_pct) & !is.na(K2O_pct),
                   CaO_pct / (K2O_pct + 0.1), NA_real_),  # Fire severity proxy
    Fe_Ca = if_else(!is.na(Fe2O3_pct) & !is.na(CaO_pct),
                    Fe2O3_pct / (CaO_pct + 0.1), NA_real_), # Soil vs ash

    # Anthropogenic signature index
    Anthro_index = (EF_Pb + EF_Zn + EF_Cu) / 3
  )

# Ratio summary
ratio_cols <- c("Pb_Zn", "Cu_Zn", "Pb_Cu", "Zn_Cd", "As_Pb", "Cr_Ni",
                "Ca_Mg", "Ca_Sr", "Fe_Mn", "K_Na", "Si_Al", "Ca_K", "Fe_Ca")

ratio_summary <- df_ratios %>%
  select(all_of(ratio_cols[ratio_cols %in% names(df_ratios)])) %>%
  summarise(across(everything(),
                   list(mean = ~mean(., na.rm = TRUE),
                        sd = ~sd(., na.rm = TRUE),
                        median = ~median(., na.rm = TRUE)),
                   .names = "{.col}_{.fn}")) %>%
  pivot_longer(everything(), names_to = "Metric", values_to = "Value")

cat("\nDiagnostic Ratio Summary:\n")
print(ratio_summary %>% pivot_wider(names_from = Metric, values_from = Value))

# -----------------------------------------------------------------------------
# 5. XRF-ICP-MS Cross-Validation
# -----------------------------------------------------------------------------
cat("\n5. Cross-validating XRF vs ICP-MS measurements...\n")

# Compare Pb, Zn, Cu between XRF and ICP-MS where both available
xrf_validation <- df_ash %>%
  filter(!is.na(Pb_xrf) & !is.na(Pb)) %>%
  select(Base_ID, Pb, Pb_xrf, Zn, Zn_xrf, Cu, Cu_xrf)

if (nrow(xrf_validation) > 5) {
  cat(sprintf("   Samples with paired XRF-ICP-MS: %d\n", nrow(xrf_validation)))

  # Pb correlation
  pb_cor <- cor(xrf_validation$Pb, xrf_validation$Pb_xrf * 10000, use = "complete.obs")  # Convert % to ppm
  pb_ratio <- mean(xrf_validation$Pb / (xrf_validation$Pb_xrf * 10000 + 0.001), na.rm = TRUE)

  # Zn correlation
  zn_cor <- cor(xrf_validation$Zn, xrf_validation$Zn_xrf * 10000, use = "complete.obs")

  cat(sprintf("\n   Pb: ICP-MS vs XRF correlation r = %.3f\n", pb_cor))
  cat(sprintf("   Zn: ICP-MS vs XRF correlation r = %.3f\n", zn_cor))

  # Create validation table
  validation_results <- tibble(
    Element = c("Pb", "Zn", "Cu"),
    N_pairs = c(sum(!is.na(xrf_validation$Pb_xrf)),
                sum(!is.na(xrf_validation$Zn_xrf)),
                sum(!is.na(xrf_validation$Cu_xrf))),
    Correlation_r = c(
      cor(xrf_validation$Pb, xrf_validation$Pb_xrf * 10000, use = "complete.obs"),
      cor(xrf_validation$Zn, xrf_validation$Zn_xrf * 10000, use = "complete.obs"),
      cor(xrf_validation$Cu, xrf_validation$Cu_xrf * 10000, use = "complete.obs")
    )
  )

  cat("\nXRF-ICP-MS Validation:\n")
  print(validation_results)
  write_csv(validation_results, file.path(data_dir, "xrf_icpms_validation.csv"))
} else {
  cat("   Insufficient paired XRF-ICP-MS data for validation\n")
}

# -----------------------------------------------------------------------------
# 6. Source Apportionment Using Ratios
# -----------------------------------------------------------------------------
cat("\n6. Source apportionment analysis...\n")

# Define typical source signatures (literature values)
source_signatures <- tribble(
  ~Source, ~Pb_Zn, ~Cu_Zn, ~Pb_Cu, ~Reference,
  "Urban soil (typical)", 0.15, 0.25, 0.6, "Chen et al. 2010",
  "Vehicle emissions", 0.3, 0.15, 2.0, "Meza-Figueroa et al. 2007",
  "Paint (lead-based)", 3.0, 0.1, 30.0, "Odigie & Flegal 2011",
  "Galvanized metal", 0.02, 0.05, 0.4, "Sutherland 2000",
  "Copper wiring/pipes", 0.1, 1.5, 0.07, "Plumlee et al. 2007"
)

cat("\nReference source signatures:\n")
print(source_signatures)

# Classify samples by dominant source signature
df_source <- df_ratios %>%
  mutate(
    Source_indicator = case_when(
      Pb_Cu > 5 ~ "Paint/Pb-rich",
      Cu_Zn > 0.8 ~ "Cu wiring/pipes",
      Pb_Zn < 0.1 ~ "Galvanized/Zn-rich",
      Pb_Zn > 0.5 ~ "Vehicle/Urban",
      TRUE ~ "Mixed/Unknown"
    )
  )

cat("\nSource classification:\n")
print(table(df_source$Source_indicator))

# -----------------------------------------------------------------------------
# 7. Generate Figure: Elemental Ratio Diagrams
# -----------------------------------------------------------------------------
cat("\n7. Generating elemental ratio figures...\n")

library(patchwork)

# Panel A: Pb/Zn vs Cu/Zn discrimination
p_ratios_a <- ggplot(df_ratios, aes(x = Pb_Zn, y = Cu_Zn)) +
  geom_point(aes(color = log10(Pb + 1)), size = 3, alpha = 0.8) +
  scale_color_viridis_c(name = "log10(Pb)") +
  scale_x_log10() + scale_y_log10() +
  geom_vline(xintercept = c(0.1, 0.5), linetype = "dashed", alpha = 0.5) +
  geom_hline(yintercept = c(0.25, 0.8), linetype = "dashed", alpha = 0.5) +
  labs(title = "A) Pb/Zn vs Cu/Zn Source Discrimination",
       x = "Pb/Zn ratio (log scale)",
       y = "Cu/Zn ratio (log scale)") +
  theme_bw() +
  annotate("text", x = 0.03, y = 0.1, label = "Galvanized", size = 3, color = "grey40") +
  annotate("text", x = 1, y = 1.5, label = "Cu-rich", size = 3, color = "grey40") +
  annotate("text", x = 1, y = 0.1, label = "Pb-rich\n(paint)", size = 3, color = "grey40")

# Panel B: Enrichment factor comparison
ef_long <- df_ef %>%
  select(Base_ID, EF_Pb, EF_Zn, EF_Cu, EF_As, EF_Cr, EF_Ni) %>%
  pivot_longer(-Base_ID, names_to = "Element", values_to = "EF") %>%
  mutate(Element = str_remove(Element, "EF_"))

p_ef <- ggplot(ef_long, aes(x = Element, y = EF)) +
  geom_boxplot(aes(fill = Element), alpha = 0.7) +
  geom_hline(yintercept = c(2, 5, 20), linetype = c("dashed", "dotted", "dashed"),
             color = c("orange", "red", "darkred"), alpha = 0.7) +
  scale_y_log10() +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  labs(title = "B) Enrichment Factors (Al-normalized)",
       x = "Element",
       y = "Enrichment Factor (log scale)") +
  theme_bw() +
  annotate("text", x = 6.5, y = 2.5, label = "Moderate", size = 2.5, color = "orange") +
  annotate("text", x = 6.5, y = 7, label = "Significant", size = 2.5, color = "red") +
  annotate("text", x = 6.5, y = 25, label = "Very High", size = 2.5, color = "darkred")

# Panel C: Ca/Mg vs Fe/Al (mineralogy)
p_mineral <- ggplot(df_ratios %>% filter(!is.na(Ca_Mg_ratio) & !is.na(Fe_Al_ratio)),
                    aes(x = Ca_Mg_ratio, y = Fe_Al_ratio)) +
  geom_point(aes(color = log10(Pb + 1)), size = 3, alpha = 0.8) +
  scale_color_viridis_c(name = "log10(Pb)") +
  labs(title = "C) Ca/Mg vs Fe/Al (Matrix Composition)",
       x = "Ca/Mg ratio",
       y = "Fe/Al ratio") +
  theme_bw()

# Panel D: Anthropogenic index vs total toxics
p_anthro <- ggplot(df_source, aes(x = Anthro_index, y = Total_Toxics_ppm)) +
  geom_point(aes(color = Source_indicator), size = 3, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "darkblue") +
  scale_y_log10() +
  scale_color_brewer(palette = "Set1", name = "Source") +
  labs(title = "D) Anthropogenic Index vs Total Toxics",
       x = "Anthropogenic Enrichment Index",
       y = "Total Toxics (ppm, log scale)") +
  theme_bw()

fig_ratios <- (p_ratios_a | p_ef) / (p_mineral | p_anthro) +
  plot_annotation(
    title = "Elemental Ratios for Source Apportionment and Data Validation",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(fig_dir, "Fig_elemental_ratios.pdf"), fig_ratios, width = 12, height = 10)
ggsave(file.path(fig_dir, "Fig_elemental_ratios.png"), fig_ratios, width = 12, height = 10, dpi = 300)
cat("   Saved: figures/Fig_elemental_ratios.pdf/png\n")

# -----------------------------------------------------------------------------
# 8. Save Enhanced Dataset
# -----------------------------------------------------------------------------
cat("\n8. Saving enhanced dataset with ratios and EFs...\n")

# Select key columns to add
df_enhanced <- df_source %>%
  select(Base_ID,
         starts_with("EF_"),
         ends_with("_class"),
         Pb_Zn, Cu_Zn, Pb_Cu, Zn_Cd, As_Pb, Cr_Ni,
         Ca_Mg, Fe_Mn, K_Na, Anthro_index, Source_indicator)

write_csv(df_enhanced, file.path(data_dir, "elemental_ratios_ef.csv"))
cat("   Saved: data/elemental_ratios_ef.csv\n")

# -----------------------------------------------------------------------------
# 9. Summary Report
# -----------------------------------------------------------------------------
cat("\n", rep("=", 60), "\n", sep = "")
cat("ELEMENTAL RATIOS AND ENRICHMENT ANALYSIS SUMMARY\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("1. Enrichment Factor Results (Al-normalized, UCC reference):\n")
cat(sprintf("   - Pb: median EF = %.1f (%s)\n",
            median(df_ef$EF_Pb, na.rm = TRUE),
            if(median(df_ef$EF_Pb, na.rm = TRUE) > 5) "Significant" else "Moderate"))
cat(sprintf("   - Zn: median EF = %.1f (%s)\n",
            median(df_ef$EF_Zn, na.rm = TRUE),
            if(median(df_ef$EF_Zn, na.rm = TRUE) > 5) "Significant" else "Moderate"))
cat(sprintf("   - Cu: median EF = %.1f (%s)\n",
            median(df_ef$EF_Cu, na.rm = TRUE),
            if(median(df_ef$EF_Cu, na.rm = TRUE) > 5) "Significant" else "Moderate"))
cat(sprintf("   - As: median EF = %.1f\n", median(df_ef$EF_As, na.rm = TRUE)))
cat(sprintf("   - Cr: median EF = %.1f\n", median(df_ef$EF_Cr, na.rm = TRUE)))

cat("\n2. Source Apportionment:\n")
source_table <- table(df_source$Source_indicator)
for (src in names(source_table)) {
  cat(sprintf("   - %s: %d samples (%.1f%%)\n", src, source_table[src],
              100 * source_table[src] / sum(source_table)))
}

cat("\n3. Key Diagnostic Ratios:\n")
cat(sprintf("   - Pb/Zn: %.3f ± %.3f (median: %.3f)\n",
            mean(df_ratios$Pb_Zn, na.rm = TRUE),
            sd(df_ratios$Pb_Zn, na.rm = TRUE),
            median(df_ratios$Pb_Zn, na.rm = TRUE)))
cat(sprintf("   - Cu/Zn: %.3f ± %.3f\n",
            mean(df_ratios$Cu_Zn, na.rm = TRUE),
            sd(df_ratios$Cu_Zn, na.rm = TRUE)))
cat(sprintf("   - Ca/Mg: %.2f ± %.2f\n",
            mean(df_ratios$Ca_Mg, na.rm = TRUE),
            sd(df_ratios$Ca_Mg, na.rm = TRUE)))

cat("\n4. Output Files:\n")
cat("   - data/enrichment_factors_summary.csv\n")
cat("   - data/elemental_ratios_ef.csv\n")
cat("   - data/xrf_icpms_validation.csv\n")
cat("   - figures/Fig_elemental_ratios.pdf/png\n")

cat("\n=== Analysis Complete ===\n")
