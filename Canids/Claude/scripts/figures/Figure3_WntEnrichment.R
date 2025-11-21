#!/usr/bin/env Rscript
# Figure 3: Functional Enrichment and Wnt Signaling Pathway
# Bar plot, network diagram, pathway schematic

library(ggplot2)
library(dplyr)
library(patchwork)
library(ggrepel)
library(tidyr)
library(scales)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Load enrichment data
enrichment_file <- "data/enrichment_results/enrichment_results_FULL.tsv"
wnt_file <- "data/enrichment_results/WNT_PATHWAY_GENES.tsv"

if (!file.exists(enrichment_file)) {
  stop("Enrichment file not found: ", enrichment_file)
}

enrichment_data <- read.delim(enrichment_file, header = TRUE, stringsAsFactors = FALSE)
wnt_data <- read.delim(wnt_file, header = TRUE, stringsAsFactors = FALSE)

# ============================================================================
# Panel A: Enriched GO Terms Bar Plot
# ============================================================================

# Prepare enrichment data
enrichment_data$log10p <- -log10(enrichment_data$p_value)
enrichment_data$term_short <- substr(enrichment_data$term_name, 1, 40)

# Highlight Wnt pathway
enrichment_data$highlight <- ifelse(grepl("Wnt", enrichment_data$term_name),
                                     "Wnt pathway", "Other")

# Sort by p-value
enrichment_data <- enrichment_data %>%
  arrange(desc(log10p)) %>%
  mutate(term_short = factor(term_short, levels = term_short))

p_enrichment <- ggplot(enrichment_data,
                       aes(x = log10p, y = term_short, fill = highlight)) +
  geom_bar(stat = "identity", color = "black") +
  # FDR threshold line
  geom_vline(xintercept = -log10(0.05), linetype = "dashed",
             color = "red", size = 1) +
  # Highlight Wnt
  scale_fill_manual(values = c("Wnt pathway" = "#E74C3C",
                                 "Other" = "#3498DB")) +
  # Add gene counts
  geom_text(aes(label = intersection_size), hjust = -0.2, size = 3) +
  # Labels
  labs(
    title = "Enriched Gene Ontology Terms",
    subtitle = "FDR < 0.05 (g:Profiler enrichment analysis)",
    x = "-log₁₀(p-value)",
    y = "",
    fill = ""
  ) +
  # Scales
  scale_x_continuous(expand = expansion(mult = c(0, 0.1))) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 9),
    axis.text.x = element_text(size = 9),
    legend.position = c(0.8, 0.2),
    legend.background = element_rect(fill = "white", color = "black"),
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel B: Wnt Pathway Genes with Selection Statistics
# ============================================================================

# Prepare Wnt genes data
wnt_data$log10p <- -log10(wnt_data$dog_pvalue)

# Sort by p-value
wnt_data <- wnt_data %>%
  arrange(dog_pvalue) %>%
  mutate(gene_symbol = factor(gene_symbol, levels = gene_symbol))

p_wnt_genes <- ggplot(wnt_data, aes(x = dog_omega, y = log10p)) +
  # Points colored by omega
  geom_point(aes(size = log10p, color = dog_omega), alpha = 0.7) +
  # Color gradient for omega
  scale_color_gradient2(low = "blue", mid = "purple", high = "red",
                        midpoint = 1, name = "ω") +
  # Size scale
  scale_size_continuous(range = c(5, 15), guide = "none") +
  # Labels
  geom_text_repel(aes(label = gene_symbol),
                  size = 3.5, fontface = "bold",
                  box.padding = 0.5, point.padding = 0.3,
                  max.overlaps = 20) +
  # Reference lines
  geom_vline(xintercept = 1, linetype = "dashed", alpha = 0.5) +
  geom_hline(yintercept = -log10(1e-10), linetype = "dashed", alpha = 0.5) +
  # Labels
  labs(
    title = "Wnt Pathway Genes Under Selection",
    x = "ω (dN/dS ratio)",
    y = "-log₁₀(p-value)"
  ) +
  # Theme
  theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9),
    legend.position = "right",
    panel.border = element_rect(fill = NA, color = "black", size = 1)
  )

# ============================================================================
# Panel C: Wnt Pathway Schematic
# ============================================================================

# Create pathway schematic data
pathway_nodes <- data.frame(
  x = c(1, 1, 2, 2, 2, 3, 3),
  y = c(3, 1, 3, 2, 1, 2.5, 1.5),
  gene = c("FZD3", "FZD4", "DVL3", "CXXC4", "GSK3B", "LEF1", "SIX3"),
  role = c("Receptor", "Receptor", "Transducer", "Inhibitor", "Regulator",
           "TF", "TF"),
  selected = c("Yes", "Yes", "Yes", "Yes", "No", "Yes", "Yes")
)

pathway_edges <- data.frame(
  x1 = c(1, 1, 2, 2, 2, 2),
  y1 = c(3, 1, 3, 2, 1, 2),
  x2 = c(2, 2, 3, 3, 2, 3),
  y2 = c(3, 1, 2.5, 1.5, 1, 2.5),
  type = c("activate", "activate", "activate", "activate", "inhibit", "activate")
)

p_pathway <- ggplot() +
  # Edges
  geom_segment(data = pathway_edges,
               aes(x = x1, y = y1, xend = x2, yend = y2, linetype = type),
               arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
               size = 1, color = "gray30") +
  # Nodes
  geom_point(data = pathway_nodes,
             aes(x = x, y = y, fill = role, color = selected),
             size = 15, shape = 21, stroke = 2) +
  # Gene labels
  geom_text(data = pathway_nodes,
            aes(x = x, y = y, label = gene),
            size = 3.5, fontface = "bold") +
  # Color scales
  scale_fill_manual(values = c("Receptor" = "#3498DB",
                                 "Transducer" = "#9B59B6",
                                 "Inhibitor" = "#E67E22",
                                 "Regulator" = "#95A5A6",
                                 "TF" = "#E74C3C")) +
  scale_color_manual(values = c("Yes" = "red", "No" = "black"),
                     guide = guide_legend(override.aes = list(size = 5))) +
  scale_linetype_manual(values = c("activate" = "solid", "inhibit" = "dashed")) +
  # Add pathway labels
  annotate("text", x = 1, y = 3.5, label = "Cell Surface",
           size = 4, fontface = "bold") +
  annotate("text", x = 2, y = 3.5, label = "Cytoplasm",
           size = 4, fontface = "bold") +
  annotate("text", x = 3, y = 3.5, label = "Nucleus",
           size = 4, fontface = "bold") +
  # Labels
  labs(
    title = "Wnt Signaling Pathway (Simplified)",
    fill = "Function",
    color = "Under\nSelection",
    linetype = "Interaction"
  ) +
  # Scales
  xlim(0.5, 3.5) +
  ylim(0.5, 4) +
  # Theme
  theme_void() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.position = "right",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Panel D: Neural Crest Hypothesis Schematic
# ============================================================================

# Create flow diagram
flow_data <- data.frame(
  x = c(1, 2, 3, 4),
  y = c(2, 2, 2, 2),
  label = c("Selection for\nTameness",
            "Wnt Pathway\nModulation",
            "Neural Crest\nChanges",
            "Domestication\nSyndrome"),
  color = c("cause", "mechanism", "development", "phenotype")
)

flow_edges <- data.frame(
  x1 = c(1, 2, 3),
  y1 = c(2, 2, 2),
  x2 = c(2, 3, 4),
  y2 = c(2, 2, 2)
)

# Examples of domestication traits
traits_data <- data.frame(
  x = rep(4, 4),
  y = c(2.6, 2.3, 1.7, 1.4),
  label = c("• Floppy ears", "• Piebald coat", "• Shortened muzzle", "• Reduced fear")
)

p_hypothesis <- ggplot() +
  # Flow boxes
  geom_tile(data = flow_data,
            aes(x = x, y = y, fill = color),
            width = 0.7, height = 0.5, color = "black", size = 1) +
  # Flow text
  geom_text(data = flow_data,
            aes(x = x, y = y, label = label),
            size = 3.5, fontface = "bold", lineheight = 0.9) +
  # Arrows
  geom_segment(data = flow_edges,
               aes(x = x1 + 0.35, y = y1, xend = x2 - 0.35, yend = y2),
               arrow = arrow(length = unit(0.3, "cm"), type = "closed"),
               size = 1.5, color = "black") +
  # Trait examples
  geom_text(data = traits_data,
            aes(x = x, y = y, label = label),
            hjust = 0, size = 3, lineheight = 0.9) +
  # Color scale
  scale_fill_manual(values = c("cause" = "#F39C12",
                                 "mechanism" = "#E74C3C",
                                 "development" = "#9B59B6",
                                 "phenotype" = "#3498DB")) +
  # Scales
  xlim(0.5, 5) +
  ylim(1, 3) +
  # Labels
  labs(title = "Neural Crest Hypothesis of Domestication Syndrome") +
  # Theme
  theme_void() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.position = "none",
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Combine All Panels
# ============================================================================

# Layout
figure3 <- (p_enrichment | p_wnt_genes) /
           (p_pathway | p_hypothesis) +
  plot_layout(heights = c(2, 2)) +
  plot_annotation(
    title = "Figure 3: Wnt Signaling Pathway Enrichment and Neural Crest Hypothesis",
    subtitle = "Genomic support for the neural crest hypothesis of domestication syndrome",
    caption = paste0("(A) Enriched GO terms among 337 domestication-selected genes. Wnt signaling pathway highlighted in red (p=0.041).\n",
                    "(B) Seven Wnt pathway genes under strong positive selection (all p<1×10⁻¹⁰). Points colored by ω value.\n",
                    "(C) Simplified Wnt signaling pathway showing selected genes (red outline) across cellular compartments.\n",
                    "(D) Neural crest hypothesis: Selection for tameness → Wnt pathway changes → Neural crest defects → Domestication syndrome traits."),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      plot.caption = element_text(size = 10, hjust = 0)
    )
  )

# Save figure
ggsave(
  filename = file.path(output_dir, "Figure3_WntEnrichment.pdf"),
  plot = figure3,
  width = 16,
  height = 12,
  dpi = 300,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure3_WntEnrichment.png"),
  plot = figure3,
  width = 16,
  height = 12,
  dpi = 300,
  device = "png"
)

# Print summary
cat("\n=== Wnt Pathway Enrichment Summary ===\n")
cat(sprintf("Total enriched GO terms: %d\n", nrow(enrichment_data)))
cat(sprintf("Wnt pathway p-value: %.3e\n",
            enrichment_data$p_value[grepl("Wnt", enrichment_data$term_name)]))
cat(sprintf("Wnt pathway genes: %d\n", nrow(wnt_data)))
cat(sprintf("Core Wnt genes (p<1e-10): %d\n", sum(wnt_data$dog_pvalue < 1e-10)))

cat("\nWnt Pathway Genes:\n")
print(wnt_data[, c("gene_symbol", "dog_pvalue", "dog_omega")])

cat("\nFigure 3 created successfully!\n")
cat("Saved to:\n")
cat("  - manuscript/figures/Figure3_WntEnrichment.pdf\n")
cat("  - manuscript/figures/Figure3_WntEnrichment.png\n")
