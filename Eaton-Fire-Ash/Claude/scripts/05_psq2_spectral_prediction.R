#!/usr/bin/env Rscript
# =============================================================================
# 05_psq2_spectral_prediction.R
# PSQ-2: Spectral prediction of metal concentrations
# =============================================================================

library(tidyverse)
library(pls)

cat("=== PSQ-2: Spectral Prediction of Metal Concentrations ===\n\n")

# Set paths
output_dir <- "data"
fig_dir <- "figures"

# -----------------------------------------------------------------------------
# 1. Load and Merge Data
# -----------------------------------------------------------------------------
cat("1. Loading and merging datasets...\n")

df_master <- read_csv(file.path(output_dir, "df_master_aviris.csv"), show_col_types = FALSE)
asd_features <- read_csv(file.path(output_dir, "asd_features_sample.csv"), show_col_types = FALSE)

# Merge spectral features with geochemistry
df_analysis <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  inner_join(asd_features, by = "Base_ID")

cat(sprintf("   Merged dataset: %d samples with paired ASD + geochemistry\n", nrow(df_analysis)))

# Check for sufficient samples
if (nrow(df_analysis) < 15) {
  cat("   WARNING: Limited sample size for robust modeling\n")
}

# -----------------------------------------------------------------------------
# 2. Prepare Predictors and Response Variables
# -----------------------------------------------------------------------------
cat("\n2. Preparing predictor and response variables...\n")

# Define spectral features (predictors)
spectral_features <- c("Slope_VIS", "Slope_NIR", "Slope_SWIR",
                       "Depth_480nm", "Depth_530nm", "Depth_670nm", "Depth_870nm",
                       "Depth_1400nm", "Depth_1900nm", "Depth_2200nm", "Depth_2300nm",
                       "Albedo_VIS", "Albedo_NIR", "Albedo_SWIR", "Overall_albedo",
                       "Fe_index", "Carbonate_index", "Char_index")

# Check which features are available
available_features <- spectral_features[spectral_features %in% names(df_analysis)]
cat(sprintf("   Available spectral features: %d/%d\n", length(available_features), length(spectral_features)))

# Define target metals
target_metals <- c("Pb", "Zn", "Cu", "Fe", "Ca")

# Log-transform metals (they span orders of magnitude)
for (metal in target_metals) {
  df_analysis[[paste0(metal, "_log")]] <- log10(df_analysis[[metal]] + 1)
}

# Remove rows with missing values in key columns
df_model <- df_analysis %>%
  select(Base_ID, all_of(paste0(target_metals, "_log")), all_of(available_features)) %>%
  drop_na()

cat(sprintf("   Complete cases for modeling: %d samples\n", nrow(df_model)))

# -----------------------------------------------------------------------------
# 3. PLSR Modeling for Each Metal
# -----------------------------------------------------------------------------
cat("\n3. Building PLSR models...\n")

# Store results
plsr_results <- list()
model_performance <- tibble(
  Metal = character(),
  N_samples = integer(),
  N_components = integer(),
  R2_cal = numeric(),
  R2_cv = numeric(),
  RMSECV = numeric(),
  Top_features = character()
)

for (metal in target_metals) {
  cat(sprintf("\n   --- %s ---\n", metal))

  response_col <- paste0(metal, "_log")

  # Create model formula
  X <- as.matrix(df_model[, available_features])
  Y <- df_model[[response_col]]

  # Check for sufficient variation
  if (sd(Y, na.rm = TRUE) < 0.01) {
    cat(sprintf("   Skipping %s: insufficient variation in response\n", metal))
    next
  }

  # Fit PLSR with leave-one-out cross-validation
  tryCatch({
    plsr_model <- plsr(Y ~ X, ncomp = min(10, nrow(df_model) - 2),
                       validation = "LOO", scale = TRUE)

    # Find optimal number of components (minimum RMSEP)
    rmsep_vals <- RMSEP(plsr_model)$val[1, 1, ]
    ncomp_opt <- which.min(rmsep_vals[-1])  # Exclude intercept-only

    if (is.na(ncomp_opt) || ncomp_opt < 1) ncomp_opt <- 1

    # Extract performance metrics
    r2_cv <- R2(plsr_model)$val[1, 1, ncomp_opt + 1]
    rmsecv <- rmsep_vals[ncomp_opt + 1]

    # Calibration R²
    Y_pred <- predict(plsr_model, ncomp = ncomp_opt)[, , 1]
    r2_cal <- cor(Y, Y_pred)^2

    # Variable importance (VIP-like using loading weights)
    loadings <- loading.weights(plsr_model)[, 1:ncomp_opt, drop = FALSE]
    vip_approx <- rowMeans(abs(loadings))
    top_features <- names(sort(vip_approx, decreasing = TRUE))[1:3]

    # Store model
    plsr_results[[metal]] <- plsr_model

    # Store performance
    model_performance <- model_performance %>%
      add_row(
        Metal = metal,
        N_samples = nrow(df_model),
        N_components = ncomp_opt,
        R2_cal = round(r2_cal, 3),
        R2_cv = round(r2_cv, 3),
        RMSECV = round(rmsecv, 3),
        Top_features = paste(top_features, collapse = ", ")
      )

    cat(sprintf("   Optimal components: %d\n", ncomp_opt))
    cat(sprintf("   R² (cal): %.3f | R² (CV): %.3f | RMSECV: %.3f\n", r2_cal, r2_cv, rmsecv))
    cat(sprintf("   Top features: %s\n", paste(top_features, collapse = ", ")))

  }, error = function(e) {
    cat(sprintf("   ERROR fitting model for %s: %s\n", metal, e$message))
  })
}

# -----------------------------------------------------------------------------
# 4. Random Forest Comparison
# -----------------------------------------------------------------------------
cat("\n4. Building Random Forest models for comparison...\n")

# Check if ranger is available
if (requireNamespace("ranger", quietly = TRUE)) {
  library(ranger)

  rf_results <- tibble(
    Metal = character(),
    R2_oob = numeric(),
    RMSE_oob = numeric(),
    Top_features = character()
  )

  for (metal in target_metals) {
    response_col <- paste0(metal, "_log")

    tryCatch({
      rf_model <- ranger(
        as.formula(paste(response_col, "~ .")),
        data = df_model %>% select(all_of(response_col), all_of(available_features)),
        num.trees = 500,
        importance = "permutation",
        mtry = floor(sqrt(length(available_features)))
      )

      # Get OOB performance
      r2_oob <- rf_model$r.squared
      rmse_oob <- sqrt(rf_model$prediction.error)

      # Get top features
      imp <- importance(rf_model)
      top_features <- names(sort(imp, decreasing = TRUE))[1:3]

      rf_results <- rf_results %>%
        add_row(
          Metal = metal,
          R2_oob = round(r2_oob, 3),
          RMSE_oob = round(rmse_oob, 3),
          Top_features = paste(top_features, collapse = ", ")
        )

      cat(sprintf("   %s: R² (OOB) = %.3f, RMSE = %.3f\n", metal, r2_oob, rmse_oob))

    }, error = function(e) {
      cat(sprintf("   ERROR with RF for %s: %s\n", metal, e$message))
    })
  }
} else {
  cat("   ranger package not available - skipping Random Forest\n")
  rf_results <- NULL
}

# -----------------------------------------------------------------------------
# 5. Generate Figure 5: Predicted vs Measured
# -----------------------------------------------------------------------------
cat("\n5. Generating Figure 5: Predicted vs Measured plots...\n")

# Create prediction plots for metals with models
prediction_plots <- list()

for (metal in names(plsr_results)) {
  model <- plsr_results[[metal]]
  response_col <- paste0(metal, "_log")

  ncomp_opt <- model_performance$N_components[model_performance$Metal == metal]
  Y_pred <- predict(model, ncomp = ncomp_opt)[, , 1]
  Y_obs <- df_model[[response_col]]

  plot_data <- tibble(
    Observed = Y_obs,
    Predicted = Y_pred,
    Metal = metal
  )

  r2_val <- model_performance$R2_cv[model_performance$Metal == metal]

  p <- ggplot(plot_data, aes(x = Observed, y = Predicted)) +
    geom_point(size = 3, alpha = 0.7, color = "steelblue") +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
    geom_smooth(method = "lm", se = FALSE, color = "darkblue", linewidth = 0.8) +
    labs(
      title = paste0(metal, " (R²cv = ", round(r2_val, 2), ")"),
      x = paste0("Observed log10(", metal, ")"),
      y = paste0("Predicted log10(", metal, ")")
    ) +
    theme_bw() +
    coord_fixed()

  prediction_plots[[metal]] <- p
}

# Combine plots
if (length(prediction_plots) >= 4) {
  library(patchwork)
  fig5 <- (prediction_plots[[1]] | prediction_plots[[2]]) /
    (prediction_plots[[3]] | prediction_plots[[4]]) +
    plot_annotation(
      title = "PLSR Spectral Prediction of Metal Concentrations",
      subtitle = paste("n =", nrow(df_model), "samples with paired ASD-ICP-MS data")
    )

  ggsave(file.path(fig_dir, "Fig5_spectral_prediction.pdf"), fig5, width = 10, height = 8)
  ggsave(file.path(fig_dir, "Fig5_spectral_prediction.png"), fig5, width = 10, height = 8, dpi = 300)
  cat("   Saved: figures/Fig5_spectral_prediction.pdf/png\n")
}

# -----------------------------------------------------------------------------
# 6. Table 4: Model Performance Summary
# -----------------------------------------------------------------------------
cat("\n6. Generating Table 4: Model performance summary...\n")

print(model_performance)

write_csv(model_performance, file.path(output_dir, "table4_spectral_models.csv"))
cat("   Saved: data/table4_spectral_models.csv\n")

if (!is.null(rf_results) && nrow(rf_results) > 0) {
  write_csv(rf_results, file.path(output_dir, "rf_model_comparison.csv"))
  cat("   Saved: data/rf_model_comparison.csv\n")
}

# -----------------------------------------------------------------------------
# 7. Feature Importance Analysis
# -----------------------------------------------------------------------------
cat("\n7. Analyzing feature importance across metals...\n")

# Aggregate top features across all metals
all_top_features <- model_performance %>%
  separate_rows(Top_features, sep = ", ") %>%
  count(Top_features, sort = TRUE) %>%
  rename(Feature = Top_features, Times_in_top3 = n)

cat("\nMost important spectral features (appearing in top 3):\n")
print(all_top_features)

write_csv(all_top_features, file.path(output_dir, "spectral_feature_importance.csv"))

# -----------------------------------------------------------------------------
# 8. Summary Report
# -----------------------------------------------------------------------------
cat("\n", rep("=", 60), "\n", sep = "")
cat("PSQ-2 ANALYSIS SUMMARY\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("SPECTRAL PREDICTION RESULTS:\n\n")

cat("1. Sample Size:\n")
cat(sprintf("   - Total paired samples (ASD + ICP-MS): %d\n", nrow(df_model)))

cat("\n2. PLSR Model Performance:\n")
for (i in 1:nrow(model_performance)) {
  row <- model_performance[i, ]
  status <- if (row$R2_cv > 0.5) "GOOD" else if (row$R2_cv > 0.3) "MODERATE" else "WEAK"
  cat(sprintf("   - %s: R²cv = %.2f (%s)\n", row$Metal, row$R2_cv, status))
}

cat("\n3. Key Spectral Features:\n")
cat(sprintf("   - Most predictive: %s\n",
            paste(all_top_features$Feature[1:min(5, nrow(all_top_features))], collapse = ", ")))

cat("\n4. Hypothesis Assessment:\n")
best_r2 <- max(model_performance$R2_cv, na.rm = TRUE)
if (best_r2 > 0.5) {
  cat("   H2 SUPPORTED: Spectral features predict metal concentrations (R² > 0.5)\n")
} else if (best_r2 > 0.3) {
  cat("   H2 PARTIALLY SUPPORTED: Moderate predictive ability (R² 0.3-0.5)\n")
} else {
  cat("   H2 NOT SUPPORTED: Weak spectral-metal relationships (R² < 0.3)\n")
}

cat("\n5. Output Files:\n")
cat("   - data/table4_spectral_models.csv\n")
cat("   - data/spectral_feature_importance.csv\n")
cat("   - figures/Fig5_spectral_prediction.pdf/png\n")

cat("\n=== PSQ-2 Analysis Complete ===\n")
