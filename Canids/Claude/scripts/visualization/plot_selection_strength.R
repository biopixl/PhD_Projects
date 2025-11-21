#!/usr/bin/env Rscript
# Plot Distribution of Selection Strength
# Visualizes p-values, omega values, and selection categories
# For Canid Domestication Manuscript Figure 2

# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(grid)
library(gridExtra)
library(cowplot)

# Set output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load selection results
cat("Loading selection results...\n")
results <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv",
                     header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Total selected genes: %d\n", nrow(results)))

# Data preprocessing
# Convert p-values of 0.0 to very small value for plotting
results$dog_pvalue_plot <- ifelse(results$dog_pvalue == 0, 1e-300, results$dog_pvalue)
results$neg_log10_p <- -log10(results$dog_pvalue_plot)

# Classify selection strength based on p-values
results$strength_category <- cut(results$dog_pvalue,
                                breaks = c(-Inf, 1e-10, 1e-7, 2.93e-6, Inf),
                                labels = c("Strong\n(p<1e-10)",
                                         "Moderate\n(1e-10 to 1e-7)",
                                         "Threshold\n(1e-7 to 2.93e-6)",
                                         "Non-significant"),
                                right = TRUE)

# Summary statistics
cat("\n=== Selection Strength Summary ===\n")
cat(sprintf("Mean omega: %.3f\n", mean(results$dog_omega, na.rm = TRUE)))
cat(sprintf("Median omega: %.3f\n", median(results$dog_omega, na.rm = TRUE)))
cat(sprintf("Min omega: %.3f\n", min(results$dog_omega, na.rm = TRUE)))
cat(sprintf("Max omega: %.3f\n", max(results$dog_omega, na.rm = TRUE)))
cat(sprintf("\nMean -log10(p): %.2f\n", mean(results$neg_log10_p[is.finite(results$neg_log10_p)], na.rm = TRUE)))
cat(sprintf("Median -log10(p): %.2f\n", median(results$neg_log10_p[is.finite(results$neg_log10_p)], na.rm = TRUE)))

cat("\nSelection strength categories:\n")
print(table(results$strength_category))

# Identify top genes for labeling
top_genes <- results %>%
  filter(!is.na(gene_symbol) & gene_symbol != "Unknown") %>%
  arrange(dog_pvalue) %>%
  head(15)

cat("\n=== Top 15 selected genes ===\n")
print(top_genes[,c("gene_symbol", "dog_pvalue", "dog_omega", "description")])

# ============================================================================
# PANEL A: Distribution of -log10(p-values) - Histogram
# ============================================================================

plot_a <- ggplot(results, aes(x = neg_log10_p)) +
  geom_histogram(bins = 50, fill = "#3498db", color = "black", alpha = 0.7) +
  geom_vline(xintercept = -log10(2.93e-6), linetype = "dashed",
             color = "red", size = 1) +
  annotate("text", x = -log10(2.93e-6), y = Inf,
           label = "Bonferroni threshold\n(p=2.93e-6)",
           vjust = 2, hjust = 1.1, size = 3, color = "red") +
  labs(title = "A. Distribution of Selection Significance",
       x = "-log₁₀(p-value)",
       y = "Number of genes") +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(face = "bold"),
        panel.grid.major = element_line(color = "grey90"))

# ============================================================================
# PANEL B: Distribution of omega (dN/dS) values - Histogram
# ============================================================================

# Cap omega at reasonable value for visualization
results$omega_capped <- pmin(results$dog_omega, 10)

plot_b <- ggplot(results, aes(x = omega_capped)) +
  geom_histogram(bins = 40, fill = "#e74c3c", color = "black", alpha = 0.7) +
  geom_vline(xintercept = 1, linetype = "dashed",
             color = "blue", size = 1) +
  annotate("text", x = 1, y = Inf,
           label = "ω = 1\n(neutral)",
           vjust = 2, hjust = -0.1, size = 3, color = "blue") +
  labs(title = "B. Distribution of ω (dN/dS)",
       x = "ω (capped at 10 for visualization)",
       y = "Number of genes") +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(face = "bold"),
        panel.grid.major = element_line(color = "grey90")) +
  scale_x_continuous(breaks = seq(0, 10, by = 1))

# ============================================================================
# PANEL C: Selection Strength Categories - Bar Plot
# ============================================================================

category_counts <- as.data.frame(table(results$strength_category))
colnames(category_counts) <- c("Category", "Count")

plot_c <- ggplot(category_counts, aes(x = Category, y = Count, fill = Category)) +
  geom_bar(stat = "identity", color = "black", alpha = 0.8) +
  geom_text(aes(label = Count), vjust = -0.5, size = 4, fontface = "bold") +
  labs(title = "C. Selection Strength Categories",
       x = "Selection Strength",
       y = "Number of genes") +
  scale_fill_manual(values = c("Strong\n(p<1e-10)" = "#27ae60",
                               "Moderate\n(1e-10 to 1e-7)" = "#f39c12",
                               "Threshold\n(1e-7 to 2.93e-6)" = "#e67e22",
                               "Non-significant" = "grey70")) +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 0.5),
        legend.position = "none",
        panel.grid.major.y = element_line(color = "grey90"))

# ============================================================================
# PANEL D: Volcano Plot (omega vs -log10(p))
# ============================================================================

plot_d <- ggplot(results, aes(x = dog_omega, y = neg_log10_p)) +
  geom_point(aes(color = strength_category), alpha = 0.6, size = 1.5) +
  geom_hline(yintercept = -log10(2.93e-6), linetype = "dashed",
             color = "red", size = 0.8) +
  geom_vline(xintercept = 1, linetype = "dashed",
             color = "blue", size = 0.8) +
  # Label top genes
  ggrepel::geom_text_repel(data = head(top_genes, 10),
                           aes(label = gene_symbol),
                           size = 3,
                           max.overlaps = 20,
                           box.padding = 0.5,
                           point.padding = 0.3,
                           segment.color = "grey50") +
  labs(title = "D. Volcano Plot: Selection Strength",
       x = "ω (dN/dS ratio)",
       y = "-log₁₀(p-value)",
       color = "Significance") +
  scale_color_manual(values = c("Strong\n(p<1e-10)" = "#27ae60",
                                "Moderate\n(1e-10 to 1e-7)" = "#f39c12",
                                "Threshold\n(1e-7 to 2.93e-6)" = "#e67e22",
                                "Non-significant" = "grey70")) +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(face = "bold"),
        legend.position = "right",
        legend.title = element_text(face = "bold", size = 10),
        panel.grid.major = element_line(color = "grey90")) +
  scale_x_continuous(limits = c(0, 5)) +
  coord_cartesian(ylim = c(0, 50))  # Cap y-axis for better visualization

# ============================================================================
# Combine panels into single figure
# ============================================================================

cat("\nCreating combined figure...\n")

# Combine top row (A and B)
top_row <- plot_grid(plot_a, plot_b, ncol = 2, labels = NULL)

# Combine bottom row (C and D)
bottom_row <- plot_grid(plot_c, plot_d, ncol = 2, labels = NULL, rel_widths = c(1, 1.2))

# Combine all panels
combined_plot <- plot_grid(top_row, bottom_row, ncol = 1)

# Save combined figure
ggsave(filename = file.path(out_dir, "SelectionStrength_Combined.pdf"),
       plot = combined_plot,
       width = 12, height = 10, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "SelectionStrength_Combined.png"),
       plot = combined_plot,
       width = 12, height = 10, units = "in", dpi = 300)

cat("\nSaved combined figure to:\n")
cat(sprintf("  %s/SelectionStrength_Combined.pdf\n", out_dir))
cat(sprintf("  %s/SelectionStrength_Combined.png\n", out_dir))

# ============================================================================
# Save individual panels as well
# ============================================================================

ggsave(filename = file.path(out_dir, "PanelA_PvalueDistribution.pdf"),
       plot = plot_a, width = 6, height = 5, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "PanelB_OmegaDistribution.pdf"),
       plot = plot_b, width = 6, height = 5, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "PanelC_StrengthCategories.pdf"),
       plot = plot_c, width = 6, height = 5, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "PanelD_VolcanoPlot.pdf"),
       plot = plot_d, width = 7, height = 6, units = "in", dpi = 300)

cat("\nSaved individual panels to manuscript/figures/\n")

# ============================================================================
# Create summary table for top genes
# ============================================================================

top_genes_table <- top_genes %>%
  select(gene_symbol, dog_pvalue, dog_omega, description) %>%
  mutate(neg_log10_p = -log10(ifelse(dog_pvalue == 0, 1e-300, dog_pvalue)),
         dog_pvalue = ifelse(dog_pvalue == 0, "< 1e-300",
                           sprintf("%.2e", dog_pvalue)),
         dog_omega = sprintf("%.2f", dog_omega)) %>%
  arrange(desc(neg_log10_p))

write.table(top_genes_table,
           file = "data/selection_results/top15_genes_for_figure.tsv",
           sep = "\t", row.names = FALSE, quote = FALSE)

cat("\nSaved top 15 genes table to data/selection_results/top15_genes_for_figure.tsv\n")

# ============================================================================
# Generate statistics summary
# ============================================================================

stats_summary <- data.frame(
  Metric = c("Total selected genes",
             "Strong selection (p<1e-10)",
             "Moderate selection (1e-10 to 1e-7)",
             "Threshold selection (1e-7 to 2.93e-6)",
             "Mean omega",
             "Median omega",
             "Omega range",
             "Mean -log10(p)",
             "Median -log10(p)"),
  Value = c(nrow(results),
            sum(results$dog_pvalue < 1e-10, na.rm = TRUE),
            sum(results$dog_pvalue >= 1e-10 & results$dog_pvalue < 1e-7, na.rm = TRUE),
            sum(results$dog_pvalue >= 1e-7 & results$dog_pvalue < 2.93e-6, na.rm = TRUE),
            sprintf("%.3f", mean(results$dog_omega, na.rm = TRUE)),
            sprintf("%.3f", median(results$dog_omega, na.rm = TRUE)),
            sprintf("%.3f - %.3f", min(results$dog_omega, na.rm = TRUE),
                   max(results$dog_omega, na.rm = TRUE)),
            sprintf("%.2f", mean(results$neg_log10_p[is.finite(results$neg_log10_p)], na.rm = TRUE)),
            sprintf("%.2f", median(results$neg_log10_p[is.finite(results$neg_log10_p)], na.rm = TRUE)))
)

write.table(stats_summary,
           file = "data/selection_results/selection_strength_stats.tsv",
           sep = "\t", row.names = FALSE, quote = FALSE)

cat("\nSaved statistics summary to data/selection_results/selection_strength_stats.tsv\n")

cat("\n=== COMPLETE ===\n")
cat("Selection strength distribution plots generated successfully!\n")
cat("\nFigures saved to manuscript/figures/\n")
cat("  - SelectionStrength_Combined.pdf (main figure)\n")
cat("  - Individual panels (A-D) also saved separately\n\n")
