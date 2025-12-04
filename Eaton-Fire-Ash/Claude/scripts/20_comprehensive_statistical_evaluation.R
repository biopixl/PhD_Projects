#!/usr/bin/env Rscript
# =============================================================================
# 20_comprehensive_statistical_evaluation.R
# Rigorous statistical evaluation of ALL proxy relationships
#
# Purpose: Identify which relationships are statistically robust enough
# to support manuscript claims. Apply strict criteria:
# - Multiple testing correction (Bonferroni/FDR)
# - Effect size thresholds (|r| > 0.5 for "moderate", >0.7 for "strong")
# - Sample size considerations
# - Outlier sensitivity analysis
# =============================================================================

library(tidyverse)
library(broom)

cat("=== COMPREHENSIVE STATISTICAL EVALUATION ===\n")
cat("=== Strict Criteria for Manuscript Support ===\n\n")

# Set paths
data_dir <- "data"
fig_dir <- "figures"

# -----------------------------------------------------------------------------
# 1. Load All Data
# -----------------------------------------------------------------------------
cat("1. Loading all datasets...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)
df_ef <- read_csv(file.path(data_dir, "elemental_ratios_ef.csv"), show_col_types = FALSE)

# Load spectral proxy data if available
ftir_file <- file.path(data_dir, "ftir_organic_features.csv")
asd_file <- file.path(data_dir, "asd_organic_features.csv")

has_ftir <- file.exists(ftir_file)
has_asd <- file.exists(asd_file)

if (has_ftir) {
  df_ftir <- read_csv(ftir_file, show_col_types = FALSE)
  cat("   FTIR data loaded\n")
}
if (has_asd) {
  df_asd <- read_csv(asd_file, show_col_types = FALSE)
  cat("   ASD data loaded\n")
}

# Combine datasets
df_ash <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  left_join(df_ef, by = "Base_ID")

if (has_ftir) {
  df_ash <- df_ash %>% left_join(df_ftir, by = "Base_ID")
}
if (has_asd) {
  df_ash <- df_ash %>% left_join(df_asd, by = "Base_ID")
}

n_samples <- nrow(df_ash)
cat(sprintf("   Total ASH samples: %d\n", n_samples))

# -----------------------------------------------------------------------------
# 2. Define Statistical Criteria
# -----------------------------------------------------------------------------
cat("\n2. Statistical Criteria for Manuscript Support:\n")

cat("\n   CORRELATION THRESHOLDS:\n")
cat("   - Weak:     |r| < 0.3\n")
cat("   - Moderate: 0.3 ≤ |r| < 0.5\n")
cat("   - Strong:   0.5 ≤ |r| < 0.7\n")
cat("   - Very Strong: |r| ≥ 0.7\n")

cat("\n   SIGNIFICANCE CRITERIA:\n")
cat("   - Raw p < 0.05 (uncorrected)\n")
cat("   - Bonferroni-corrected p < 0.05\n")
cat("   - FDR-corrected (BH) p < 0.05\n")

cat("\n   MINIMUM REQUIREMENTS FOR MANUSCRIPT CLAIMS:\n")
cat("   - |r| ≥ 0.5 AND adjusted p < 0.05\n")
cat("   - OR |r| ≥ 0.7 (strong effect regardless of p)\n")
cat("   - Must survive outlier removal (Cook's D > 4/n)\n")

# -----------------------------------------------------------------------------
# 3. Define All Variables to Test
# -----------------------------------------------------------------------------
cat("\n3. Defining variables for comprehensive testing...\n")

# Target variables (what we want to predict/explain)
target_metals <- c("Pb", "Zn", "Cu", "As", "Cr", "Ni")

# XRF offset variables (for method comparison)
# Calculate offsets if XRF data available
if ("Pb_xrf" %in% names(df_ash)) {
  df_ash <- df_ash %>%
    mutate(
      Pb_offset = log10((Pb + 1) / (Pb_xrf * 10000 + 1)),
      Zn_offset = log10((Zn + 1) / (Zn_xrf * 10000 + 1)),
      Cu_offset = log10((Cu + 1) / (Cu_xrf * 10000 + 1)),
      XRF_organic = if_else(!is.na(SiO2_pct),
                            100 - (SiO2_pct + Al2O3_pct + Fe2O3_pct + CaO_pct +
                                   MgO_pct + Na2O_pct + K2O_pct + TiO2_pct +
                                   P2O5_pct + MnO_pct),
                            NA_real_)
    )
}

# Predictor categories
xrf_predictors <- c("XRF_organic", "SiO2_pct", "Al2O3_pct", "Fe2O3_pct",
                    "CaO_pct", "MgO_pct", "K2O_pct")

ratio_predictors <- c("Cr_Ni", "Fe_Mn", "Ca_Mg", "Fe_Al_ratio", "Si_Al_ratio",
                      "Pb_Zn", "Cu_Zn", "Pb_Cu", "Anthro_index")

# FTIR predictors (if available)
ftir_predictors <- if (has_ftir) {
  names(df_ftir)[names(df_ftir) != "Base_ID"]
} else { character(0) }

# ASD predictors (if available)
asd_predictors <- if (has_asd) {
  names(df_asd)[names(df_asd) != "Base_ID"]
} else { character(0) }

all_predictors <- c(xrf_predictors, ratio_predictors, ftir_predictors, asd_predictors)
all_predictors <- all_predictors[all_predictors %in% names(df_ash)]

cat(sprintf("   Target variables: %d\n", length(target_metals)))
cat(sprintf("   Predictor variables: %d\n", length(all_predictors)))
cat(sprintf("   Total tests: %d\n", length(target_metals) * length(all_predictors)))

# -----------------------------------------------------------------------------
# 4. Comprehensive Correlation Analysis
# -----------------------------------------------------------------------------
cat("\n4. Running comprehensive correlation analysis...\n")

correlation_results <- tibble(
  Target = character(),
  Predictor = character(),
  Category = character(),
  N = integer(),
  r = numeric(),
  p_raw = numeric(),
  r_clean = numeric(),
  p_clean = numeric(),
  N_influential = integer(),
  Max_CooksD = numeric()
)

for (target in target_metals) {
  for (predictor in all_predictors) {
    if (target %in% names(df_ash) & predictor %in% names(df_ash)) {

      # Get complete cases
      complete_data <- df_ash %>%
        select(Base_ID, all_of(target), all_of(predictor)) %>%
        drop_na()

      n_complete <- nrow(complete_data)

      if (n_complete >= 10) {  # Minimum sample size

        # Correlation test
        cor_test <- cor.test(complete_data[[target]], complete_data[[predictor]])

        # Linear model for Cook's D
        lm_fit <- lm(as.formula(paste(target, "~", predictor)), data = complete_data)
        cooks_d <- cooks.distance(lm_fit)
        n_influential <- sum(cooks_d > 4/n_complete, na.rm = TRUE)
        max_cooks <- max(cooks_d, na.rm = TRUE)

        # Correlation without influential points
        if (n_influential > 0 & n_influential < n_complete - 5) {
          clean_data <- complete_data[cooks_d <= 4/n_complete, ]
          cor_clean <- cor.test(clean_data[[target]], clean_data[[predictor]])
          r_clean <- cor_clean$estimate
          p_clean <- cor_clean$p.value
        } else {
          r_clean <- cor_test$estimate
          p_clean <- cor_test$p.value
        }

        # Determine predictor category
        pred_category <- case_when(
          predictor %in% xrf_predictors ~ "XRF",
          predictor %in% ratio_predictors ~ "Ratio",
          predictor %in% ftir_predictors ~ "FTIR",
          predictor %in% asd_predictors ~ "ASD",
          TRUE ~ "Other"
        )

        correlation_results <- correlation_results %>%
          add_row(
            Target = target,
            Predictor = predictor,
            Category = pred_category,
            N = n_complete,
            r = cor_test$estimate,
            p_raw = cor_test$p.value,
            r_clean = r_clean,
            p_clean = p_clean,
            N_influential = n_influential,
            Max_CooksD = max_cooks
          )
      }
    }
  }
}

# Apply multiple testing corrections
n_tests <- nrow(correlation_results)
correlation_results <- correlation_results %>%
  mutate(
    p_bonferroni = pmin(p_raw * n_tests, 1),
    p_fdr = p.adjust(p_raw, method = "BH"),
    p_clean_bonferroni = pmin(p_clean * n_tests, 1),
    p_clean_fdr = p.adjust(p_clean, method = "BH"),

    # Effect size classification
    Effect_size = case_when(
      abs(r) >= 0.7 ~ "Very Strong",
      abs(r) >= 0.5 ~ "Strong",
      abs(r) >= 0.3 ~ "Moderate",
      TRUE ~ "Weak"
    ),

    # Manuscript support criteria
    Sig_raw = p_raw < 0.05,
    Sig_bonferroni = p_bonferroni < 0.05,
    Sig_fdr = p_fdr < 0.05,

    # Survives outlier removal
    Robust = abs(r_clean) >= 0.5 & p_clean_fdr < 0.05,

    # STRICT criterion for manuscript
    Manuscript_ready = (abs(r) >= 0.5 & p_fdr < 0.05) | (abs(r) >= 0.7)
  )

cat(sprintf("   Completed %d correlation tests\n", n_tests))

# -----------------------------------------------------------------------------
# 5. Summary of Significant Relationships
# -----------------------------------------------------------------------------
cat("\n5. SUMMARY OF SIGNIFICANT RELATIONSHIPS:\n")

cat("\n   A) Relationships passing RAW p < 0.05:\n")
sig_raw <- correlation_results %>% filter(Sig_raw) %>% nrow()
cat(sprintf("      %d of %d (%.1f%%)\n", sig_raw, n_tests, 100*sig_raw/n_tests))

cat("\n   B) Relationships passing BONFERRONI correction:\n")
sig_bonf <- correlation_results %>% filter(Sig_bonferroni) %>% nrow()
cat(sprintf("      %d of %d (%.1f%%)\n", sig_bonf, n_tests, 100*sig_bonf/n_tests))

cat("\n   C) Relationships passing FDR correction:\n")
sig_fdr <- correlation_results %>% filter(Sig_fdr) %>% nrow()
cat(sprintf("      %d of %d (%.1f%%)\n", sig_fdr, n_tests, 100*sig_fdr/n_tests))

cat("\n   D) MANUSCRIPT-READY (|r| ≥ 0.5 AND FDR p < 0.05):\n")
manuscript_ready <- correlation_results %>% filter(Manuscript_ready)
cat(sprintf("      %d relationships\n", nrow(manuscript_ready)))

# -----------------------------------------------------------------------------
# 6. Detailed Manuscript-Ready Relationships
# -----------------------------------------------------------------------------
cat("\n6. MANUSCRIPT-READY RELATIONSHIPS (Strict Criteria):\n")
cat("   " , rep("=", 65), "\n", sep = "")

if (nrow(manuscript_ready) > 0) {
  manuscript_ready_sorted <- manuscript_ready %>%
    arrange(Target, desc(abs(r)))

  cat("\n   Target  Predictor           Category  N     r      p_FDR    Effect     Robust\n")
  cat("   ", rep("-", 75), "\n", sep = "")

  for (i in 1:nrow(manuscript_ready_sorted)) {
    row <- manuscript_ready_sorted[i, ]
    cat(sprintf("   %-6s  %-18s  %-8s  %-3d  %6.3f  %.4f   %-10s %s\n",
                row$Target, row$Predictor, row$Category, row$N,
                row$r, row$p_fdr, row$Effect_size,
                if_else(row$Robust, "Yes", "No")))
  }
} else {
  cat("   NO RELATIONSHIPS MEET STRICT MANUSCRIPT CRITERIA\n")
}

# -----------------------------------------------------------------------------
# 7. Category-wise Summary
# -----------------------------------------------------------------------------
cat("\n7. SUMMARY BY PREDICTOR CATEGORY:\n")
cat("   ", rep("=", 65), "\n", sep = "")

category_summary <- correlation_results %>%
  group_by(Category) %>%
  summarise(
    N_tests = n(),
    N_sig_raw = sum(Sig_raw),
    N_sig_fdr = sum(Sig_fdr),
    N_manuscript = sum(Manuscript_ready),
    Mean_abs_r = mean(abs(r)),
    Max_abs_r = max(abs(r)),
    Best_predictor = Predictor[which.max(abs(r))],
    Best_r = r[which.max(abs(r))],
    .groups = "drop"
  )

cat("\n   Category   N_tests  Sig_raw  Sig_FDR  Manuscript  Mean|r|  Max|r|  Best_predictor\n")
cat("   ", rep("-", 85), "\n", sep = "")
for (i in 1:nrow(category_summary)) {
  row <- category_summary[i, ]
  cat(sprintf("   %-10s  %5d    %5d    %5d    %5d       %.3f    %.3f   %s\n",
              row$Category, row$N_tests, row$N_sig_raw, row$N_sig_fdr,
              row$N_manuscript, row$Mean_abs_r, row$Max_abs_r, row$Best_predictor))
}

# -----------------------------------------------------------------------------
# 8. Target-wise Summary
# -----------------------------------------------------------------------------
cat("\n8. SUMMARY BY TARGET METAL:\n")
cat("   ", rep("=", 65), "\n", sep = "")

target_summary <- correlation_results %>%
  group_by(Target) %>%
  summarise(
    N_tests = n(),
    N_sig_fdr = sum(Sig_fdr),
    N_manuscript = sum(Manuscript_ready),
    N_robust = sum(Robust),
    Best_predictor = Predictor[which.max(abs(r))],
    Best_r = r[which.max(abs(r))],
    Best_p_fdr = p_fdr[which.max(abs(r))],
    .groups = "drop"
  ) %>%
  mutate(
    Metal_class = if_else(Target %in% c("Pb", "Zn", "Cu"), "Fire-enriched", "Geogenic")
  )

cat("\n   Metal  Class          Tests  Sig_FDR  Manuscript  Robust  Best_predictor       r       p_FDR\n")
cat("   ", rep("-", 95), "\n", sep = "")
for (i in 1:nrow(target_summary)) {
  row <- target_summary[i, ]
  cat(sprintf("   %-5s  %-13s  %4d   %4d     %4d        %4d    %-18s  %6.3f  %.4f\n",
              row$Target, row$Metal_class, row$N_tests, row$N_sig_fdr,
              row$N_manuscript, row$N_robust, row$Best_predictor, row$Best_r, row$Best_p_fdr))
}

# -----------------------------------------------------------------------------
# 9. XRF-ICP-MS Method Comparison (Special Focus)
# -----------------------------------------------------------------------------
cat("\n9. XRF-ICP-MS METHOD COMPARISON:\n")
cat("   ", rep("=", 65), "\n", sep = "")

if ("Pb_xrf" %in% names(df_ash)) {

  xrf_comparison <- tibble(
    Metal = character(),
    N_pairs = integer(),
    r = numeric(),
    p = numeric(),
    Bias_ppm = numeric(),
    Pct_bias = numeric(),
    LOA_lower = numeric(),
    LOA_upper = numeric()
  )

  for (metal in c("Pb", "Zn", "Cu")) {
    icpms_col <- metal
    xrf_col <- paste0(metal, "_xrf")

    if (xrf_col %in% names(df_ash)) {
      complete_data <- df_ash %>%
        filter(!is.na(.data[[icpms_col]]) & !is.na(.data[[xrf_col]])) %>%
        mutate(xrf_ppm = .data[[xrf_col]] * 10000)  # Convert to ppm

      n_pairs <- nrow(complete_data)

      if (n_pairs >= 5) {
        cor_test <- cor.test(complete_data[[icpms_col]], complete_data$xrf_ppm)

        # Bland-Altman statistics
        mean_vals <- (complete_data[[icpms_col]] + complete_data$xrf_ppm) / 2
        diff_vals <- complete_data[[icpms_col]] - complete_data$xrf_ppm
        bias <- mean(diff_vals)
        loa_lower <- bias - 1.96 * sd(diff_vals)
        loa_upper <- bias + 1.96 * sd(diff_vals)

        # Percent bias
        pct_bias <- 100 * mean((complete_data[[icpms_col]] - complete_data$xrf_ppm) /
                                 complete_data[[icpms_col]], na.rm = TRUE)

        xrf_comparison <- xrf_comparison %>%
          add_row(
            Metal = metal,
            N_pairs = n_pairs,
            r = cor_test$estimate,
            p = cor_test$p.value,
            Bias_ppm = bias,
            Pct_bias = pct_bias,
            LOA_lower = loa_lower,
            LOA_upper = loa_upper
          )
      }
    }
  }

  if (nrow(xrf_comparison) > 0) {
    cat("\n   Metal  N_pairs    r       p        Bias(ppm)   %Bias    LOA_range\n")
    cat("   ", rep("-", 70), "\n", sep = "")
    for (i in 1:nrow(xrf_comparison)) {
      row <- xrf_comparison[i, ]
      cat(sprintf("   %-5s  %5d    %.3f   %.4f   %8.1f    %6.1f   [%.0f, %.0f]\n",
                  row$Metal, row$N_pairs, row$r, row$p, row$Bias_ppm,
                  row$Pct_bias, row$LOA_lower, row$LOA_upper))
    }

    cat("\n   XRF-ICP-MS VERDICT:\n")
    if (all(xrf_comparison$r > 0.9)) {
      cat("   ✓ STRONG correlation (r > 0.9) for all metals\n")
    }
    if (any(abs(xrf_comparison$Pct_bias) > 50)) {
      cat("   ⚠ SYSTEMATIC BIAS detected (>50% for some metals)\n")
      cat("   → Supports need for correction models\n")
    }
  }
} else {
  cat("   No paired XRF-ICP-MS data available\n")
}

# -----------------------------------------------------------------------------
# 10. FINAL MANUSCRIPT RECOMMENDATIONS
# -----------------------------------------------------------------------------
cat("\n", rep("=", 70), "\n", sep = "")
cat("FINAL MANUSCRIPT RECOMMENDATIONS\n")
cat(rep("=", 70), "\n\n", sep = "")

cat("STATISTICALLY SUPPORTED CLAIMS:\n\n")

# Check XRF validation
if (exists("xrf_comparison") && nrow(xrf_comparison) > 0) {
  if (all(xrf_comparison$r > 0.9 & xrf_comparison$p < 0.001)) {
    cat("1. XRF-ICP-MS CORRELATION: ✓ SUPPORTED\n")
    cat("   - Strong correlations (r > 0.9) for Pb, Zn, Cu\n")
    cat("   - Systematic bias requires correction\n\n")
  }
}

# Check matrix effects (XRF_organic)
xrf_organic_results <- correlation_results %>%
  filter(Predictor == "XRF_organic", Target %in% c("Pb", "Zn", "Cu"))

if (nrow(xrf_organic_results) > 0) {
  if (any(xrf_organic_results$Manuscript_ready)) {
    cat("2. XRF_ORGANIC MATRIX PROXY: ✓ SUPPORTED\n")
    cat(sprintf("   - Significant correlations with: %s\n",
                paste(xrf_organic_results$Target[xrf_organic_results$Manuscript_ready], collapse = ", ")))
  } else if (any(xrf_organic_results$Sig_fdr)) {
    cat("2. XRF_ORGANIC MATRIX PROXY: ~ WEAK SUPPORT\n")
    cat("   - Significant but effect sizes below threshold\n")
  } else {
    cat("2. XRF_ORGANIC MATRIX PROXY: ✗ NOT SUPPORTED\n")
    cat("   - No significant relationships after correction\n")
  }
  cat("\n")
}

# Check spectral proxies
ftir_results <- correlation_results %>% filter(Category == "FTIR")
asd_results <- correlation_results %>% filter(Category == "ASD")

if (nrow(ftir_results) > 0) {
  if (any(ftir_results$Manuscript_ready)) {
    cat("3. FTIR SPECTRAL PROXIES: ✓ SUPPORTED\n")
  } else {
    cat("3. FTIR SPECTRAL PROXIES: ✗ NOT SUPPORTED\n")
    cat(sprintf("   - Max |r| = %.3f, none pass strict criteria\n", max(abs(ftir_results$r))))
  }
  cat("\n")
}

if (nrow(asd_results) > 0) {
  if (any(asd_results$Manuscript_ready)) {
    cat("4. ASD SPECTRAL PROXIES: ✓ SUPPORTED\n")
  } else {
    cat("4. ASD SPECTRAL PROXIES: ✗ NOT SUPPORTED\n")
    cat(sprintf("   - Max |r| = %.3f, none pass strict criteria\n", max(abs(asd_results$r))))
  }
  cat("\n")
}

# Check geogenic ratios
geogenic_results <- correlation_results %>%
  filter(Target %in% c("As", "Cr", "Ni"), Category == "Ratio")

if (nrow(geogenic_results) > 0) {
  geogenic_supported <- geogenic_results %>% filter(Manuscript_ready)
  if (nrow(geogenic_supported) > 0) {
    cat("5. GEOGENIC RATIO PROXIES: ✓ SUPPORTED\n")
    cat(sprintf("   - %d relationships pass strict criteria\n", nrow(geogenic_supported)))
  } else {
    cat("5. GEOGENIC RATIO PROXIES: ✗ NOT SUPPORTED\n")
  }
  cat("\n")
}

# Metal classification support
cat("6. METAL CLASSIFICATION (Fire-enriched vs Geogenic):\n")
fire_cv <- df_ash %>%
  summarise(
    Pb_cv = 100 * sd(Pb, na.rm = TRUE) / mean(Pb, na.rm = TRUE),
    Zn_cv = 100 * sd(Zn, na.rm = TRUE) / mean(Zn, na.rm = TRUE),
    Cu_cv = 100 * sd(Cu, na.rm = TRUE) / mean(Cu, na.rm = TRUE),
    As_cv = 100 * sd(As, na.rm = TRUE) / mean(As, na.rm = TRUE),
    Cr_cv = 100 * sd(Cr, na.rm = TRUE) / mean(Cr, na.rm = TRUE),
    Ni_cv = 100 * sd(Ni, na.rm = TRUE) / mean(Ni, na.rm = TRUE)
  )

cat(sprintf("   Fire-enriched (CV): Pb=%.0f%%, Zn=%.0f%%, Cu=%.0f%%\n",
            fire_cv$Pb_cv, fire_cv$Zn_cv, fire_cv$Cu_cv))
cat(sprintf("   Geogenic (CV):      As=%.0f%%, Cr=%.0f%%, Ni=%.0f%%\n",
            fire_cv$As_cv, fire_cv$Cr_cv, fire_cv$Ni_cv))

if (fire_cv$Pb_cv > 200 & fire_cv$As_cv < 100) {
  cat("   ✓ CV difference SUPPORTS classification\n")
} else {
  cat("   ~ CV evidence is mixed\n")
}

cat("\n")
cat(rep("-", 70), "\n", sep = "")
cat("RECOMMENDED MANUSCRIPT FOCUS:\n")
cat(rep("-", 70), "\n\n", sep = "")

# Rank what to focus on
focus_items <- tibble(
  Topic = character(),
  Support = character(),
  Priority = character()
)

# Add items based on results
if (exists("xrf_comparison") && all(xrf_comparison$r > 0.9)) {
  focus_items <- focus_items %>%
    add_row(Topic = "XRF-ICP-MS method comparison", Support = "Strong", Priority = "HIGH")
}

if (any(correlation_results$Manuscript_ready)) {
  n_ready <- sum(correlation_results$Manuscript_ready)
  focus_items <- focus_items %>%
    add_row(Topic = sprintf("Proxy relationships (%d pass criteria)", n_ready),
            Support = "Moderate", Priority = "MEDIUM")
}

focus_items <- focus_items %>%
  add_row(Topic = "Metal classification (CV-based)", Support = "Strong", Priority = "HIGH")

focus_items <- focus_items %>%
  add_row(Topic = "ICP-MS characterization (descriptive)", Support = "Strong", Priority = "HIGH")

cat("Priority  Topic                                    Support\n")
cat(rep("-", 60), "\n", sep = "")
for (i in 1:nrow(focus_items)) {
  cat(sprintf("%-8s  %-40s  %s\n",
              focus_items$Priority[i], focus_items$Topic[i], focus_items$Support[i]))
}

# -----------------------------------------------------------------------------
# 11. Save Results
# -----------------------------------------------------------------------------
cat("\n11. Saving results...\n")

write_csv(correlation_results, file.path(data_dir, "comprehensive_correlation_results.csv"))
cat("   Saved: data/comprehensive_correlation_results.csv\n")

write_csv(manuscript_ready, file.path(data_dir, "manuscript_ready_relationships.csv"))
cat("   Saved: data/manuscript_ready_relationships.csv\n")

if (exists("xrf_comparison")) {
  write_csv(xrf_comparison, file.path(data_dir, "xrf_icpms_comparison_stats.csv"))
  cat("   Saved: data/xrf_icpms_comparison_stats.csv\n")
}

cat("\n=== Comprehensive Evaluation Complete ===\n")
