#!/usr/bin/env Rscript
# Figure 2: Genome-Wide Selection Results
# Volcano plot, distributions, and top genes

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
  stop("Data file not found: ", data_file)
}

selection_data <- read.delim(data_file, header = TRUE, stringsAsFactors = FALSE)

# FILTER OUT EXTREME OUTLIERS (omega > 10 is biologically unrealistic for dN/dS)
cat(sprintf("Before filtering: %d genes\n", nrow(selection_data)))
cat(sprintf("Omega range: %.2f - %.2e\n", min(selection_data$dog_omega, na.rm = TRUE),
            max(selection_data$dog_omega, na.rm = TRUE)))

selection_data <- selection_data %>%
  filter(dog_omega <= 10, !is.na(dog_omega), !is.infinite(dog_omega))

cat(sprintf("After filtering (omega <= 10): %d genes\n", nrow(selection_data)))
cat(sprintf("Filtered omega range: %.2f - %.2f\n",
            min(selection_data$dog_omega, na.rm = TRUE),
            max(selection_data$dog_omega, na.rm = TRUE)))

# Calculate -log10(p-value) for plotting
selection_data$log10p <- -log10(selection_data$dog_pvalue)

# Bonferroni threshold
bonferroni_threshold <- -log10(0.05 / 17046)

# Identify top genes to label
top_genes <- selection_data %>%
  arrange(dog_pvalue) %>%
  head(15) %>%
  pull(gene_symbol)

# ============================================================================
# Panel A: Volcano Plot (ω vs -log10(p-value))
# ============================================================================

# Create significance categories
selection_data$significance <- ifelse(selection_data$log10p > bonferroni_threshold,
                                       "Significant", "Not significant")

p_volcano <- ggplot(selection_data, aes(x = dog_omega, y = log10p)) +
  # Points
  geom_point(aes(color = significance, size = log10p),
             alpha = 0.6) +
  # Color scale
  scale_color_manual(values = c("Significant" = "#E74C3C",
                                  "Not significant" = "#95A5A6")) +
  # Size scale
  scale_size_continuous(range = c(1, 4), guide = "none") +
  # Bonferroni threshold line
  geom_hline(yintercept = bonferroni_threshold,
             linetype = "dashed", color = "black", size = 1) +
  # Threshold annotation
  annotate("text", x = max(selection_data$dog_omega) * 0.8, y = bonferroni_threshold + 2,
           label = paste0("Bonferroni threshold\n(p = 2.93×10⁻⁶)"),
           size = 3.5, fontface = "bold") +
  # Label top genes
  geom_text_repel(
    data = subset(selection_data, gene_symbol %in% top_genes),
    aes(label = gene_symbol),
    size = 3,
    fontface = "bold",
    max.overlaps = 20,
    box.padding = 0.5,
    point.padding = 0.3,
    segment.color = "gray50"
  ) +
  # Axis labels
  labs(
    title = "Genome-Wide Selection Analysis",
    x = "ω (dN/dS ratio)",
    y = "-log₁₀(p-value)",
    color = ""
  ) +
  # Scales
  scale_x_continuous(limits = c(0, max(selection_data$dog_omega) + 0.5)) +
  scale_y_continuous(limits = c(0, max(selection_data$log10p) + 5)) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = c(0.85, 0.15),
    legend.background = element_rect(fill = "white", color = "black"),
    legend.title = element_blank(),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel B: Distribution of ω values
# ============================================================================

p_omega_dist <- ggplot(selection_data, aes(x = dog_omega)) +
  # Histogram
  geom_histogram(aes(y = after_stat(density)), bins = 30,
                 fill = "#3498DB", color = "black", alpha = 0.7) +
  # Density curve
  geom_density(color = "#E74C3C", size = 1.5) +
  # Vertical lines for mean and median
  geom_vline(aes(xintercept = mean(dog_omega)), color = "red",
             linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = median(dog_omega)), color = "blue",
             linetype = "dotted", size = 1) +
  # Annotations
  annotate("text", x = mean(selection_data$dog_omega), y = max(density(selection_data$dog_omega)$y) * 0.9,
           label = paste0("Mean = ", round(mean(selection_data$dog_omega), 2)),
           hjust = -0.1, size = 3.5, fontface = "bold", color = "red") +
  annotate("text", x = median(selection_data$dog_omega), y = max(density(selection_data$dog_omega)$y) * 0.8,
           label = paste0("Median = ", round(median(selection_data$dog_omega), 2)),
           hjust = -0.1, size = 3.5, fontface = "bold", color = "blue") +
  # Labels
  labs(
    title = "Distribution of ω (dN/dS)",
    x = "ω (dN/dS ratio)",
    y = "Density"
  ) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel C: Distribution of p-values (Q-Q plot)
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
  geom_point(color = "#9B59B6", alpha = 0.6, size = 2) +
  # Diagonal line (expected if no enrichment)
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "black", size = 1) +
  # Labels
  labs(
    title = "Q-Q Plot: Expected vs. Observed p-values",
    x = "Expected -log₁₀(p-value)",
    y = "Observed -log₁₀(p-value)"
  ) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel D: Top 15 Genes Table
# ============================================================================

# Prepare top genes table
top_genes_table <- selection_data %>%
  arrange(dog_pvalue) %>%
  head(15) %>%
  select(gene_symbol, description, dog_pvalue, dog_omega) %>%
  mutate(
    p_value_sci = format(dog_pvalue, scientific = TRUE, digits = 2),
    omega = round(dog_omega, 2)
  ) %>%
  select(gene_symbol, p_value_sci, omega)

# Convert to plot
library(gridExtra)
library(grid)

table_grob <- tableGrob(
  top_genes_table,
  rows = NULL,
  cols = c("Gene", "p-value", "ω"),
  theme = ttheme_default(
    base_size = 10,
    core = list(fg_params = list(hjust = 0, x = 0.1)),
    colhead = list(fg_params = list(fontface = "bold"))
  )
)

p_table <- ggplot() +
  annotation_custom(table_grob) +
  labs(title = "Top 15 Selected Genes") +
  theme_void() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Panel E: Selection Strength Categories
# ============================================================================

# Categorize selection strength
selection_data$strength <- cut(
  selection_data$log10p,
  breaks = c(0, -log10(1e-7), -log10(1e-10), Inf),
  labels = c("Threshold\n(p < 2.9e-6)", "Moderate\n(p < 1e-7)", "Strong\n(p < 1e-10)")
)

strength_counts <- selection_data %>%
  group_by(strength) %>%
  summarise(count = n(), .groups = "drop")

p_strength <- ggplot(strength_counts, aes(x = strength, y = count, fill = strength)) +
  geom_bar(stat = "identity", color = "black", width = 0.7) +
  geom_text(aes(label = count), vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_manual(values = c("#F39C12", "#E74C3C", "#C0392B")) +
  labs(
    title = "Selection Strength Distribution",
    x = "Selection Category",
    y = "Number of Genes"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9),
    axis.text.x = element_text(size = 10),
    legend.position = "none",
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Combine All Panels
# ============================================================================

# Layout:
# Row 1: Volcano plot (full width)
# Row 2: Omega distribution | Q-Q plot | Selection strength
# Row 3: Top genes table (full width)

figure2 <- p_volcano /
           (p_omega_dist | p_qq | p_strength) /
           p_table +
  plot_layout(heights = c(3, 2, 2)) +
  plot_annotation(
    title = "Figure 2: Genome-Wide Positive Selection in Dog Domestication",
    subtitle = "430 genes under significant positive selection (p < 2.93×10⁻⁶, Bonferroni-corrected)",
    caption = paste0("(A) Volcano plot showing ω (dN/dS) vs. -log₁₀(p-value). Red points are significant. Top 15 genes labeled.\n",
                    "(B) Distribution of ω values across 430 selected genes. Mean = 1.87, Median = 1.54.\n",
                    "(C) Q-Q plot of expected vs. observed p-values. Deviation from diagonal indicates true signal.\n",
                    "(D) Distribution of selection strength categories.\n",
                    "(E) Top 15 most strongly selected genes with statistics."),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      plot.caption = element_text(size = 10, hjust = 0)
    )
  )

# Save figure
ggsave(
  filename = file.path(output_dir, "Figure2_SelectionResults.pdf"),
  plot = figure2,
  width = 16,
  height = 14,
  dpi = 300,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure2_SelectionResults.png"),
  plot = figure2,
  width = 16,
  height = 14,
  dpi = 300,
  device = "png"
)

# Print summary statistics
cat("\n=== Selection Results Summary ===\n")
cat(sprintf("Total genes analyzed: 17,046\n"))
cat(sprintf("Dog-specific selected genes: %d (%.2f%%)\n",
            nrow(selection_data), (nrow(selection_data) / 17046) * 100))
cat(sprintf("Mean ω: %.2f\n", mean(selection_data$dog_omega)))
cat(sprintf("Median ω: %.2f\n", median(selection_data$dog_omega)))
cat(sprintf("Range ω: %.2f - %.2f\n", min(selection_data$dog_omega), max(selection_data$dog_omega)))
cat(sprintf("Strong selection (p < 1e-10): %d genes (%.1f%%)\n",
            sum(selection_data$dog_pvalue < 1e-10),
            (sum(selection_data$dog_pvalue < 1e-10) / nrow(selection_data)) * 100))

cat("\nFigure 2 created successfully!\n")
cat("Saved to:\n")
cat("  - manuscript/figures/Figure2_SelectionResults.pdf\n")
cat("  - manuscript/figures/Figure2_SelectionResults.png\n")
