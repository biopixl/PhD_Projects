#!/usr/bin/env Rscript
# Figure 4: Gene Prioritization for Experimental Validation
# Heatmap of multi-criteria scores with tier assignments

library(ggplot2)
library(dplyr)
library(tidyr)
library(tibble)
library(ComplexHeatmap)
library(circlize)
library(patchwork)
library(grid)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Load prioritization data
prioritization_file <- "data/enrichment_results/GENE_PRIORITIZATION_FOR_VALIDATION.tsv"

if (!file.exists(prioritization_file)) {
  stop("Prioritization file not found: ", prioritization_file)
}

prioritization_data <- read.delim(prioritization_file, header = TRUE, stringsAsFactors = FALSE)

# ============================================================================
# Panel A: Tier Distribution
# ============================================================================

tier_counts <- prioritization_data %>%
  group_by(tier) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(tier = factor(tier, levels = c(1, 2, 3)),
         tier_label = paste0("Tier ", tier, "\n(n=", count, ")"))

p_tier_dist <- ggplot(tier_counts, aes(x = tier_label, y = count, fill = tier)) +
  geom_bar(stat = "identity", color = "black", width = 0.7) +
  geom_text(aes(label = count), vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("1" = "#E74C3C", "2" = "#F39C12", "3" = "#95A5A6")) +
  labs(
    title = "Gene Prioritization Tier Distribution",
    x = "",
    y = "Number of Genes"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    axis.text.x = element_text(size = 11),
    legend.position = "none",
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel B: Scoring Criteria Distributions
# ============================================================================

# Reshape data for scoring distributions
score_data <- prioritization_data %>%
  select(gene_symbol, selection_score, relevance_score, tractability_score, literature_score) %>%
  pivot_longer(cols = -gene_symbol, names_to = "criterion", values_to = "score") %>%
  mutate(criterion = gsub("_score", "", criterion),
         criterion = tools::toTitleCase(criterion))

p_scores_dist <- ggplot(score_data, aes(x = score, fill = criterion)) +
  geom_density(alpha = 0.6, color = "black") +
  facet_wrap(~criterion, ncol = 2) +
  scale_fill_manual(values = c("Selection" = "#E74C3C",
                                 "Relevance" = "#3498DB",
                                 "Tractability" = "#2ECC71",
                                 "Literature" = "#9B59B6")) +
  labs(
    title = "Distribution of Scoring Criteria",
    x = "Score (0-5)",
    y = "Density"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9),
    legend.position = "none",
    strip.background = element_rect(fill = "gray90", color = "black"),
    strip.text = element_text(size = 11, face = "bold"),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel C: Heatmap of Top 30 Genes
# ============================================================================

# Select top 30 genes by total score
top_genes <- prioritization_data %>%
  arrange(desc(total_score)) %>%
  head(30)

# Prepare matrix for heatmap
heatmap_matrix <- top_genes %>%
  select(gene_symbol, selection_score, relevance_score, tractability_score, literature_score) %>%
  column_to_rownames("gene_symbol") %>%
  as.matrix()

colnames(heatmap_matrix) <- c("Selection", "Relevance", "Tractability", "Literature")

# Create color function
col_fun <- colorRamp2(c(0, 2.5, 5), c("white", "yellow", "red"))

# Create tier annotation
tier_annotation <- top_genes %>%
  select(gene_symbol, tier) %>%
  column_to_rownames("gene_symbol")

tier_colors <- c("1" = "#E74C3C", "2" = "#F39C12", "3" = "#95A5A6")

row_ha <- rowAnnotation(
  Tier = tier_annotation$tier,
  col = list(Tier = tier_colors),
  annotation_name_side = "top",
  annotation_legend_param = list(
    Tier = list(title = "Priority Tier",
                 labels = c("1 (IMMEDIATE)", "2 (FOLLOW-UP)", "3 (EXPLORATORY)"))
  )
)

# Create total score annotation
total_annotation <- top_genes %>%
  select(gene_symbol, total_score) %>%
  column_to_rownames("gene_symbol")

row_ha2 <- rowAnnotation(
  Total = anno_barplot(total_annotation$total_score,
                        width = unit(3, "cm"),
                        gp = gpar(fill = "#3498DB")),
  annotation_name_side = "top"
)

# Create heatmap
pdf(file.path(output_dir, "Figure4_GenePrioritization_Heatmap.pdf"), width = 12, height = 10)

ht <- Heatmap(
  heatmap_matrix,
  name = "Score",
  col = col_fun,
  # Row settings
  row_names_side = "left",
  row_names_gp = gpar(fontsize = 10, fontface = "bold"),
  row_order = order(top_genes$total_score, decreasing = TRUE),
  # Column settings
  column_names_side = "top",
  column_names_gp = gpar(fontsize = 12, fontface = "bold"),
  column_names_rot = 0,
  column_names_centered = TRUE,
  # Annotations
  left_annotation = row_ha,
  right_annotation = row_ha2,
  # Clustering
  cluster_rows = FALSE,
  cluster_columns = FALSE,
  # Appearance
  cell_fun = function(j, i, x, y, width, height, fill) {
    grid.text(sprintf("%.1f", heatmap_matrix[i, j]),
              x, y, gp = gpar(fontsize = 8))
  },
  # Legend
  heatmap_legend_param = list(
    title = "Score",
    at = c(0, 1, 2, 3, 4, 5),
    labels = c("0", "1", "2", "3", "4", "5"),
    legend_height = unit(4, "cm")
  ),
  # Title
  column_title = "Top 30 Genes by Multi-Criteria Prioritization Score",
  column_title_gp = gpar(fontsize = 14, fontface = "bold")
)

draw(ht, heatmap_legend_side = "right")

dev.off()

# Also save as PNG
png(file.path(output_dir, "Figure4_GenePrioritization_Heatmap.png"),
    width = 12, height = 10, units = "in", res = 300)
draw(ht, heatmap_legend_side = "right")
dev.off()

cat("Heatmap created and saved separately\n")

# ============================================================================
# Panel D: Tier 1 Genes Details
# ============================================================================

tier1_genes <- prioritization_data %>%
  filter(tier == 1) %>%
  arrange(desc(total_score))

# Create detailed plot for Tier 1 genes
tier1_long <- tier1_genes %>%
  select(gene_symbol, selection_score, relevance_score, tractability_score, literature_score) %>%
  pivot_longer(cols = -gene_symbol, names_to = "criterion", values_to = "score") %>%
  mutate(criterion = factor(gsub("_score", "", criterion),
                            levels = c("selection", "relevance", "tractability", "literature")),
         criterion = tools::toTitleCase(as.character(criterion)))

p_tier1 <- ggplot(tier1_long, aes(x = gene_symbol, y = score, fill = criterion)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  scale_fill_manual(values = c("Selection" = "#E74C3C",
                                 "Relevance" = "#3498DB",
                                 "Tractability" = "#2ECC71",
                                 "Literature" = "#9B59B6")) +
  geom_hline(yintercept = c(1, 2, 3, 4, 5), linetype = "dotted", alpha = 0.3) +
  labs(
    title = "Tier 1 Genes: Detailed Scoring",
    subtitle = "6 genes prioritized for immediate experimental validation",
    x = "",
    y = "Score (0-5)",
    fill = "Criterion"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11, face = "bold"),
    legend.position = "right",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel E: Total Score vs Selection Strength
# ============================================================================

# Add log10p for visualization
prioritization_data$log10p <- -log10(prioritization_data$p_value)

p_scatter <- ggplot(prioritization_data, aes(x = log10p, y = total_score)) +
  # Points colored by tier
  geom_point(aes(color = factor(tier), size = total_score), alpha = 0.6) +
  # Color scale
  scale_color_manual(values = c("1" = "#E74C3C", "2" = "#F39C12", "3" = "#95A5A6"),
                      labels = c("Tier 1 (IMMEDIATE)", "Tier 2 (FOLLOW-UP)", "Tier 3 (EXPLORATORY)"),
                      name = "Priority Tier") +
  # Size scale
  scale_size_continuous(range = c(1, 8), guide = "none") +
  # Tier threshold lines
  geom_hline(yintercept = 16, linetype = "dashed", color = "#E74C3C", size = 1) +
  geom_hline(yintercept = 13, linetype = "dashed", color = "#F39C12", size = 1) +
  # Annotations
  annotate("text", x = max(prioritization_data$log10p) * 0.9, y = 16.5,
           label = "Tier 1 threshold (≥16)", hjust = 1, size = 3.5, fontface = "bold", color = "#E74C3C") +
  annotate("text", x = max(prioritization_data$log10p) * 0.9, y = 13.5,
           label = "Tier 2 threshold (≥13)", hjust = 1, size = 3.5, fontface = "bold", color = "#F39C12") +
  # Label Tier 1 genes
  geom_text_repel(
    data = subset(prioritization_data, tier == 1),
    aes(label = gene_symbol),
    size = 3.5, fontface = "bold",
    box.padding = 0.5, point.padding = 0.3,
    max.overlaps = 20
  ) +
  # Labels
  labs(
    title = "Prioritization Score vs. Selection Strength",
    x = "-log₁₀(p-value)",
    y = "Total Prioritization Score (0-20)"
  ) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = c(0.25, 0.85),
    legend.background = element_rect(fill = "white", color = "black"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Combine Panels (excluding heatmap which is separate)
# ============================================================================

figure4_panels <- (p_tier_dist | p_scores_dist) /
                   p_tier1 /
                   p_scatter +
  plot_layout(heights = c(1.5, 2, 2)) +
  plot_annotation(
    title = "Figure 4: Multi-Criteria Gene Prioritization for Experimental Validation",
    subtitle = "Systematic ranking of 337 genes using selection strength, biological relevance, experimental tractability, and literature support",
    caption = paste0("(A) Distribution of genes across three priority tiers. Tier 1 (n=6): IMMEDIATE validation. Tier 2 (n=47): FOLLOW-UP. Tier 3 (n=284): EXPLORATORY.\n",
                    "(B) Distributions of four scoring criteria across all 337 genes. Each criterion scored 0-5.\n",
                    "(C) Detailed scores for 6 Tier 1 genes: GABRA3 (18.8), EDNRB (17.8), HTR2B (16.2), HCRTR1 (16.2), FZD3 (16.2), FZD4 (16.0).\n",
                    "(D) Total prioritization score vs. selection strength. Tier 1 genes labeled in red.\n",
                    "Note: Heatmap of top 30 genes saved separately (Figure4_GenePrioritization_Heatmap.pdf)"),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      plot.caption = element_text(size = 10, hjust = 0)
    )
  )

# Save combined panels
ggsave(
  filename = file.path(output_dir, "Figure4_GenePrioritization.pdf"),
  plot = figure4_panels,
  width = 16,
  height = 14,
  dpi = 300,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure4_GenePrioritization.png"),
  plot = figure4_panels,
  width = 16,
  height = 14,
  dpi = 300,
  device = "png"
)

# Print summary
cat("\n=== Gene Prioritization Summary ===\n")
cat(sprintf("Total genes prioritized: %d\n", nrow(prioritization_data)))
cat(sprintf("Tier 1 (≥16 points): %d genes (%.1f%%)\n",
            sum(prioritization_data$tier == 1),
            (sum(prioritization_data$tier == 1) / nrow(prioritization_data)) * 100))
cat(sprintf("Tier 2 (13-15.99 points): %d genes (%.1f%%)\n",
            sum(prioritization_data$tier == 2),
            (sum(prioritization_data$tier == 2) / nrow(prioritization_data)) * 100))
cat(sprintf("Tier 3 (<13 points): %d genes (%.1f%%)\n",
            sum(prioritization_data$tier == 3),
            (sum(prioritization_data$tier == 3) / nrow(prioritization_data)) * 100))

cat("\nTier 1 Genes:\n")
print(tier1_genes[, c("gene_symbol", "total_score", "selection_score", "relevance_score",
                       "tractability_score", "literature_score")])

cat("\nFigure 4 created successfully!\n")
cat("Saved to:\n")
cat("  - manuscript/figures/Figure4_GenePrioritization.pdf (panels)\n")
cat("  - manuscript/figures/Figure4_GenePrioritization.png (panels)\n")
cat("  - manuscript/figures/Figure4_GenePrioritization_Heatmap.pdf (heatmap)\n")
cat("  - manuscript/figures/Figure4_GenePrioritization_Heatmap.png (heatmap)\n")
