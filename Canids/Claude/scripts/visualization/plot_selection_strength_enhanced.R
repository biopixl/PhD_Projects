#!/usr/bin/env Rscript
# Enhanced Publication-Quality Selection Strength Figures
# Improved fonts, colors, layout for manuscript

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(grid)
library(gridExtra)
library(cowplot)
library(ggrepel)

# Set output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load selection results
cat("Loading selection results...\n")
results <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv",
                     header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Total selected genes: %d\n", nrow(results)))

# Data preprocessing
results$dog_pvalue_plot <- ifelse(results$dog_pvalue == 0, 1e-300, results$dog_pvalue)
results$neg_log10_p <- -log10(results$dog_pvalue_plot)

# Classify selection strength
results$strength_category <- cut(results$dog_pvalue,
                                breaks = c(-Inf, 1e-10, 1e-7, 2.93e-6, Inf),
                                labels = c("p < 1×10⁻¹⁰",
                                         "1×10⁻¹⁰ to 1×10⁻⁷",
                                         "1×10⁻⁷ to 2.93×10⁻⁶",
                                         "Non-significant"),
                                right = TRUE)

# Top genes for labeling
top_genes <- results %>%
  filter(!is.na(gene_symbol) & gene_symbol != "Unknown") %>%
  arrange(dog_pvalue) %>%
  head(20)

# Define publication-quality color palette (colorblind-friendly)
colors <- c("p < 1×10⁻¹⁰" = "#0072B2",      # Blue
           "1×10⁻¹⁰ to 1×10⁻⁷" = "#E69F00", # Orange
           "1×10⁻⁷ to 2.93×10⁻⁶" = "#CC79A7", # Pink
           "Non-significant" = "#999999")     # Gray

# Base theme for all panels
theme_pub <- function(base_size = 14) {
  theme_classic(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2, hjust = 0),
      axis.title = element_text(face = "bold", size = base_size),
      axis.text = element_text(size = base_size - 2),
      legend.title = element_text(face = "bold", size = base_size - 1),
      legend.text = element_text(size = base_size - 2),
      panel.grid.major = element_line(color = "grey92", size = 0.3),
      panel.border = element_rect(color = "black", fill = NA, size = 0.5)
    )
}

# ============================================================================
# PANEL A: Distribution histogram with better styling
# ============================================================================

plot_a <- ggplot(results, aes(x = neg_log10_p)) +
  geom_histogram(bins = 50, fill = "#0072B2", color = "black", alpha = 0.8, size = 0.3) +
  geom_vline(xintercept = -log10(2.93e-6), linetype = "dashed",
             color = "#D55E00", size = 1) +
  annotate("text", x = -log10(2.93e-6), y = Inf,
           label = "Bonferroni threshold", vjust = 1.5, hjust = 1.05,
           size = 4.5, color = "#D55E00", fontface = "bold") +
  labs(title = "A",
       x = expression(bold("-log"[10]*"(p-value)")),
       y = "Number of genes") +
  theme_pub() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

# ============================================================================
# PANEL B: Cumulative distribution
# ============================================================================

results_sorted <- results %>%
  arrange(dog_pvalue) %>%
  mutate(cumulative_pct = 100 * (1:n()) / n())

plot_b <- ggplot(results_sorted, aes(x = neg_log10_p, y = cumulative_pct)) +
  geom_line(color = "#E69F00", size = 1.2) +
  geom_hline(yintercept = 64.7, linetype = "dashed", color = "#D55E00", size = 0.8) +
  annotate("text", x = 5, y = 64.7,
           label = "64.7% with p < 1×10⁻¹⁰",
           vjust = -0.5, size = 4.5, color = "#D55E00", fontface = "bold") +
  labs(title = "B",
       x = expression(bold("-log"[10]*"(p-value)")),
       y = "Cumulative percentage (%)") +
  theme_pub() +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0))

# ============================================================================
# PANEL C: Top 20 genes ranked by selection
# ============================================================================

top20_plot <- top_genes %>%
  head(20) %>%
  mutate(gene_symbol = factor(gene_symbol, levels = rev(gene_symbol)),
         log_p = -log10(ifelse(dog_pvalue == 0, 1e-300, dog_pvalue)))

plot_c <- ggplot(top20_plot, aes(x = gene_symbol, y = log_p)) +
  geom_col(fill = "#009E73", color = "black", alpha = 0.85, size = 0.3) +
  coord_flip() +
  labs(title = "C",
       x = NULL,
       y = expression(bold("-log"[10]*"(p-value)"))) +
  theme_pub() +
  theme(axis.text.y = element_text(face = "italic", size = 11)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

# ============================================================================
# PANEL D: Omega vs p-value scatter with enhanced labeling
# ============================================================================

plot_d <- ggplot(results, aes(x = dog_omega, y = neg_log10_p)) +
  geom_point(aes(color = strength_category), alpha = 0.7, size = 2) +
  geom_hline(yintercept = -log10(2.93e-6), linetype = "dashed",
             color = "#D55E00", size = 0.8) +
  geom_vline(xintercept = 1, linetype = "dotted",
             color = "grey40", size = 0.8) +
  geom_text_repel(data = head(top_genes, 10),
                  aes(label = gene_symbol),
                  size = 3.5,
                  fontface = "italic",
                  max.overlaps = 20,
                  box.padding = 0.5,
                  point.padding = 0.3,
                  segment.color = "grey60",
                  segment.size = 0.3) +
  labs(title = "D",
       x = expression(bold(omega*" (dN/dS ratio)")),
       y = expression(bold("-log"[10]*"(p-value)")),
       color = "Selection strength") +
  scale_color_manual(values = colors) +
  theme_pub() +
  theme(legend.position = c(0.72, 0.25),
        legend.background = element_rect(fill = "white", color = "black", size = 0.3),
        legend.key.size = unit(0.8, "lines")) +
  scale_x_continuous(limits = c(0, 5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 50), expand = c(0, 0))

# ============================================================================
# Combine panels with better spacing
# ============================================================================

cat("\nCreating enhanced combined figure...\n")

combined_plot <- plot_grid(
  plot_a, plot_b,
  plot_c, plot_d,
  ncol = 2,
  nrow = 2,
  labels = NULL,
  rel_widths = c(1, 1),
  rel_heights = c(1, 1.1)
)

# Save high-resolution combined figure
ggsave(filename = file.path(out_dir, "SelectionStrength_Combined.pdf"),
       plot = combined_plot,
       width = 13, height = 11, units = "in", dpi = 600,
       device = cairo_pdf)

ggsave(filename = file.path(out_dir, "SelectionStrength_Combined.png"),
       plot = combined_plot,
       width = 13, height = 11, units = "in", dpi = 600)

cat("\nSaved enhanced figures to:\n")
cat(sprintf("  %s/SelectionStrength_Combined.pdf\n", out_dir))
cat(sprintf("  %s/SelectionStrength_Combined.png\n", out_dir))
cat("\n=== COMPLETE ===\n")
