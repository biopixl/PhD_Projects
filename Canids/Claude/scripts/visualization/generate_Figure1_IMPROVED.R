#!/usr/bin/env Rscript
# Figure 1 IMPROVED: Study Design - Publication Quality
# Addresses user feedback:
#   1. Combine phylogeny + timeline into single cladogram-style figure
#   2. Make conceptual flowchart standalone with better spacing
#   3. Professional aesthetic with proper arrow connections

library(ggplot2)
library(ggtree)
library(ape)
library(patchwork)
library(cowplot)
library(grid)
library(gridExtra)

# Publication theme
theme_publication <- function(base_size = 12) {
  theme_classic(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 4, hjust = 0.5),
      plot.subtitle = element_text(size = base_size, hjust = 0.5, color = "grey30"),
      axis.title = element_text(face = "bold", size = base_size + 2),
      axis.text = element_text(size = base_size),
      legend.title = element_text(face = "bold", size = base_size),
      legend.text = element_text(size = base_size - 1),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
      plot.margin = margin(15, 15, 15, 15)
    )
}

# Color palette (colorblind-friendly)
col_dog <- "#E69F00"      # Orange
col_dingo <- "#56B4E9"    # Sky Blue
col_fox <- "#999999"      # Grey
col_highlight <- "#D55E00"  # Vermillion

output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  FIGURE 1 GENERATION - Publication Quality Study Design       ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# FIGURE 1A: Combined Phylogeny-Timeline Cladogram
# ============================================================================

cat("█ Generating Figure 1A: Phylogeny-Timeline Cladogram\n")
cat("─────────────────────────────────────────────────────────────────\n")

# Create phylogenetic tree with realistic branch lengths (millions of years)
# Dog-Fox split: ~12 Mya
# Dog-Dingo split: ~8,000 years ago = 0.008 Mya
tree_string <- "(Fox:12,(Dingo:0.008,Dog:0.008)Domestication:11.992)Root;"
tree <- read.tree(text = tree_string)

# Create base tree plot
p_cladogram <- ggtree(tree, size = 1.8) +
  # Species tip labels
  geom_tiplab(size = 6.5, fontface = "italic", offset = 0.3, hjust = 0) +

  # Node labels for divergence events
  geom_nodelab(aes(label = label),
               size = 5, hjust = 1.2, vjust = -0.8,
               fontface = "bold", color = "grey20") +

  # Highlight test branch (Dog) - the branch where selection is tested
  geom_hilight(node = 3, fill = col_dog, alpha = 0.25, extend = 1.5) +

  # Branch annotations with timeline markers
  # Add time markers along branches
  geom_text(aes(x = 6, y = 2.7), label = "~12 Million years ago\nDog-Fox divergence",
            size = 4.5, fontface = "bold", hjust = 0.5, vjust = -0.5) +

  geom_text(aes(x = 11.8, y = 1.5), label = "~8,000 years ago\nDomestication event\n(Dog-Dingo split)",
            size = 4.2, fontface = "bold", hjust = 0.5, vjust = -0.5,
            color = col_dingo) +

  geom_text(aes(x = 12.3, y = 0.8), label = "~200 years ago\nBreed formation\n(TEST BRANCH)",
            size = 4.2, fontface = "bold", hjust = 0, vjust = 0.5,
            color = col_dog) +

  # Add timeline axis at bottom
  scale_x_continuous(
    name = "Time before present (Million years ago)",
    breaks = c(0, 3, 6, 9, 12),
    labels = c("Present", "3 Mya", "6 Mya", "9 Mya", "12 Mya"),
    expand = c(0.02, 0)
  ) +

  # Expand plot area to accommodate labels
  xlim(-1, 16) +

  labs(
    title = "Three-Species Phylogenetic Design with Evolutionary Timeline",
    subtitle = "Isolating breed-specific selection from domestication background"
  ) +

  theme_tree2(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "grey30"),
    axis.title.x = element_text(face = "bold", size = 14, margin = margin(t = 10)),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.line.x = element_line(linewidth = 1.2, color = "black"),
    axis.ticks.x = element_line(linewidth = 1, color = "black"),
    plot.margin = margin(20, 20, 20, 20),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.5, linetype = "dashed")
  )

# Add legend/annotation box explaining the design
legend_box <- data.frame(
  x = c(-0.5, -0.5, -0.5),
  y = c(3.2, 2.7, 2.2),
  label = c(
    "DOG (Canis familiaris): Modern breeds - TEST BRANCH",
    "DINGO (C. l. dingo): Ancient domesticate - CONTROL",
    "FOX (Vulpes vulpes): Wild canid - OUTGROUP"
  ),
  color = c(col_dog, col_dingo, col_fox)
)

p_cladogram <- p_cladogram +
  geom_tile(data = data.frame(x = 7, y = 2.7),
            aes(x = x, y = y), width = 14, height = 1.8,
            fill = "white", color = "black", linewidth = 1.5, alpha = 0.95) +
  geom_text(data = legend_box,
            aes(x = 7, y = y, label = label),
            size = 4.2, hjust = 0.5, fontface = "bold",
            color = legend_box$color)

# Save Figure 1A
ggsave(
  filename = file.path(output_dir, "Figure1A_Phylogeny_Timeline.pdf"),
  plot = p_cladogram,
  width = 16, height = 10, dpi = 600, device = cairo_pdf
)

ggsave(
  filename = file.path(output_dir, "Figure1A_Phylogeny_Timeline.png"),
  plot = p_cladogram,
  width = 16, height = 10, dpi = 600
)

cat("  ✓ Figure 1A saved (16×10 in, 600 DPI)\n")
cat("    - Phylogeny + Timeline combined in cladogram format\n")
cat("    - Clear timeline axis showing deep (12 Mya) to recent (200 ya) events\n\n")

# ============================================================================
# FIGURE 1B: Standalone Conceptual Study Design - PROFESSIONAL REDESIGN
# ============================================================================

cat("█ Generating Figure 1B: Study Design Flowchart (Standalone)\n")
cat("─────────────────────────────────────────────────────────────────\n")

# Create a professional flowchart with better spacing and connections
# Using a grid-based layout system

p_flowchart <- ggplot() +
  # ═══════════════════════════════════════════════════════════════════
  # COLUMN 1: SPECIES (Left side)
  # ═══════════════════════════════════════════════════════════════════

  # Dog box
  annotate("rect", xmin = 1, xmax = 3.5, ymin = 8, ymax = 9.5,
           fill = col_dog, color = "black", linewidth = 2, alpha = 0.85) +
  annotate("text", x = 2.25, y = 8.75,
           label = "Modern Dog Breeds\n(Canis familiaris)",
           size = 6, fontface = "bold", lineheight = 0.9) +

  # Dingo box
  annotate("rect", xmin = 1, xmax = 3.5, ymin = 5, ymax = 6.5,
           fill = col_dingo, color = "black", linewidth = 2, alpha = 0.85) +
  annotate("text", x = 2.25, y = 5.75,
           label = "Ancient Dingo\n(C. lupus dingo)",
           size = 6, fontface = "bold", lineheight = 0.9) +

  # Fox box
  annotate("rect", xmin = 1, xmax = 3.5, ymin = 2, ymax = 3.5,
           fill = col_fox, color = "black", linewidth = 2, alpha = 0.85) +
  annotate("text", x = 2.25, y = 2.75,
           label = "Red Fox\n(Vulpes vulpes)",
           size = 6, fontface = "bold", lineheight = 0.9) +

  # Column 1 header
  annotate("text", x = 2.25, y = 10.5,
           label = "STUDY SPECIES", size = 7, fontface = "bold",
           color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # ARROWS: SPECIES → SELECTION CONTEXT
  # ═══════════════════════════════════════════════════════════════════

  # Arrow 1: Dog → Artificial selection (straight)
  geom_segment(aes(x = 3.5, y = 8.75, xend = 5.2, yend = 8.75),
               arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
               linewidth = 2, color = "black") +

  # Arrow 2: Dingo → Ancient domestication (straight)
  geom_segment(aes(x = 3.5, y = 5.75, xend = 5.2, yend = 5.75),
               arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
               linewidth = 2, color = "black") +

  # Arrow 3: Fox → Wild baseline (straight)
  geom_segment(aes(x = 3.5, y = 2.75, xend = 5.2, yend = 2.75),
               arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
               linewidth = 2, color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # COLUMN 2: SELECTIVE CONTEXT (Middle)
  # ═══════════════════════════════════════════════════════════════════

  # Context 1: Artificial selection
  annotate("rect", xmin = 5.2, xmax = 8.5, ymin = 8, ymax = 9.5,
           fill = "#FFE5E5", color = "black", linewidth = 2) +
  annotate("text", x = 6.85, y = 9,
           label = "ARTIFICIAL SELECTION", size = 5.5, fontface = "bold") +
  annotate("text", x = 6.85, y = 8.5,
           label = "Breed formation\n~200 years", size = 4.5, lineheight = 0.9) +

  # Context 2: Domestication
  annotate("rect", xmin = 5.2, xmax = 8.5, ymin = 5, ymax = 6.5,
           fill = "#E0F7F4", color = "black", linewidth = 2) +
  annotate("text", x = 6.85, y = 6,
           label = "DOMESTICATION", size = 5.5, fontface = "bold") +
  annotate("text", x = 6.85, y = 5.5,
           label = "Ancient (~8,000 ya)\nNo breed selection", size = 4.5, lineheight = 0.9) +

  # Context 3: Wild baseline
  annotate("rect", xmin = 5.2, xmax = 8.5, ymin = 2, ymax = 3.5,
           fill = "#F5F5F5", color = "black", linewidth = 2) +
  annotate("text", x = 6.85, y = 3,
           label = "WILD BASELINE", size = 5.5, fontface = "bold") +
  annotate("text", x = 6.85, y = 2.5,
           label = "Natural selection\nNo human influence", size = 4.5, lineheight = 0.9) +

  # Column 2 header
  annotate("text", x = 6.85, y = 10.5,
           label = "SELECTIVE PRESSURES", size = 7, fontface = "bold",
           color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # ARROWS: SELECTION CONTEXT → ANALYSIS
  # ═══════════════════════════════════════════════════════════════════

  # Converging arrows to analysis box
  geom_curve(aes(x = 8.5, y = 8.75, xend = 10.5, yend = 6.5),
             arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
             linewidth = 2, curvature = -0.3, color = "black") +

  geom_segment(aes(x = 8.5, y = 5.75, xend = 10.5, yend = 5.75),
               arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
               linewidth = 2, color = "black") +

  geom_curve(aes(x = 8.5, y = 2.75, xend = 10.5, yend = 5),
             arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
             linewidth = 2, curvature = 0.3, color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # COLUMN 3: PHYLOGENETIC ANALYSIS (Middle-Right)
  # ═══════════════════════════════════════════════════════════════════

  annotate("rect", xmin = 10.5, xmax = 14.5, ymin = 4.5, ymax = 7,
           fill = "#FFF4E6", color = "black", linewidth = 2.5) +
  annotate("text", x = 12.5, y = 6.5,
           label = "PHYLOGENETIC ANALYSIS", size = 6, fontface = "bold") +
  annotate("text", x = 12.5, y = 6,
           label = "aBSREL (HyPhy)", size = 5, fontface = "bold", color = "grey30") +
  annotate("text", x = 12.5, y = 5.4,
           label = "17,046 orthologous genes\nTest: Dog branch",
           size = 4.5, lineheight = 0.9) +
  annotate("text", x = 12.5, y = 4.8,
           label = "Control: Dingo + Fox", size = 4.5) +

  # Column 3 header
  annotate("text", x = 12.5, y = 10.5,
           label = "METHODS", size = 7, fontface = "bold",
           color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # ARROW: ANALYSIS → RESULTS
  # ═══════════════════════════════════════════════════════════════════

  geom_segment(aes(x = 14.5, y = 5.75, xend = 16, yend = 5.75),
               arrow = arrow(length = unit(0.5, "cm"), type = "closed", angle = 20),
               linewidth = 2, color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # COLUMN 4: KEY FINDINGS (Right side)
  # ═══════════════════════════════════════════════════════════════════

  annotate("rect", xmin = 16, xmax = 20, ymin = 4, ymax = 7.5,
           fill = col_highlight, color = "black", linewidth = 3, alpha = 0.9) +

  annotate("text", x = 18, y = 7.1,
           label = "KEY FINDINGS", size = 6.5, fontface = "bold", color = "white") +

  annotate("text", x = 18, y = 6.5,
           label = "430 genes under\ndog-specific selection",
           size = 5.5, fontface = "bold", color = "white", lineheight = 0.9) +

  annotate("text", x = 18, y = 5.8,
           label = "(2.5% of genome)",
           size = 5, fontface = "bold", color = "white") +

  # Separator line
  geom_segment(aes(x = 16.5, y = 5.5, xend = 19.5, yend = 5.5),
               color = "white", linewidth = 1.5) +

  annotate("text", x = 18, y = 5,
           label = "Wnt signaling pathway",
           size = 5, fontface = "bold", color = "white") +

  annotate("text", x = 18, y = 4.5,
           label = "enriched (p = 0.041)",
           size = 4.8, fontface = "bold", color = "white") +

  # Column 4 header
  annotate("text", x = 18, y = 10.5,
           label = "RESULTS", size = 7, fontface = "bold",
           color = "black") +

  # ═══════════════════════════════════════════════════════════════════
  # OVERALL LAYOUT SETTINGS
  # ═══════════════════════════════════════════════════════════════════

  xlim(0, 21) +
  ylim(1, 11) +

  labs(
    title = "Study Design: Three-Species Comparative Approach",
    subtitle = "Isolating breed-specific selection signals from domestication background using phylogenetic control"
  ) +

  theme_void() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 14, hjust = 0.5, color = "grey30", margin = margin(b = 20)),
    plot.margin = margin(20, 20, 20, 20),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Save Figure 1B
ggsave(
  filename = file.path(output_dir, "Figure1B_StudyDesign_Flowchart.pdf"),
  plot = p_flowchart,
  width = 18, height = 10, dpi = 600, device = cairo_pdf
)

ggsave(
  filename = file.path(output_dir, "Figure1B_StudyDesign_Flowchart.png"),
  plot = p_flowchart,
  width = 18, height = 10, dpi = 600
)

cat("  ✓ Figure 1B saved (18×10 in, 600 DPI)\n")
cat("    - Standalone flowchart with professional spacing\n")
cat("    - Clear arrow connections between components\n")
cat("    - Column-based layout: Species → Pressures → Methods → Results\n\n")

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  FIGURE 1 GENERATION COMPLETE                                 ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Generated publication-quality figures:\n")
cat("  1. Figure1A_Phylogeny_Timeline.pdf/png\n")
cat("     - Combined phylogeny + timeline in cladogram format\n")
cat("     - Timeline axis spanning 12 Mya to present\n")
cat("     - Clear annotation of divergence events\n\n")

cat("  2. Figure1B_StudyDesign_Flowchart.pdf/png\n")
cat("     - Standalone conceptual study design\n")
cat("     - Professional arrow connections and spacing\n")
cat("     - Four-column layout with clear flow\n\n")

cat("Improvements over previous version:\n")
cat("  ✓ Phylogeny and timeline unified (addresses user feedback)\n")
cat("  ✓ Flowchart expanded to standalone figure (better spacing)\n")
cat("  ✓ Professional arrow connections (properly aligned)\n")
cat("  ✓ Colorblind-friendly palette (Okabe-Ito)\n")
cat("  ✓ 600 DPI publication quality\n\n")

cat("Ready for manuscript integration.\n\n")
