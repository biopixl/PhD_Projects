#!/usr/bin/env Rscript
# Generate all tables WITHOUT titles - just raw table content

library(tidyverse)
library(gridExtra)
library(grid)

# =============================================================================
# Table themes
# =============================================================================

table_theme <- ttheme_minimal(
  core = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 11),
    bg_params = list(fill = c("gray95", "white"), col = NA),
    padding = unit(c(6, 4), "mm")
  ),
  colhead = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 11, fontface = "bold"),
    bg_params = list(fill = "gray80", col = NA),
    padding = unit(c(6, 4), "mm")
  )
)

# =============================================================================
# Table 1: Major Elements (no title)
# =============================================================================

tab1_data <- data.frame(
  Element = c("Ca", "Fe", "Al", "K", "Mg", "Na", "Ti", "Mn"),
  Mean = c("52,728", "36,577", "36,613", "18,858", "13,947", "13,271", "6,138", "962"),
  Median = c("33,378", "38,332", "43,973", "19,522", "11,876", "14,451", "5,246", "898"),
  Range = c("10,148–322,441", "8,336–64,081", "1,912–56,585", "3,101–35,972",
            "1,089–117,363", "3,731–22,361", "3,171–19,222", "273–2,742"),
  CV = c("116", "37", "45", "31", "125", "37", "55", "48"),
  stringsAsFactors = FALSE
)
colnames(tab1_data) <- c("Element", "Mean", "Median", "Range", "CV (%)")

table1 <- tableGrob(tab1_data, rows = NULL, theme = table_theme,
                    widths = unit(c(1.2, 1.2, 1.2, 2, 1), "in"))

png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table1_major_elements.png",
    width = 7, height = 2.8, units = "in", res = 300, bg = "white")
grid.draw(table1)
dev.off()

# =============================================================================
# Table 2: Trace Metals (no title)
# =============================================================================

tab2_data <- data.frame(
  Element = c("Pb", "Zn", "Cu", "Co", "Ni", "Sb", "Cr", "Cd", "As", "V"),
  Mean = c("638", "1,310", "207", "22", "46", "9.1", "55", "0.5", "6.5", "85"),
  Median = c("61", "333", "61", "14", "26", "4.1", "43", "0.3", "6.1", "82"),
  Range = c("14–18,528", "100–23,829", "14–3,650", "5–216", "17–372",
            "2–49", "22–332", "0.1–1.5", "3–12", "20–143"),
  CV = c("464", "292", "284", "150", "143", "135", "91", "74", "33", "31"),
  stringsAsFactors = FALSE
)
colnames(tab2_data) <- c("Element", "Mean", "Median", "Range", "CV (%)")

table2 <- tableGrob(tab2_data, rows = NULL, theme = table_theme,
                    widths = unit(c(1.2, 1.2, 1.2, 2, 1), "in"))

png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table2_trace_metals.png",
    width = 7, height = 3.4, units = "in", res = 300, bg = "white")
grid.draw(table2)
dev.off()

# =============================================================================
# Table 3: XRF Calibration (no title)
# =============================================================================

tab3_data <- data.frame(
  Model = c("Cumulative L-lines", "FP m.f.%"),
  R2 = c("0.994", "0.980"),
  RMSE = c("230", "431"),
  Intercept = c("-133", "-185"),
  Slope_SE = c("0.817 (0.011)", "5,732 (141)"),
  AIC = c("485.8", "530.0"),
  dAIC = c("0", "44.2"),
  stringsAsFactors = FALSE
)
colnames(tab3_data) <- c("Model", "R²", "RMSE (ppm)", "Intercept", "Slope (SE)", "AIC", "ΔAIC")

table3 <- tableGrob(tab3_data, rows = NULL, theme = table_theme,
                    widths = unit(c(1.8, 0.8, 1.1, 1, 1.4, 0.8, 0.8), "in"))

png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table3_XRF_calibration_2models.png",
    width = 8.5, height = 1.2, units = "in", res = 300, bg = "white")
grid.draw(table3)
dev.off()

# =============================================================================
# Table 4: Threshold Classification (no title)
# =============================================================================

tab4_data <- data.frame(
  Threshold = c("80", "", "200", "", "400", "", "1000", ""),
  Model = rep(c("L-lines", "FP (m.f.%)"), 4),
  Sensitivity = c("64", "64", "86", "71", "83", "83", "100", "100"),
  Specificity = c("96", "83", "100", "100", "100", "100", "97", "97"),
  FP = c("1", "4", "0", "0", "0", "0", "1", "1"),
  FN = c("4", "4", "1", "2", "1", "1", "0", "0"),
  stringsAsFactors = FALSE
)
colnames(tab4_data) <- c("Threshold (ppm)", "Model", "Sensitivity (%)", "Specificity (%)",
                          "False Positives", "False Negatives")

table4_theme <- ttheme_minimal(
  core = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 10),
    bg_params = list(fill = rep(c("gray95", "white"), 4), col = NA),
    padding = unit(c(5, 3), "mm")
  ),
  colhead = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 10, fontface = "bold"),
    bg_params = list(fill = "gray80", col = NA),
    padding = unit(c(5, 3), "mm")
  )
)

table4 <- tableGrob(tab4_data, rows = NULL, theme = table4_theme,
                    widths = unit(c(1.3, 1, 1.3, 1.3, 1.2, 1.2), "in"))

png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table4_threshold_2models.png",
    width = 8, height = 2.8, units = "in", res = 300, bg = "white")
grid.draw(table4)
dev.off()

cat("All tables saved without titles:\n")
cat("  - Table1_major_elements.png\n")
cat("  - Table2_trace_metals.png\n")
cat("  - Table3_XRF_calibration_2models.png\n")
cat("  - Table4_threshold_2models.png\n")
