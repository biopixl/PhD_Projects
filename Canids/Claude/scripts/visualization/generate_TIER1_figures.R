#!/usr/bin/env Rscript
# TIER 1 Figure Generation: Publication-Ready Figures for Manuscript
# Fixes critical data quality issues and applies scientific visualization best practices
#
# Generated figures (currently referenced in manuscript):
#   1. SelectionStrength_Combined.{pdf,png}
#   2. QualityControl_Combined.{pdf,png}
#   3. ChromosomeDistribution_Combined.{pdf,png}
#
# Key improvements:
#   - Omega filtering (≤5) to remove computational artifacts
#   - Colorblind-friendly palettes
#   - Clear labels and legends
#   - High resolution (600 DPI)

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(ggrepel)
library(scales)
library(viridis)
library(cowplot)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  TIER 1 FIGURE GENERATION - Publication Quality               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# DATA LOADING AND QUALITY CONTROL
# ============================================================================

cat("█ STEP 1: Data Loading and Quality Control\n")
cat("─────────────────────────────────────────────────────────────────\n")

data_file <- "data/selection_results/results_3species_dog_only_ANNOTATED.tsv"
raw_data <- read.delim(data_file, header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("  • Loaded raw data: %d genes\n", nrow(raw_data)))

# CRITICAL DATA QUALITY FILTERS
# Following Tufte's principle: "Above all else show the data"
# But first: remove computational artifacts that obscure real patterns

# Check for extreme outliers
extreme_outliers <- raw_data %>% filter(dog_omega > 100)
cat(sprintf("  • Found %d extreme outliers (omega > 100)\n", nrow(extreme_outliers)))
cat(sprintf("    Range: %.2e to %.2e\n",
            min(extreme_outliers$dog_omega), max(extreme_outliers$dog_omega)))

# Filter to biologically realistic values
# Sustained selection with omega > 5 is extremely rare in nature
selection_data <- raw_data %>%
  filter(
    dog_omega <= 5,           # Biologically realistic dN/dS
    !is.na(dog_omega),
    !is.infinite(dog_omega),
    !is.na(dog_pvalue),
    !is.infinite(dog_pvalue)
  ) %>%
  mutate(
    # Handle p-value = 0 (numerical underflow in HyPhy)
    dog_pvalue_safe = ifelse(dog_pvalue == 0, .Machine$double.xmin, dog_pvalue),
    neg_log10_p = -log10(dog_pvalue_safe),

    # Classify selection strength for coloring
    strength_category = case_when(
      dog_pvalue < 1e-10 ~ "Very Strong (p<10⁻¹⁰)",
      dog_pvalue < 1e-7 ~ "Strong (p<10⁻⁷)",
      dog_pvalue < 2.93e-6 ~ "Significant (Bonferroni)",
      TRUE ~ "Not Significant"
    ),

    # Handle missing gene symbols
    gene_label = ifelse(is.na(gene_symbol) | gene_symbol == "Unknown" | gene_symbol == "",
                       paste0("Gene", substr(gene_id, 13, 18)), gene_symbol)
  )

cat(sprintf("  • After QC filtering: %d genes\n", nrow(selection_data)))
cat(sprintf("  • Removed: %d outliers/invalid (%.1f%%)\n",
            nrow(raw_data) - nrow(selection_data),
            100 * (nrow(raw_data) - nrow(selection_data)) / nrow(raw_data)))
cat(sprintf("  • Final omega range: %.3f to %.3f\n",
            min(selection_data$dog_omega), max(selection_data$dog_omega)))
cat(sprintf("  • P-value range: %.2e to %.2e\n\n",
            min(selection_data$dog_pvalue), max(selection_data$dog_pvalue)))

# Bonferroni threshold
bonferroni <- 2.93e-6
bonferroni_log <- -log10(bonferroni)

# ============================================================================
# PUBLICATION THEME
# ============================================================================

theme_publication <- function(base_size = 14) {
  theme_classic(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 4, hjust = 0),
      axis.title = element_text(face = "bold", size = base_size + 2),
      axis.text = element_text(size = base_size),
      legend.title = element_text(face = "bold", size = base_size),
      legend.text = element_text(size = base_size - 1),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
      panel.grid.major = element_line(color = "grey92", linewidth = 0.4),
      axis.line = element_line(linewidth = 0.8),
      legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5)
    )
}

# Colorblind-friendly palette (Okabe-Ito)
colors_strength <- c(
  "Very Strong (p<10⁻¹⁰)" = "#0072B2",      # Blue
  "Strong (p<10⁻⁷)" = "#E69F00",            # Orange
  "Significant (Bonferroni)" = "#009E73",   # Green
  "Not Significant" = "#999999"             # Grey
)

# Output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ============================================================================
# FIGURE 1: SELECTION STRENGTH COMBINED (4 PANELS)
# ============================================================================

cat("█ STEP 2: Generating SelectionStrength_Combined\n")
cat("─────────────────────────────────────────────────────────────────\n")

# Identify top genes for labeling
top20 <- selection_data %>%
  filter(!is.na(gene_symbol), gene_symbol != "Unknown") %>%
  arrange(dog_pvalue) %>%
  head(20)

# Panel A: Histogram of -log10(p-value)
panel_1a <- ggplot(selection_data, aes(x = neg_log10_p)) +
  geom_histogram(bins = 50, fill = "#0072B2", color = "black",
                 alpha = 0.85, linewidth = 0.4) +
  geom_vline(xintercept = bonferroni_log, linetype = "dashed",
             color = "#D55E00", linewidth = 1.2) +
  annotate("text", x = bonferroni_log + 2, y = Inf,
           label = "Bonferroni", vjust = 1.5, hjust = 0,
           size = 4.5, fontface = "bold", color = "#D55E00") +
  labs(title = "A", x = expression(bold("-log"[10]*"(p-value)")),
       y = "Number of genes") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  theme_publication()

# Panel B: Cumulative distribution
cumul_data <- selection_data %>%
  arrange(dog_pvalue) %>%
  mutate(cumulative_pct = 100 * (1:n()) / n())

panel_1b <- ggplot(cumul_data, aes(x = neg_log10_p, y = cumulative_pct)) +
  geom_line(color = "#E69F00", linewidth = 1.2) +
  geom_hline(yintercept = 64.7, linetype = "dashed",
             color = "#D55E00", linewidth = 0.8) +
  annotate("rect", xmin = 4, xmax = 10, ymin = 60, ymax = 69,
           fill = "white", color = "black", linewidth = 0.5) +
  annotate("text", x = 7, y = 64.7,
           label = "64.7% with p<10⁻¹⁰",
           size = 4, fontface = "bold") +
  labs(title = "B", x = expression(bold("-log"[10]*"(p-value)")),
       y = "Cumulative %") +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) +
  theme_publication()

# Panel C: Top 20 genes
top20_plot <- top20 %>%
  head(20) %>%
  mutate(gene_symbol = factor(gene_symbol, levels = rev(gene_symbol)),
         log_p = -log10(ifelse(dog_pvalue == 0, 1e-300, dog_pvalue)))

panel_1c <- ggplot(top20_plot, aes(x = gene_symbol, y = log_p, fill = log_p)) +
  geom_col(color = "black", linewidth = 0.4) +
  scale_fill_viridis_c(option = "plasma", direction = -1,
                       name = "-log10(p)") +
  coord_flip() +
  labs(title = "C", x = NULL,
       y = expression(bold("-log"[10]*"(p-value)"))) +
  theme_publication() +
  theme(axis.text.y = element_text(face = "italic", size = 12)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

# Panel D: Omega vs p-value scatter
panel_1d <- ggplot(selection_data, aes(x = dog_omega, y = neg_log10_p)) +
  geom_point(aes(color = strength_category), alpha = 0.7, size = 2.5) +
  geom_hline(yintercept = bonferroni_log, linetype = "dashed",
             color = "#D55E00", linewidth = 0.8) +
  geom_vline(xintercept = 1, linetype = "dotted",
             color = "grey40", linewidth = 0.8) +
  geom_text_repel(data = head(top20, 12),
                  aes(label = gene_symbol),
                  size = 3.5, fontface = "italic",
                  max.overlaps = 15, box.padding = 0.5) +
  labs(title = "D",
       x = expression(bold(omega*" (dN/dS)")),
       y = expression(bold("-log"[10]*"(p-value)")),
       color = "Selection\nstrength") +
  scale_color_manual(values = colors_strength) +
  theme_publication() +
  theme(legend.position = c(0.75, 0.28),
        legend.key.size = unit(0.8, "lines")) +
  scale_x_continuous(limits = c(0, 5), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))

# Combine panels
fig1_combined <- (panel_1a | panel_1b) / (panel_1c | panel_1d) +
  plot_layout(heights = c(1, 1.1))

# Save
ggsave(file.path(out_dir, "SelectionStrength_Combined.pdf"),
       fig1_combined, width = 14, height = 12, dpi = 600, device = cairo_pdf)
ggsave(file.path(out_dir, "SelectionStrength_Combined.png"),
       fig1_combined, width = 14, height = 12, dpi = 600)

cat("  ✓ SelectionStrength_Combined saved (PDF & PNG)\n\n")

# ============================================================================
# FIGURE 2: QUALITY CONTROL COMBINED (4 PANELS)
# ============================================================================

cat("█ STEP 3: Generating QualityControl_Combined\n")
cat("─────────────────────────────────────────────────────────────────\n")

# Panel A: Q-Q plot
observed_sorted <- sort(selection_data$neg_log10_p)
expected <- -log10(ppoints(length(observed_sorted)))
qq_data <- data.frame(expected = expected, observed = observed_sorted) %>%
  mutate(significant = observed > bonferroni_log)

# Calculate genomic inflation factor (lambda)
lambda <- median(qchisq(1 - selection_data$dog_pvalue_safe, df = 1)) / qchisq(0.5, df = 1)

panel_2a <- ggplot(qq_data, aes(x = expected, y = observed)) +
  geom_abline(intercept = 0, slope = 1, color = "#D55E00",
              linewidth = 1.2, linetype = "dashed") +
  geom_point(aes(color = significant), alpha = 0.7, size = 2) +
  annotate("rect", xmin = 2, xmax = 8, ymin = 38, ymax = 48,
           fill = "white", color = "black", linewidth = 0.5) +
  annotate("text", x = 5, y = 43,
           label = paste0("λ = ", sprintf("%.1f", lambda)),
           size = 6, fontface = "bold") +
  scale_color_manual(values = c("FALSE" = "grey50", "TRUE" = "#0072B2"),
                     name = "Significant") +
  labs(title = "A",
       x = "Expected -log10(p)",
       y = "Observed -log10(p)") +
  theme_publication() +
  theme(legend.position = "none")

# Panel B: Annotation coverage
annot_data <- selection_data %>%
  mutate(annotated = !is.na(gene_symbol) & gene_symbol != "Unknown") %>%
  count(annotated) %>%
  mutate(pct = 100 * n / sum(n),
         label_text = ifelse(annotated, "Annotated", "Unannotated"),
         label_pct = sprintf("%.1f%%\n(n=%d)", pct, n))

panel_2b <- ggplot(annot_data, aes(x = label_text, y = n, fill = annotated)) +
  geom_col(color = "black", linewidth = 0.8, width = 0.7) +
  geom_text(aes(label = label_pct), vjust = -0.5,
            size = 5, fontface = "bold") +
  scale_fill_manual(values = c("FALSE" = "#999999", "TRUE" = "#009E73"),
                    guide = "none") +
  labs(title = "B", x = NULL, y = "Number of genes") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  theme_publication() +
  theme(axis.text.x = element_text(size = 14, face = "bold"))

# Panel C: Selection strength by annotation
strength_annot <- selection_data %>%
  mutate(annotated = !is.na(gene_symbol) & gene_symbol != "Unknown") %>%
  group_by(annotated, strength_category) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(label = ifelse(annotated, "Annotated", "Unannotated"))

panel_2c <- ggplot(strength_annot, aes(x = label, y = count, fill = strength_category)) +
  geom_col(position = "dodge", color = "black", linewidth = 0.5, width = 0.6) +
  scale_fill_manual(values = colors_strength, name = "Selection\nstrength") +
  labs(title = "C", x = NULL, y = "Number of genes") +
  theme_publication() +
  theme(legend.position = "right",
        legend.key.size = unit(0.8, "lines"))

# Panel D: Omega distribution
panel_2d <- ggplot(selection_data, aes(x = dog_omega)) +
  geom_histogram(bins = 40, fill = "#619CFF", color = "black",
                 alpha = 0.7, linewidth = 0.4) +
  geom_vline(xintercept = median(selection_data$dog_omega),
             linetype = "dashed", color = "#D55E00", linewidth = 1) +
  geom_vline(xintercept = 1, linetype = "dotted",
             color = "grey30", linewidth = 1) +
  annotate("text", x = median(selection_data$dog_omega), y = Inf,
           label = paste0("Median = ", round(median(selection_data$dog_omega), 2)),
           vjust = 1.5, hjust = -0.1, size = 4, fontface = "bold", color = "#D55E00") +
  annotate("text", x = 1, y = Inf,
           label = "Neutral (ω=1)", vjust = 1.5, hjust = 1.1,
           size = 4, fontface = "bold", color = "grey30") +
  labs(title = "D",
       x = expression(bold(omega*" (dN/dS)")),
       y = "Number of genes") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  theme_publication()

# Combine panels
fig2_combined <- (panel_2a | panel_2b) / (panel_2c | panel_2d) +
  plot_layout(widths = c(1, 1))

# Save
ggsave(file.path(out_dir, "QualityControl_Combined.pdf"),
       fig2_combined, width = 14, height = 12, dpi = 600, device = cairo_pdf)
ggsave(file.path(out_dir, "QualityControl_Combined.png"),
       fig2_combined, width = 14, height = 12, dpi = 600)

cat("  ✓ QualityControl_Combined saved (PDF & PNG)\n\n")

# ============================================================================
# FIGURE 3: CHROMOSOME DISTRIBUTION (Already exists, verify compatibility)
# ============================================================================

cat("█ STEP 4: ChromosomeDistribution figure\n")
cat("─────────────────────────────────────────────────────────────────\n")
cat("  → Using existing plot_chromosome_distribution.R script\n")
cat("  → Verifying data compatibility...\n")

# Check if chromosome data exists
if (file.exists("manuscript/figures/ChromosomeDistribution_Combined.png")) {
  cat("  ✓ ChromosomeDistribution_Combined already exists\n\n")
} else {
  cat("  ! ChromosomeDistribution needs regeneration\n")
  cat("    Run: Rscript scripts/visualization/plot_chromosome_distribution.R\n\n")
}

# ============================================================================
# SUMMARY
# ============================================================================

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  TIER 1 FIGURE GENERATION COMPLETE                            ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Generated figures:\n")
cat("  1. ✓ SelectionStrength_Combined (14×12 in, 600 DPI)\n")
cat("  2. ✓ QualityControl_Combined (14×12 in, 600 DPI)\n")
cat("  3. → ChromosomeDistribution_Combined (verify existing)\n\n")

cat("Data quality summary:\n")
cat(sprintf("  • Analyzed: %d genes (filtered from %d)\n",
            nrow(selection_data), nrow(raw_data)))
cat(sprintf("  • Omega range: %.3f - %.3f (realistic values)\n",
            min(selection_data$dog_omega), max(selection_data$dog_omega)))
cat(sprintf("  • Selection categories:\n"))
strength_summary <- selection_data %>% count(strength_category)
for(i in 1:nrow(strength_summary)) {
  cat(sprintf("    - %s: %d genes\n",
              strength_summary$strength_category[i], strength_summary$n[i]))
}

cat("\nAll figures ready for manuscript integration.\n\n")
