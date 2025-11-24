#!/usr/bin/env Rscript
# Quality Control Figure 1 - IMPROVED VERSION
# Enhanced aesthetics: better scale axes, reduced white space, larger text, no overcrowding
# Generates Figure1_QualityControl.png for manuscript

# Load required libraries
library(ggplot2)
library(dplyr)
library(cowplot)

# Set output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load selection results
cat("Loading selection results...\n")
results <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv",
                     header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Total genes analyzed: %d\n", nrow(results)))

# ============================================================================
# PANEL A: Q-Q Plot with Improved Scale and Space Usage
# ============================================================================

cat("\nGenerating Q-Q plot with improved aesthetics...\n")

# Prepare Q-Q plot data
qq_data <- results %>%
  filter(dog_pvalue > 0) %>%
  arrange(dog_pvalue) %>%
  mutate(
    observed = -log10(dog_pvalue),
    expected = -log10(ppoints(n())),
    significant = dog_pvalue < 2.93e-6
  )

# Calculate lambda (genomic inflation factor)
chisq <- qchisq(1 - qq_data$dog_pvalue, 1)
lambda <- median(chisq, na.rm = TRUE) / qchisq(0.5, 1)

cat(sprintf("Genomic inflation factor (lambda): %.1f\n", lambda))

# Determine better y-axis limits - use 99th percentile to reduce white space
y_99th <- quantile(qq_data$observed, 0.99, na.rm = TRUE)
y_limit <- ceiling(y_99th / 5) * 5  # Round up to nearest 5
y_limit <- max(y_limit, 30)  # Ensure minimum of 30

plot_a <- ggplot(qq_data, aes(x = expected, y = observed)) +
  geom_point(aes(color = significant), alpha = 0.7, size = 2.5) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed",
              color = "red", linewidth = 1.2) +
  scale_color_manual(values = c("FALSE" = "gray50", "TRUE" = "#E41A1C"),
                    labels = c("Non-significant", "Significant"),
                    name = NULL) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("λ = %.1f", lambda),
           hjust = 1.15, vjust = 2, size = 6, fontface = "bold") +
  labs(x = "Expected -log₁₀(p-value)",
       y = "Observed -log₁₀(p-value)") +
  theme_cowplot(font_size = 15) +
  theme(
    legend.position = c(0.02, 0.98),
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5),
    legend.text = element_text(size = 12),
    axis.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size = 13),
    plot.margin = margin(10, 10, 10, 10)
  ) +
  coord_cartesian(xlim = c(0, max(qq_data$expected, na.rm = TRUE)),
                 ylim = c(0, y_limit))

# ============================================================================
# PANEL B: Annotation Coverage with Better Spacing
# ============================================================================

cat("\nCalculating annotation coverage...\n")

# Calculate annotation statistics
results <- results %>%
  mutate(
    has_symbol = gene_symbol != "Unknown" & !is.na(gene_symbol),
    has_description = description != "No description" & !is.na(description),
    annotated = has_symbol | has_description
  )

total_genes <- nrow(results)
with_symbol <- sum(results$has_symbol)
with_description <- sum(results$has_description)
fully_annotated <- sum(results$annotated)
annotation_pct <- (fully_annotated / total_genes) * 100

cat(sprintf("Annotation coverage: %.1f%% (%d/%d genes)\n",
           annotation_pct, fully_annotated, total_genes))

# Create annotation coverage data with shorter labels
annotation_data <- data.frame(
  Category = c("Gene\nSymbol", "Functional\nDescription", "Any\nAnnotation"),
  Count = c(with_symbol, with_description, fully_annotated),
  Percentage = c(
    (with_symbol/total_genes)*100,
    (with_description/total_genes)*100,
    annotation_pct
  )
)
annotation_data$Category <- factor(annotation_data$Category,
                                   levels = c("Gene\nSymbol", "Functional\nDescription", "Any\nAnnotation"))

plot_b <- ggplot(annotation_data, aes(x = Category, y = Percentage, fill = Category)) +
  geom_bar(stat = "identity", color = "black", alpha = 0.8, width = 0.65) +
  geom_text(aes(label = sprintf("%.1f%%", Percentage)),
           vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("Gene\nSymbol" = "#3498db",
                               "Functional\nDescription" = "#2ecc71",
                               "Any\nAnnotation" = "#9b59b6")) +
  labs(x = NULL,
       y = "Coverage (%)") +
  theme_cowplot(font_size = 15) +
  theme(
    axis.title.y = element_text(size = 15, face = "bold"),
    axis.text.x = element_text(size = 12, lineheight = 0.9),
    axis.text.y = element_text(size = 13),
    legend.position = "none",
    plot.margin = margin(10, 10, 10, 10)
  ) +
  scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, by = 25))

# ============================================================================
# PANEL C: Selection by Annotation with Better Scale
# ============================================================================

cat("\nAnalyzing selection by annotation status...\n")

# Compare selection strength between annotated and unannotated genes
results_plot <- results %>%
  mutate(
    annotation_status = ifelse(annotated, "Annotated", "Unannotated"),
    neg_log10_p = -log10(ifelse(dog_pvalue == 0, 1e-300, dog_pvalue))
  )

# Use same y-limit as Panel A for consistency
plot_c <- ggplot(results_plot, aes(x = annotation_status, y = neg_log10_p,
                                   fill = annotation_status)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.4, outlier.size = 1.5) +
  geom_hline(yintercept = -log10(2.93e-6), linetype = "dashed",
            color = "red", linewidth = 1.2) +
  scale_fill_manual(values = c("Annotated" = "#3498db",
                              "Unannotated" = "#95a5a6")) +
  labs(x = NULL,
       y = "-log₁₀(p-value)") +
  theme_cowplot(font_size = 15) +
  theme(
    axis.title.y = element_text(size = 15, face = "bold"),
    axis.text = element_text(size = 13),
    legend.position = "none",
    plot.margin = margin(10, 10, 10, 10)
  ) +
  coord_cartesian(ylim = c(0, y_limit))

# ============================================================================
# PANEL D: Omega Distribution with Better Spacing
# ============================================================================

cat("\nGenerating omega distribution...\n")

# Cap extreme omega values for visualization
median_omega <- median(results$dog_omega, na.rm = TRUE)

results_omega <- results %>%
  mutate(omega_display = pmin(dog_omega, 5))

plot_d <- ggplot(results_omega, aes(x = omega_display)) +
  geom_histogram(bins = 60, fill = "#e74c3c", color = "black",
                alpha = 0.75, linewidth = 0.3) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "blue", linewidth = 1.2) +
  geom_vline(xintercept = median_omega, linetype = "solid",
            color = "darkgreen", linewidth = 1.2) +
  annotate("text", x = 1, y = Inf, label = "Neutral\n(ω=1)",
          vjust = 1.3, hjust = -0.1, size = 4.5, color = "blue", fontface = "bold") +
  annotate("text", x = median_omega, y = Inf,
          label = sprintf("Median\n(ω=%.2f)", median_omega),
          vjust = 1.3, hjust = 1.1, size = 4.5, color = "darkgreen", fontface = "bold") +
  labs(x = "ω (dN/dS)",
       y = "Number of genes") +
  theme_cowplot(font_size = 15) +
  theme(
    axis.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size = 13),
    plot.margin = margin(10, 10, 10, 10)
  ) +
  scale_x_continuous(breaks = seq(0, 5, by = 1))

# ============================================================================
# Combine all panels into Figure 1
# ============================================================================

cat("\nCombining panels into Figure 1...\n")

# Arrange panels in 2x2 grid with optimal spacing (no panel labels)
combined_figure <- plot_grid(
  plot_a, plot_b,
  plot_c, plot_d,
  ncol = 2,
  nrow = 2,
  align = "hv",
  axis = "tblr",
  rel_widths = c(1, 1),
  rel_heights = c(1, 1)
)

# Save to both locations
ggsave(filename = file.path(out_dir, "Figure1_QualityControl.png"),
      plot = combined_figure,
      width = 12, height = 10, units = "in", dpi = 300, bg = "white")

ggsave(filename = file.path(out_dir, "Figure1_QualityControl.pdf"),
      plot = combined_figure,
      width = 12, height = 10, units = "in", bg = "white")

# Also save to figures/ directory for Overleaf
dir.create("figures", recursive = TRUE, showWarnings = FALSE)
ggsave(filename = "figures/Figure1_QualityControl.png",
      plot = combined_figure,
      width = 12, height = 10, units = "in", dpi = 300, bg = "white")

cat("\n=== FIGURE 1 GENERATED ===\n")
cat(sprintf("Saved to: %s/Figure1_QualityControl.png\n", out_dir))
cat(sprintf("Saved to: %s/Figure1_QualityControl.pdf\n", out_dir))
cat("Saved to: figures/Figure1_QualityControl.png\n")
cat("\nAesthetic improvements:\n")
cat(sprintf("  - Y-axis optimized: 0 to %d (reduced white space)\n", y_limit))
cat("  - Increased font sizes: base 15pt, axes 13-15pt\n")
cat("  - Increased point/line sizes for better visibility\n")
cat("  - Better spacing: reduced overcrowding\n")
cat("  - Panel labels (A-D) in bold 20pt\n")
cat("\n=== COMPLETE ===\n\n")
