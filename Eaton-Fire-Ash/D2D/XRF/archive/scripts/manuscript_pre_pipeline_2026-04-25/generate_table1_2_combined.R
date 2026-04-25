#!/usr/bin/env Rscript
# Generate combined Table 1 & 2 with tight margins and wider columns

library(tidyverse)
library(gridExtra)
library(grid)

# =============================================================================
# Table 1: Major Elements
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

# =============================================================================
# Table 2: Trace Metals
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

# =============================================================================
# Create table themes with wider columns
# =============================================================================

table_theme <- ttheme_minimal(
  core = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 11),
    bg_params = list(fill = c("gray95", "white"), col = NA),
    padding = unit(c(8, 4), "mm")
  ),
  colhead = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 11, fontface = "bold"),
    bg_params = list(fill = "gray80", col = NA),
    padding = unit(c(8, 4), "mm")
  )
)

# =============================================================================
# Build combined figure
# =============================================================================

# Create table grobs with explicit wider widths
table1 <- tableGrob(tab1_data, rows = NULL, theme = table_theme,
                    widths = unit(c(1.5, 1.5, 1.5, 2.5, 1.2), "in"))
table2 <- tableGrob(tab2_data, rows = NULL, theme = table_theme,
                    widths = unit(c(1.5, 1.5, 1.5, 2.5, 1.2), "in"))

# Save with proper dimensions
png("/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Manuscript/Data/Table1_2_combined.png",
    width = 10, height = 8, units = "in", res = 300, bg = "white")

# Use viewport-based layout for precise positioning
grid.newpage()

# Main title
grid.text("Table 1. Metal concentrations (ppm) in Eaton Fire ash (n = 39)",
          x = 0.02, y = 0.97, hjust = 0,
          gp = gpar(fontsize = 13, fontface = "bold"))

# Subtitle A
grid.text("(A) Major elements",
          x = 0.02, y = 0.93, hjust = 0,
          gp = gpar(fontsize = 12, fontface = "bold"))

# Table 1
pushViewport(viewport(x = 0.5, y = 0.72, width = 0.96, height = 0.38))
grid.draw(table1)
popViewport()

# Subtitle B
grid.text("(B) Trace metals of toxicological concern, ordered by coefficient of variation",
          x = 0.02, y = 0.50, hjust = 0,
          gp = gpar(fontsize = 12, fontface = "bold"))

# Table 2
pushViewport(viewport(x = 0.5, y = 0.25, width = 0.96, height = 0.46))
grid.draw(table2)
popViewport()

dev.off()

cat("Combined table saved: Table1_2_combined.png\n")
