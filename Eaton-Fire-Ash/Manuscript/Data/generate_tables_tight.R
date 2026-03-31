#!/usr/bin/env Rscript
# Generate publication tables with tight margins using gridExtra

library(tidyverse)
library(gridExtra)
library(grid)

# Custom table theme with minimal padding
table_theme <- ttheme_minimal(
  core = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 11),
    bg_params = list(fill = c("gray95", "white"), col = NA),
    padding = unit(c(4, 4), "mm")
  ),
  colhead = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 11, fontface = "bold"),
    bg_params = list(fill = "gray80", col = NA),
    padding = unit(c(4, 4), "mm")
  )
)

# =============================================================================
# Table 3: XRF Calibration Models
# =============================================================================

tab3_data <- data.frame(
  Model = c("Cumulative L-lines", "FP wt%"),
  R2 = c("0.994", "0.980"),
  RMSE = c("230", "431"),
  Intercept = c("-133", "-185"),
  Slope_SE = c("0.817 (0.011)", "5,732 (141)"),
  AIC = c("485.8", "530.0"),
  dAIC = c("0", "44.2"),
  stringsAsFactors = FALSE
)

colnames(tab3_data) <- c("Model", "R²", "RMSE (ppm)", "Intercept", "Slope (SE)", "AIC", "ΔAIC")

# Create title and footnote
title3 <- textGrob("Table 3. Linear regression models for XRF calibration of Pb against ICP-MS (n = 35)",
                   gp = gpar(fontsize = 12, fontface = "bold"), hjust = 0, x = 0.02)
footnote3 <- textGrob("Slope units: ppm/count for L-line model; ppm/wt% for FP model.",
                      gp = gpar(fontsize = 10, fontface = "italic"), hjust = 0, x = 0.02)

table3 <- tableGrob(tab3_data, rows = NULL, theme = table_theme)

# Combine with minimal spacing
combined3 <- arrangeGrob(
  title3, table3, footnote3,
  nrow = 3,
  heights = unit(c(0.8, 1.5, 0.6), "null"),
  padding = unit(0, "mm")
)

# Save with tight dimensions
png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table3_XRF_calibration_2models.png",
    width = 8, height = 2, units = "in", res = 300, bg = "white")
grid.draw(combined3)
dev.off()

# =============================================================================
# Table 4: Threshold Classification Performance
# =============================================================================

tab4_data <- data.frame(
  Threshold = c("80", "", "200", "", "400", "", "1000", ""),
  Model = rep(c("L-lines", "FP (wt%)"), 4),
  Sensitivity = c("64", "64", "86", "71", "83", "83", "100", "100"),
  Specificity = c("96", "83", "100", "100", "100", "100", "97", "97"),
  FP = c("1", "4", "0", "0", "0", "0", "1", "1"),
  FN = c("4", "4", "1", "2", "1", "1", "0", "0"),
  stringsAsFactors = FALSE
)

colnames(tab4_data) <- c("Threshold (ppm)", "Model", "Sensitivity (%)", "Specificity (%)",
                          "False Positives", "False Negatives")

# Alternate row coloring for threshold groups
table4_theme <- ttheme_minimal(
  core = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 10),
    bg_params = list(fill = rep(c("gray95", "white"), 4), col = NA),
    padding = unit(c(3, 3), "mm")
  ),
  colhead = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 10, fontface = "bold"),
    bg_params = list(fill = "gray80", col = NA),
    padding = unit(c(3, 3), "mm")
  )
)

title4 <- textGrob("Table 4. Classification performance of calibrated XRF models for Pb screening thresholds (n = 35)",
                   gp = gpar(fontsize = 12, fontface = "bold"), hjust = 0, x = 0.02)
footnote4 <- textGrob("Sensitivity = TP/(TP+FN); Specificity = TN/(TN+FP)",
                      gp = gpar(fontsize = 10, fontface = "italic"), hjust = 0, x = 0.02)

table4 <- tableGrob(tab4_data, rows = NULL, theme = table4_theme)

combined4 <- arrangeGrob(
  title4, table4, footnote4,
  nrow = 3,
  heights = unit(c(0.6, 3.5, 0.5), "null"),
  padding = unit(0, "mm")
)

png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table4_threshold_2models.png",
    width = 8, height = 3.5, units = "in", res = 300, bg = "white")
grid.draw(combined4)
dev.off()

cat("Tables saved with tight margins:\n")
cat("  - Table3_XRF_calibration_2models.png\n")
cat("  - Table4_threshold_2models.png\n")
