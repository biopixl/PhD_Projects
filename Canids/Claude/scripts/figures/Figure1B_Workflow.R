#!/usr/bin/env Rscript
# Figure 1B: Data Acquisition and Analysis Workflow
# Horizontal pipeline showing key steps and metrics

library(ggplot2)
library(grid)
library(gridExtra)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Create horizontal workflow diagram
p <- ggplot() +
  # ============================================================================
  # STEP 1: Genome Data
  # ============================================================================
  annotate("rect", xmin = 0.5, xmax = 2.2, ymin = 1.7, ymax = 3.3,
           fill = "#E8F4F8", color = "black", linewidth = 1) +
  annotate("text", x = 1.35, y = 2.9,
           label = "GENOMES", size = 3.5, fontface = "bold") +
  annotate("text", x = 1.35, y = 2.5,
           label = "Dog, Dingo, Fox", size = 3) +
  annotate("text", x = 1.35, y = 2.1,
           label = "Ensembl v111", size = 2.5, color = "gray30") +

  # Arrow right
  geom_segment(aes(x = 2.2, xend = 2.8, y = 2.5, yend = 2.5),
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 1.2, color = "black") +

  # ============================================================================
  # STEP 2: Ortholog Identification
  # ============================================================================
  annotate("rect", xmin = 2.8, xmax = 4.5, ymin = 1.7, ymax = 3.3,
           fill = "#FFF4E6", color = "black", linewidth = 1) +
  annotate("text", x = 3.65, y = 2.9,
           label = "ORTHOLOGS", size = 3.5, fontface = "bold") +
  annotate("text", x = 3.65, y = 2.5,
           label = "17,078 genes", size = 3, fontface = "bold", color = "#D35400") +
  annotate("text", x = 3.65, y = 2.1,
           label = "1:1:1 mapping", size = 2.5, color = "gray30") +

  # Arrow right
  geom_segment(aes(x = 4.5, xend = 5.1, y = 2.5, yend = 2.5),
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 1.2, color = "black") +

  # ============================================================================
  # STEP 3: Alignment
  # ============================================================================
  annotate("rect", xmin = 5.1, xmax = 6.8, ymin = 1.7, ymax = 3.3,
           fill = "#E8F8F5", color = "black", linewidth = 1) +
  annotate("text", x = 6, y = 2.9,
           label = "ALIGNMENT", size = 3.5, fontface = "bold") +
  annotate("text", x = 6, y = 2.5,
           label = "MAFFT", size = 3) +
  annotate("text", x = 6, y = 2.1,
           label = "Codon-aware", size = 2.5, color = "gray30") +

  # Arrow right
  geom_segment(aes(x = 6.8, xend = 7.4, y = 2.5, yend = 2.5),
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 1.2, color = "black") +

  # ============================================================================
  # STEP 4: Selection Analysis
  # ============================================================================
  annotate("rect", xmin = 7.4, xmax = 9.1, ymin = 1.7, ymax = 3.3,
           fill = "#FCF3CF", color = "black", linewidth = 1) +
  annotate("text", x = 8.25, y = 2.9,
           label = "SELECTION", size = 3.5, fontface = "bold") +
  annotate("text", x = 8.25, y = 2.5,
           label = "aBSREL", size = 3) +
  annotate("text", x = 8.25, y = 2.1,
           label = "Dog branch", size = 2.5, color = "gray30") +

  # Arrow right
  geom_segment(aes(x = 9.1, xend = 9.7, y = 2.5, yend = 2.5),
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 1.2, color = "black") +

  # ============================================================================
  # STEP 5: Results
  # ============================================================================
  annotate("rect", xmin = 9.7, xmax = 11.5, ymin = 1.7, ymax = 3.3,
           fill = "#FADBD8", color = "black", linewidth = 1) +
  annotate("text", x = 10.6, y = 2.9,
           label = "RESULTS", size = 3.5, fontface = "bold") +
  annotate("text", x = 10.6, y = 2.5,
           label = "430 genes", size = 3, fontface = "bold", color = "#C0392B") +
  annotate("text", x = 10.6, y = 2.1,
           label = "FDR < 0.05", size = 2.5, color = "gray30") +

  # Arrow right
  geom_segment(aes(x = 11.5, xend = 12.1, y = 2.5, yend = 2.5),
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 1.2, color = "black") +

  # ============================================================================
  # STEP 6: Enrichment
  # ============================================================================
  annotate("rect", xmin = 12.1, xmax = 13.8, ymin = 1.7, ymax = 3.3,
           fill = "#E8DAEF", color = "black", linewidth = 1) +
  annotate("text", x = 12.95, y = 2.9,
           label = "PATHWAYS", size = 3.5, fontface = "bold") +
  annotate("text", x = 12.95, y = 2.5,
           label = "Wnt signaling", size = 3, fontface = "bold", color = "#7D3C98") +
  annotate("text", x = 12.95, y = 2.1,
           label = "p = 0.041", size = 2.5, color = "gray30") +

  # Set limits and theme
  xlim(0, 14.5) +
  ylim(1, 4) +
  labs(title = "Analysis Workflow") +
  theme_void() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5,
                              margin = margin(b = 10)),
    plot.margin = margin(15, 15, 15, 15)
  )

# Save figure - LANDSCAPE format to match Figure 1A
ggsave(
  filename = file.path(output_dir, "Figure1B_Workflow.pdf"),
  plot = p,
  width = 10,
  height = 4,
  dpi = 600,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure1B_Workflow.png"),
  plot = p,
  width = 10,
  height = 4,
  dpi = 600,
  device = "png"
)

cat("\n=== Figure 1B Workflow Complete ===\n")
cat("Clean workflow diagram with:\n")
cat("  - 6 main analysis steps\n")
cat("  - Key metrics at each stage\n")
cat("  - Visual flow from data to results\n")
cat("  - Minimal text, maximum clarity\n")
