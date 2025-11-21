#!/usr/bin/env Rscript
# MASTER Figure Generation Script for Manuscript
# Follows scientific visualization best practices
# References: Rougier et al. 2014 "Ten Simple Rules for Better Figures"
#             Weissgerber et al. 2015 "Beyond Bar and Line Graphs"
#             Tufte 2001 "The Visual Display of Quantitative Information"

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(ggrepel)
library(scales)
library(viridis)
library(cowplot)

# ============================================================================
# DATA LOADING AND QUALITY CONTROL
# ============================================================================

cat("\n=== LOADING AND CLEANING DATA ===\n")

# Load selection results
data_file <- "data/selection_results/results_3species_dog_only_ANNOTATED.tsv"
raw_data <- read.delim(data_file, header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Raw data: %d genes\n", nrow(raw_data)))

# DATA QUALITY FILTERS (following best practices)
# 1. Remove computational artifacts: omega > 5 is biologically unrealistic for sustained selection
# 2. Remove NA/Inf values
# 3. Remove genes with p-value = 0 (likely numerical underflow, use minimum float instead)

selection_data <- raw_data %>%
  filter(
    dog_omega <= 5,                    # Biologically realistic dN/dS
    !is.na(dog_omega),
    !is.infinite(dog_omega),
    !is.na(dog_pvalue),
    !is.infinite(dog_pvalue)
  ) %>%
  mutate(
    # Handle p-value = 0 (numerical underflow)
    dog_pvalue_plot = ifelse(dog_pvalue == 0, .Machine$double.xmin, dog_pvalue),
    log10p = -log10(dog_pvalue_plot),

    # Categorize selection strength
    selection_strength = case_when(
      dog_pvalue < 1e-10 ~ "Very Strong\n(p < 10⁻¹⁰)",
      dog_pvalue < 1e-7 ~ "Strong\n(p < 10⁻⁷)",
      dog_pvalue < 2.93e-6 ~ "Significant\n(p < 2.93×10⁻⁶)",
      TRUE ~ "Not Significant"
    ),

    # Handle missing gene symbols
    gene_label = ifelse(is.na(gene_symbol) | gene_symbol == "Unknown" | gene_symbol == "",
                       paste0("Gene_", substr(gene_id, 12, 20)),
                       gene_symbol)
  )

cat(sprintf("After QC: %d genes (removed %d outliers)\n",
            nrow(selection_data),
            nrow(raw_data) - nrow(selection_data)))

cat(sprintf("Omega range: %.3f - %.3f\n",
            min(selection_data$dog_omega), max(selection_data$dog_omega)))
cat(sprintf("P-value range: %.2e - %.2e\n",
            min(selection_data$dog_pvalue), max(selection_data$dog_pvalue)))

# Bonferroni threshold
bonferroni <- 2.93e-6
bonferroni_log <- -log10(bonferroni)

# ============================================================================
# PUBLICATION-QUALITY THEME
# ============================================================================

theme_publication <- function(base_size = 12) {
  theme_classic(base_size = base_size) +
    theme(
      # Text
      plot.title = element_text(face = "bold", size = base_size + 4, hjust = 0),
      plot.subtitle = element_text(size = base_size, hjust = 0, color = "grey30"),
      axis.title = element_text(face = "bold", size = base_size + 2),
      axis.text = element_text(size = base_size),
      legend.title = element_text(face = "bold", size = base_size),
      legend.text = element_text(size = base_size - 1),

      # Lines and borders
      axis.line = element_line(linewidth = 0.8, color = "black"),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 1),

      # Grid (subtle)
      panel.grid.major = element_line(color = "grey92", linewidth = 0.4),
      panel.grid.minor = element_blank(),

      # Legend
      legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5),
      legend.key.size = unit(1, "lines"),

      # Margins
      plot.margin = margin(10, 10, 10, 10)
    )
}

# Color palette (colorblind-friendly, following Okabe-Ito palette)
colors_okabe_ito <- c(
  "#E69F00",  # Orange
  "#56B4E9",  # Sky Blue
  "#009E73",  # Bluish Green
  "#F0E442",  # Yellow
  "#0072B2",  # Blue
  "#D55E00",  # Vermillion
  "#CC79A7",  # Reddish Purple
  "#999999"   # Grey
)

# Set output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cat("\n=== GENERATING FIGURES ===\n\n")

# Save function with consistent parameters
save_figure <- function(plot, filename, width = 12, height = 10) {
  ggsave(
    filename = file.path(out_dir, paste0(filename, ".pdf")),
    plot = plot,
    width = width, height = height, units = "in", dpi = 600,
    device = cairo_pdf
  )

  ggsave(
    filename = file.path(out_dir, paste0(filename, ".png")),
    plot = plot,
    width = width, height = height, units = "in", dpi = 600
  )

  cat(sprintf("✓ Saved: %s (PDF & PNG, %d×%d in, 600 DPI)\n",
              filename, width, height))
}

cat("Master figure generation script loaded successfully.\n")
cat("Data quality filters applied. Ready to generate figures.\n\n")
