#!/usr/bin/env Rscript
# Quality Control Plots for Selection Analysis
# Generates Q-Q plots, annotation coverage, and distribution statistics
# For Canid Domestication Manuscript Supplementary Figures

# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(cowplot)
library(gridExtra)

# Set output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load selection results
cat("Loading selection results...\n")
results <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv",
                     header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Total genes analyzed: %d\n", nrow(results)))

# ============================================================================
# PANEL A: Q-Q Plot for P-value Calibration
# ============================================================================

cat("\nGenerating Q-Q plot...\n")

# Prepare data for Q-Q plot
# Remove p-values of exactly 0 (which are < machine precision)
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

cat(sprintf("Genomic inflation factor (lambda): %.3f\n", lambda))

plot_a <- ggplot(qq_data, aes(x = expected, y = observed)) +
  geom_point(aes(color = significant), alpha = 0.6, size = 1.5) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed",
              color = "red", size = 1) +
  scale_color_manual(values = c("FALSE" = "grey60", "TRUE" = "#e74c3c"),
                    labels = c("Non-significant", "Significant"),
                    name = "") +
  labs(title = "A. Q-Q Plot: P-value Calibration",
       x = "Expected -log₁₀(p-value)",
       y = "Observed -log₁₀(p-value)",
       subtitle = sprintf("λ = %.3f", lambda)) +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11),
        axis.title = element_text(face = "bold"),
        legend.position = "bottom",
        panel.grid.major = element_line(color = "grey90")) +
  coord_cartesian(xlim = c(0, max(qq_data$expected, na.rm = TRUE)),
                 ylim = c(0, 50))

# ============================================================================
# PANEL B: Annotation Coverage Statistics
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

cat(sprintf("\n=== Annotation Coverage ===\n"))
cat(sprintf("Total genes: %d\n", total_genes))
cat(sprintf("With gene symbol: %d (%.1f%%)\n", with_symbol,
           (with_symbol/total_genes)*100))
cat(sprintf("With description: %d (%.1f%%)\n", with_description,
           (with_description/total_genes)*100))
cat(sprintf("Annotated (symbol OR description): %d (%.1f%%)\n",
           fully_annotated, annotation_pct))

# Create annotation coverage data
annotation_data <- data.frame(
  Category = c("Gene Symbol", "Functional Description", "Either Annotation"),
  Count = c(with_symbol, with_description, fully_annotated),
  Percentage = c(
    (with_symbol/total_genes)*100,
    (with_description/total_genes)*100,
    annotation_pct
  )
)

plot_b <- ggplot(annotation_data, aes(x = Category, y = Percentage, fill = Category)) +
  geom_bar(stat = "identity", color = "black", alpha = 0.8, width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%\n(%d/%d)", Percentage, Count, total_genes)),
           vjust = -0.3, size = 4, fontface = "bold") +
  geom_hline(yintercept = 75, linetype = "dashed", color = "red", size = 1) +
  annotate("text", x = 3, y = 77, label = "75% target threshold",
          color = "red", size = 3.5, hjust = 1) +
  scale_fill_manual(values = c("Gene Symbol" = "#3498db",
                               "Functional Description" = "#2ecc71",
                               "Either Annotation" = "#9b59b6")) +
  labs(title = "B. Gene Annotation Coverage",
       x = "Annotation Type",
       y = "Coverage (%)") +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 0.5),
        legend.position = "none",
        panel.grid.major.y = element_line(color = "grey90")) +
  scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, by = 20))

# ============================================================================
# PANEL C: P-value Distribution by Annotation Status
# ============================================================================

cat("\nAnalyzing selection by annotation status...\n")

# Compare selection strength between annotated and unannotated genes
results_plot <- results %>%
  mutate(
    annotation_status = ifelse(annotated, "Annotated", "Unannotated"),
    neg_log10_p = -log10(ifelse(dog_pvalue == 0, 1e-300, dog_pvalue))
  )

plot_c <- ggplot(results_plot, aes(x = annotation_status, y = neg_log10_p,
                                   fill = annotation_status)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  geom_hline(yintercept = -log10(2.93e-6), linetype = "dashed",
            color = "red", size = 1) +
  scale_fill_manual(values = c("Annotated" = "#3498db",
                              "Unannotated" = "#95a5a6")) +
  labs(title = "C. Selection Strength by Annotation Status",
       x = "Annotation Status",
       y = "-log₁₀(p-value)") +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(face = "bold"),
        legend.position = "none",
        panel.grid.major.y = element_line(color = "grey90")) +
  coord_cartesian(ylim = c(0, 50))

# Statistics
wilcox_test <- wilcox.test(neg_log10_p ~ annotation_status,
                          data = results_plot)
cat(sprintf("\nWilcoxon test (annotated vs unannotated): p = %.4f\n",
           wilcox_test$p.value))

# ============================================================================
# PANEL D: Distribution of Omega Values with Calibration
# ============================================================================

cat("\nGenerating omega distribution with calibration check...\n")

# Cap extreme omega values for visualization
results_omega <- results %>%
  mutate(
    omega_display = pmin(dog_omega, 5),
    selection_type = case_when(
      dog_omega < 0.5 ~ "Strong purifying\n(ω < 0.5)",
      dog_omega >= 0.5 & dog_omega < 1 ~ "Purifying\n(0.5 ≤ ω < 1)",
      dog_omega >= 1 & dog_omega < 1.5 ~ "Neutral/relaxed\n(1 ≤ ω < 1.5)",
      dog_omega >= 1.5 ~ "Positive\n(ω ≥ 1.5)"
    )
  )

omega_summary <- results_omega %>%
  group_by(selection_type) %>%
  summarize(count = n()) %>%
  mutate(percentage = (count / sum(count)) * 100)

cat("\n=== Omega Distribution ===\n")
print(omega_summary)

plot_d <- ggplot(results_omega, aes(x = omega_display)) +
  geom_histogram(bins = 50, fill = "#e74c3c", color = "black", alpha = 0.7) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "blue", size = 1) +
  geom_vline(xintercept = 0.5, linetype = "dotted", color = "darkgreen", size = 0.8) +
  annotate("text", x = 1, y = Inf, label = "Neutral (ω=1)",
          vjust = 2, hjust = -0.1, size = 3, color = "blue") +
  labs(title = "D. Distribution of ω Values (Quality Control)",
       x = "ω (dN/dS, capped at 5 for visualization)",
       y = "Number of genes",
       subtitle = sprintf("Median ω = %.3f", median(results$dog_omega, na.rm = TRUE))) +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11),
        axis.title = element_text(face = "bold"),
        panel.grid.major = element_line(color = "grey90"))

# ============================================================================
# Combine all panels into single QC figure
# ============================================================================

cat("\nCombining QC panels...\n")

# Arrange panels in 2x2 grid
combined_qc <- plot_grid(
  plot_a, plot_b,
  plot_c, plot_d,
  ncol = 2,
  labels = NULL
)

# Save combined figure
ggsave(filename = file.path(out_dir, "QualityControl_Combined.pdf"),
      plot = combined_qc,
      width = 12, height = 10, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "QualityControl_Combined.png"),
      plot = combined_qc,
      width = 12, height = 10, units = "in", dpi = 300)

cat("\nSaved combined QC figure to:\n")
cat(sprintf("  %s/QualityControl_Combined.pdf\n", out_dir))
cat(sprintf("  %s/QualityControl_Combined.png\n", out_dir))

# Save individual panels
ggsave(filename = file.path(out_dir, "QC_PanelA_QQplot.pdf"),
      plot = plot_a, width = 6, height = 5, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "QC_PanelB_AnnotationCoverage.pdf"),
      plot = plot_b, width = 6, height = 5, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "QC_PanelC_SelectionByAnnotation.pdf"),
      plot = plot_c, width = 6, height = 5, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "QC_PanelD_OmegaDistribution.pdf"),
      plot = plot_d, width = 6, height = 5, units = "in", dpi = 300)

cat("\nSaved individual QC panels to manuscript/figures/\n")

# ============================================================================
# Generate QC statistics summary table
# ============================================================================

qc_stats <- data.frame(
  Metric = c(
    "Total genes analyzed",
    "Genomic inflation factor (lambda)",
    "Genes with p < 1e-6",
    "Annotation coverage (%)",
    "Genes with gene symbols",
    "Genes with descriptions",
    "Median omega",
    "Genes with omega < 1 (purifying)",
    "Genes with omega ≥ 1 (neutral/positive)"
  ),
  Value = c(
    total_genes,
    sprintf("%.3f", lambda),
    sum(results$dog_pvalue < 1e-6, na.rm = TRUE),
    sprintf("%.1f%%", annotation_pct),
    with_symbol,
    with_description,
    sprintf("%.3f", median(results$dog_omega, na.rm = TRUE)),
    sum(results$dog_omega < 1, na.rm = TRUE),
    sum(results$dog_omega >= 1, na.rm = TRUE)
  )
)

write.table(qc_stats,
           file = "data/selection_results/qc_statistics.tsv",
           sep = "\t", row.names = FALSE, quote = FALSE)

cat("\nSaved QC statistics to data/selection_results/qc_statistics.tsv\n")

# ============================================================================
# Final Summary
# ============================================================================

cat("\n=== QUALITY CONTROL SUMMARY ===\n")
cat(sprintf("Lambda (genomic inflation): %.3f\n", lambda))
cat(sprintf("Annotation coverage: %.1f%% (target: 75%%)\n", annotation_pct))
cat(sprintf("Genes passing annotation target: %s\n",
           ifelse(annotation_pct >= 75, "YES", "NO")))
cat("\n=== COMPLETE ===\n")
cat("Quality control figures generated successfully!\n\n")
