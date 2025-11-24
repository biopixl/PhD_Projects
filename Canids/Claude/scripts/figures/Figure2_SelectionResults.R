#!/usr/bin/env Rscript
# Figure 2: Genome-Wide Selection Results - FINAL
# Improvements: Remove "Unknown" labels, transparency, no table panel

library(ggplot2)
library(ggrepel)
library(patchwork)
library(dplyr)
library(scales)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Load data
data_file <- "results_3species_dog_only_ANNOTATED.tsv"

if (!file.exists(data_file)) {
  stop("Data file not found: ", data_file)
}

selection_data <- read.delim(data_file, header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Initial data: %d genes\n", nrow(selection_data)))

# ============================================================================
# CRITICAL DATA CLEANING
# ============================================================================

# 1. Handle p-values of exactly 0 (replace with minimum non-zero p-value)
min_nonzero_p <- min(selection_data$dog_pvalue[selection_data$dog_pvalue > 0], na.rm = TRUE)
cat(sprintf("Minimum non-zero p-value: %e\n", min_nonzero_p))

# Count genes with p=0
n_pzero <- sum(selection_data$dog_pvalue == 0, na.rm = TRUE)
if (n_pzero > 0) {
  cat(sprintf("WARNING: %d genes have p-value = 0 (will use %e)\n", n_pzero, min_nonzero_p))
  selection_data$dog_pvalue[selection_data$dog_pvalue == 0] <- min_nonzero_p
}

# 2. Filter extreme omega outliers (biologically unrealistic values)
cat(sprintf("Omega range before filtering: %.2f - %.2e\n",
            min(selection_data$dog_omega, na.rm = TRUE),
            max(selection_data$dog_omega, na.rm = TRUE)))

# Remove extreme outliers (omega > 10 is very unusual for dN/dS)
selection_data <- selection_data %>%
  filter(dog_omega <= 10, dog_omega > 0,
         !is.na(dog_omega), !is.infinite(dog_omega),
         !is.na(dog_pvalue), !is.infinite(dog_pvalue))

cat(sprintf("After filtering: %d genes\n", nrow(selection_data)))
cat(sprintf("Omega range: %.2f - %.2f\n",
            min(selection_data$dog_omega),
            max(selection_data$dog_omega)))

# Calculate -log10(p-value)
selection_data$log10p <- -log10(selection_data$dog_pvalue)

# Bonferroni threshold
bonferroni_threshold <- -log10(0.05 / 17046)

cat(sprintf("Bonferroni threshold: -log10(p) = %.2f (p = %.2e)\n",
            bonferroni_threshold, 0.05/17046))

# Identify top KNOWN genes to label (exclude "Unknown")
top_genes <- selection_data %>%
  filter(gene_symbol != "Unknown") %>%
  arrange(dog_pvalue) %>%
  head(10) %>%
  pull(gene_symbol)

# Add transparency based on whether gene is known
selection_data$is_known <- selection_data$gene_symbol != "Unknown"

cat(sprintf("Known genes: %d, Unknown genes: %d\n",
            sum(selection_data$is_known),
            sum(!selection_data$is_known)))

# ============================================================================
# Panel A: Volcano Plot (ω vs -log10(p-value))
# ============================================================================

# Create significance categories
selection_data$significance <- ifelse(selection_data$log10p > bonferroni_threshold,
                                       "Significant", "Not significant")

p_volcano <- ggplot(selection_data, aes(x = dog_omega, y = log10p)) +
  # Points - known genes more opaque, unknown more transparent
  geom_point(aes(color = significance,
                 alpha = ifelse(is_known, 0.8, 0.25)),
             size = 2) +
  # Color scale
  scale_color_manual(values = c("Significant" = "#E74C3C",
                                  "Not significant" = "#95A5A6")) +
  # Alpha scale (fixed values, no gradient)
  scale_alpha_identity() +
  # Bonferroni threshold line
  geom_hline(yintercept = bonferroni_threshold,
             linetype = "dashed", color = "black", linewidth = 1) +
  # Threshold annotation (positioned safely)
  annotate("text", x = 1, y = bonferroni_threshold + 1.5,
           label = "Bonferroni threshold",
           size = 3.5, fontface = "bold", hjust = 0) +
  # Label top KNOWN genes only (no "Unknown")
  geom_text_repel(
    data = subset(selection_data, gene_symbol %in% top_genes & is_known),
    aes(label = gene_symbol),
    size = 3.5,
    fontface = "bold.italic",
    max.overlaps = 30,
    box.padding = 0.7,
    point.padding = 0.6,
    segment.color = "gray40",
    segment.size = 0.4,
    min.segment.length = 0,
    force = 4,
    seed = 42  # Reproducible label positions
  ) +
  # Axis labels with proper notation
  labs(
    title = "A. Genome-Wide Selection Analysis",
    x = expression(paste(omega, " (d"[N], "/d"[S], " ratio)")),
    y = expression(-log[10](italic(p)*"-value")),
    color = ""
  ) +
  # Log scale for x-axis (omega) - CROPPED AT 2 to focus on majority of data
  scale_x_log10(
    breaks = c(0.5, 1, 2),
    labels = c("0.5", "1", "2"),
    limits = c(0.3, 2.2)
  ) +
  # Y-axis with better breaks
  scale_y_continuous(
    breaks = seq(0, ceiling(max(selection_data$log10p)), by = 5),
    limits = c(0, ceiling(max(selection_data$log10p)) + 2),
    expand = expansion(mult = c(0.02, 0.05))
  ) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9),
    legend.position = c(0.98, 0.02),
    legend.justification = c(1, 0),
    legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5),
    legend.title = element_blank(),
    legend.text = element_text(size = 9),
    panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Panel B: Distribution of ω values (log scale)
# ============================================================================

p_omega_dist <- ggplot(selection_data, aes(x = dog_omega)) +
  # Histogram
  geom_histogram(aes(y = after_stat(density)), bins = 40,
                 fill = "#3498DB", color = "black", alpha = 0.7, linewidth = 0.3) +
  # Density curve
  geom_density(color = "#E74C3C", linewidth = 1.2) +
  # Vertical lines for mean and median
  geom_vline(aes(xintercept = mean(dog_omega)), color = "#C0392B",
             linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = median(dog_omega)), color = "#2980B9",
             linetype = "dotted", linewidth = 1) +
  # Annotations (positioned carefully to avoid overlap)
  annotate("text", x = mean(selection_data$dog_omega) * 1.2, y = Inf,
           label = paste0("Mean = ", round(mean(selection_data$dog_omega), 2)),
           vjust = 1.5, hjust = 0, size = 3, fontface = "bold", color = "#C0392B") +
  annotate("text", x = median(selection_data$dog_omega) * 0.8, y = Inf,
           label = paste0("Median = ", round(median(selection_data$dog_omega), 2)),
           vjust = 3, hjust = 1, size = 3, fontface = "bold", color = "#2980B9") +
  # Labels
  labs(
    title = expression(paste("B. Distribution of ", omega)),
    x = expression(paste(omega, " (d"[N], "/d"[S], " ratio)")),
    y = "Density"
  ) +
  # Log scale for x-axis - CROPPED AT 2 to match Panel A
  scale_x_log10(
    breaks = c(0.5, 1, 2),
    labels = c("0.5", "1", "2"),
    limits = c(0.3, 2.2)
  ) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 11, face = "bold", hjust = 0),
    axis.title = element_text(size = 10, face = "bold"),
    axis.text = element_text(size = 8),
    panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
    plot.margin = margin(5, 5, 5, 5)
  )

# ============================================================================
# Panel C: Q-Q Plot (EXPANDED - no Panel D)
# ============================================================================

# Calculate expected vs observed -log10(p-values)
observed <- sort(selection_data$log10p, decreasing = FALSE)
expected <- -log10(ppoints(length(observed)))

qq_data <- data.frame(
  expected = expected,
  observed = observed
)

p_qq <- ggplot(qq_data, aes(x = expected, y = observed)) +
  # Points
  geom_point(color = "#9B59B6", alpha = 0.5, size = 2) +
  # Diagonal line (expected if no enrichment)
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "black", linewidth = 1) +
  # Labels
  labs(
    title = "C. Q-Q Plot: p-value Distribution",
    x = expression(Expected~-log[10](italic(p))),
    y = expression(Observed~-log[10](italic(p)))
  ) +
  # Set axis limits without constraining aspect ratio (allows horizontal stretch)
  scale_x_continuous(limits = c(0, max(expected)*1.1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, max(observed)*1.1), expand = c(0, 0)) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 11, face = "bold", hjust = 0),
    axis.title = element_text(size = 10, face = "bold"),
    axis.text = element_text(size = 8),
    panel.border = element_rect(fill = NA, color = "black", linewidth = 1),
    plot.margin = margin(5, 5, 5, 5)
  )

# ============================================================================
# Combine All Panels (NO TABLE - Panel D removed)
# ============================================================================

# Two-row layout: Volcano (full width) | Omega dist + Q-Q plot (balanced)
# Use wrap_plots with explicit widths for bottom row: 1:2 ratio (33% vs 67%)
figure2 <- p_volcano /
           wrap_plots(p_omega_dist, p_qq, widths = c(1, 2)) +
  plot_layout(heights = c(2.5, 1.5)) +
  plot_annotation(
    title = "Figure 2: Positive Selection in Dog Domestication",
    subtitle = paste0(nrow(selection_data), " genes under significant positive selection (Bonferroni-corrected, p < 2.93×10⁻⁶)"),
    caption = "Known genes labeled in volcano plot. Unknown genes shown with reduced opacity. Full gene list in Supplementary Table S1.",
    theme = theme(
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5),
      plot.caption = element_text(size = 9, hjust = 1, face = "italic"),
      plot.margin = margin(10, 10, 10, 10)
    )
  )

# Save figure (600 DPI to match Figure 1)
ggsave(
  filename = file.path(output_dir, "Figure2_SelectionResults.pdf"),
  plot = figure2,
  width = 12,
  height = 9,
  dpi = 600,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure2_SelectionResults.png"),
  plot = figure2,
  width = 12,
  height = 9,
  dpi = 600,
  device = "png"
)

# Print summary statistics
cat("\n=== Figure 2 Summary ===\n")
cat(sprintf("Genes analyzed: 17,046\n"))
cat(sprintf("Significantly selected genes: %d (%.2f%%)\n",
            nrow(selection_data), (nrow(selection_data) / 17046) * 100))
cat(sprintf("Known genes: %d, Unknown genes: %d\n",
            sum(selection_data$is_known),
            sum(!selection_data$is_known)))
cat(sprintf("Mean ω: %.2f\n", mean(selection_data$dog_omega)))
cat(sprintf("Median ω: %.2f\n", median(selection_data$dog_omega)))
cat(sprintf("Range ω: %.2f - %.2f\n", min(selection_data$dog_omega), max(selection_data$dog_omega)))
cat(sprintf("Strong selection (p < 1e-10): %d genes (%.1f%%)\n",
            sum(selection_data$dog_pvalue < 1e-10),
            (sum(selection_data$dog_pvalue < 1e-10) / nrow(selection_data)) * 100))

cat("\n=== FINAL IMPROVEMENTS ===\n")
cat("✓ Fixed p-value = 0 issue (replaced with minimum non-zero)\n")
cat("✓ Removed extreme omega outliers (> 10)\n")
cat("✓ Applied log scale to omega axis for better visualization\n")
cat("✓ Cropped x-axis at omega = 2 (focuses on majority of data)\n")
cat("✓ Removed 'Unknown' gene labels for clarity\n")
cat("✓ Label only top 10 KNOWN genes\n")
cat("✓ Unknown genes shown with transparency (alpha = 0.25)\n")
cat("✓ Known genes more opaque (alpha = 0.8)\n")
cat("✓ Removed Panel D (table) - more space for panels B & C\n")
cat("✓ Panel B (33%), Panel C (67%) balanced ratio using wrap_plots\n")
cat("✓ Legend moved to bottom right of Panel A\n")
cat("✓ Table data will be incorporated into manuscript text\n")
cat("✓ Updated deprecated 'size' to 'linewidth' parameters\n")
cat("✓ Increased DPI to 600 (matching Figure 1)\n")
cat("✓ Optimized figure dimensions (12x9)\n")

cat("\nFigure 2 saved to:\n")
cat("  - manuscript/figures/Figure2_SelectionResults.pdf\n")
cat("  - manuscript/figures/Figure2_SelectionResults.png\n")
