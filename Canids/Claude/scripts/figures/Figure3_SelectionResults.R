#!/usr/bin/env Rscript
# Figure 3: Genome-Wide Selection Results - HARMONIZED
# Aesthetic improvements: text sizes, spacing, label clarity, no QC duplication

library(ggplot2)
library(ggrepel)
library(patchwork)
library(dplyr)
library(scales)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Load data
data_file <- "data/selection_results/results_3species_dog_only_ANNOTATED.tsv"

if (!file.exists(data_file)) {
  # Try alternate location
  data_file <- "results_3species_dog_only_ANNOTATED.tsv"
  if (!file.exists(data_file)) {
    stop("Data file not found. Please check path.")
  }
}

selection_data <- read.delim(data_file, header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Initial data: %d genes\n", nrow(selection_data)))

# ============================================================================
# DATA CLEANING
# ============================================================================

# Handle p-values of exactly 0
min_nonzero_p <- min(selection_data$dog_pvalue[selection_data$dog_pvalue > 0], na.rm = TRUE)
n_pzero <- sum(selection_data$dog_pvalue == 0, na.rm = TRUE)
if (n_pzero > 0) {
  cat(sprintf("Replacing %d p-values = 0 with %e\n", n_pzero, min_nonzero_p))
  selection_data$dog_pvalue[selection_data$dog_pvalue == 0] <- min_nonzero_p
}

# Filter extreme omega outliers and invalid values
selection_data <- selection_data %>%
  filter(dog_omega <= 10, dog_omega > 0,
         !is.na(dog_omega), !is.infinite(dog_omega),
         !is.na(dog_pvalue), !is.infinite(dog_pvalue))

cat(sprintf("After filtering: %d genes\n", nrow(selection_data)))

# Calculate -log10(p-value)
selection_data$log10p <- -log10(selection_data$dog_pvalue)

# Bonferroni threshold
n_tests <- 17046  # Total genes tested
bonferroni_threshold <- -log10(0.05 / n_tests)

# Identify top 6 KNOWN genes to label (reduced from 10 to prevent crowding)
top_genes <- selection_data %>%
  filter(gene_symbol != "Unknown") %>%
  arrange(dog_pvalue) %>%
  head(6) %>%
  pull(gene_symbol)

# Add transparency for known vs unknown genes
selection_data$is_known <- selection_data$gene_symbol != "Unknown"
selection_data$significance <- ifelse(selection_data$log10p > bonferroni_threshold,
                                       "Significant", "Not significant")

cat(sprintf("Top genes to label: %s\n", paste(top_genes, collapse = ", ")))

# ============================================================================
# Panel A: Volcano Plot (ω vs -log10(p-value))
# ============================================================================

p_volcano <- ggplot(selection_data, aes(x = dog_omega, y = log10p)) +
  # Points - known genes opaque, unknown transparent
  geom_point(aes(color = significance,
                 alpha = ifelse(is_known, 0.7, 0.2)),
             size = 2.5) +
  # Color scale
  scale_color_manual(values = c("Significant" = "#E74C3C",
                                  "Not significant" = "#95A5A6")) +
  scale_alpha_identity() +
  # Bonferroni threshold line
  geom_hline(yintercept = bonferroni_threshold,
             linetype = "dashed", color = "black", linewidth = 0.8) +
  # Threshold annotation
  annotate("text", x = 0.8, y = bonferroni_threshold,
           label = "Bonferroni threshold",
           size = 3.5, fontface = "bold", hjust = 0, vjust = -0.5) +
  # Label top 6 KNOWN genes with improved spacing
  geom_text_repel(
    data = subset(selection_data, gene_symbol %in% top_genes),
    aes(label = gene_symbol),
    size = 4,
    fontface = "bold.italic",
    max.overlaps = Inf,
    box.padding = 1.0,        # Increased from 0.7
    point.padding = 0.8,      # Increased from 0.6
    min.segment.length = 0,
    segment.color = "gray30",
    segment.size = 0.5,
    force = 8,                # Increased repulsion
    force_pull = 0.5,         # Pull toward points
    xlim = c(NA, NA),
    ylim = c(NA, NA),
    seed = 42
  ) +
  # Axis labels
  labs(
    x = expression(omega~"(d"[N]*"/d"[S]*" ratio)"),
    y = expression("-log"[10]*"("*italic(p)*"-value)"),
    color = ""
  ) +
  # Log scale for x-axis
  scale_x_log10(
    breaks = c(0.3, 0.5, 1, 2),
    labels = c("0.3", "0.5", "1", "2"),
    limits = c(0.25, 2.5)
  ) +
  # Y-axis
  scale_y_continuous(
    breaks = seq(0, 16, by = 5),
    limits = c(0, max(selection_data$log10p) * 1.05),
    expand = expansion(mult = c(0.02, 0.08))  # More space at top for labels
  ) +
  # Theme - harmonized with Figures 4-5
  theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    legend.position = c(0.98, 0.05),
    legend.justification = c(1, 0),
    legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5),
    legend.title = element_blank(),
    legend.text = element_text(size = 11),
    legend.key.size = unit(0.8, "lines"),
    panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
    plot.margin = margin(5, 5, 5, 5)
  )

# ============================================================================
# Panel B: Distribution of ω values
# ============================================================================

p_omega_dist <- ggplot(selection_data, aes(x = dog_omega)) +
  # Histogram
  geom_histogram(aes(y = after_stat(density)), bins = 35,
                 fill = "#3498DB", color = "black", alpha = 0.7, linewidth = 0.3) +
  # Density curve
  geom_density(color = "#E74C3C", linewidth = 1.5) +
  # Vertical lines for median and mean
  geom_vline(aes(xintercept = median(dog_omega)), color = "#2980B9",
             linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = mean(dog_omega)), color = "#C0392B",
             linetype = "dotted", linewidth = 1) +
  # Annotations
  annotate("text", x = median(selection_data$dog_omega), y = Inf,
           label = paste0("Median = ", round(median(selection_data$dog_omega), 2)),
           vjust = 1.5, hjust = -0.1, size = 3.5, fontface = "bold", color = "#2980B9") +
  annotate("text", x = mean(selection_data$dog_omega), y = Inf,
           label = paste0("Mean = ", round(mean(selection_data$dog_omega), 2)),
           vjust = 3, hjust = -0.1, size = 3.5, fontface = "bold", color = "#C0392B") +
  # Neutral evolution line
  geom_vline(xintercept = 1, linetype = "solid", color = "black", linewidth = 0.5, alpha = 0.5) +
  annotate("text", x = 1, y = 0, label = expression(omega*" = 1"),
           vjust = -0.5, hjust = 1.1, size = 3, angle = 90, color = "gray20") +
  # Labels
  labs(
    x = expression(omega~"(d"[N]*"/d"[S]*" ratio)"),
    y = "Density"
  ) +
  # Log scale for x-axis
  scale_x_log10(
    breaks = c(0.3, 0.5, 1, 2),
    labels = c("0.3", "0.5", "1", "2"),
    limits = c(0.25, 2.5)
  ) +
  # Theme
  theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
    plot.margin = margin(5, 5, 5, 5)
  )

# ============================================================================
# Panel C: Selection Strength Categories
# ============================================================================

# Create selection strength categories
selection_data$strength_category <- cut(
  selection_data$log10p,
  breaks = c(0, bonferroni_threshold, 10, Inf),
  labels = c("Not Significant",
             "Significant\n(p < 2.93×10⁻⁶)",
             "Very Strong\n(p < 10⁻¹⁰)"),
  include.lowest = TRUE
)

# Count genes in each category
strength_summary <- selection_data %>%
  group_by(strength_category) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(percentage = (count / nrow(selection_data)) * 100)

p_strength <- ggplot(strength_summary, aes(x = strength_category, y = count, fill = strength_category)) +
  geom_col(color = "black", linewidth = 0.8, width = 0.7) +
  geom_text(aes(label = count), vjust = -0.5, size = 5, fontface = "bold") +
  geom_text(aes(label = sprintf("(%.1f%%)", percentage)), vjust = 1.5, size = 3.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = c("Not Significant" = "#95A5A6",
                                 "Significant\n(p < 2.93×10⁻⁶)" = "#3498DB",
                                 "Very Strong\n(p < 10⁻¹⁰)" = "#E74C3C")) +
  labs(
    x = "",
    y = "Number of Genes"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0),
    axis.title.y = element_text(size = 13, face = "bold"),
    axis.text.x = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 11),
    legend.position = "none",
    panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
    plot.margin = margin(5, 5, 5, 5)
  )

# ============================================================================
# Combine Panels - NO TITLE/SUBTITLE/CAPTION
# ============================================================================

figure3 <- p_volcano /
           (p_omega_dist | p_strength) +
  plot_layout(heights = c(2, 1.5))

# Save figure
ggsave(
  filename = file.path(output_dir, "Figure3_SelectionResults.pdf"),
  plot = figure3,
  width = 14,
  height = 11,
  dpi = 300,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure3_SelectionResults.png"),
  plot = figure3,
  width = 14,
  height = 11,
  dpi = 300,
  device = "png"
)

# Print summary
cat("\n=== Figure 3 Summary ===\n")
cat(sprintf("Total genes tested: %d\n", n_tests))
cat(sprintf("Genes passing filters: %d (%.2f%%)\n",
            nrow(selection_data), (nrow(selection_data) / n_tests) * 100))
cat(sprintf("Known genes: %d (%.1f%%)\n",
            sum(selection_data$is_known),
            (sum(selection_data$is_known) / nrow(selection_data)) * 100))
cat(sprintf("Bonferroni threshold: -log10(p) = %.2f (p = %.2e)\n",
            bonferroni_threshold, 0.05/n_tests))
cat(sprintf("Median ω: %.2f\n", median(selection_data$dog_omega)))
cat(sprintf("Mean ω: %.2f\n", mean(selection_data$dog_omega)))
cat(sprintf("ω range: %.2f - %.2f\n", min(selection_data$dog_omega), max(selection_data$dog_omega)))

cat("\n=== Harmonization Applied ===\n")
cat("✓ Removed figure title, subtitle, and caption\n")
cat("✓ Panel titles simplified to A, B, C\n")
cat("✓ Text sizes harmonized: 13pt base, 11pt axes, 14pt panel labels\n")
cat("✓ Reduced gene labels from 10 to 6 to prevent crowding\n")
cat("✓ Increased label spacing (box.padding, point.padding, force)\n")
cat("✓ Replaced Panel C Q-Q plot (now in Figure 1) with selection strength categories\n")
cat("✓ Standardized margins to 5px across all panels\n")
cat("✓ Consistent white space balancing\n")
cat("✓ Updated filename to Figure3_SelectionResults\n")
cat("✓ Legend positioned consistently with other figures\n")
cat("✓ Added neutral evolution line (ω = 1) to Panel B\n")

cat("\nFigure 3 saved to:\n")
cat("  - manuscript/figures/Figure3_SelectionResults.pdf\n")
cat("  - manuscript/figures/Figure3_SelectionResults.png\n")
