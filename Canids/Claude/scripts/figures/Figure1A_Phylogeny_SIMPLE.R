#!/usr/bin/env Rscript
# Figure 1A: Simple Phylogenetic Tree
# Clean cladogram showing Dog+Dingo clade with Fox outgroup
# Nodes positioned at divergence times

library(ggplot2)
library(ape)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Divergence times (millions of years ago):
# - Fox-Dog divergence: 12 Mya
# - Dog-Dingo split: 0.008 Mya (8,000 years ago)

# Create phylogeny data manually
# Node positions:
# Fox: x=12 (diverged 12 Mya, shown at that point)
# Dog-Dingo ancestor: x=0.008 (split 0.008 Mya)
# Dog: x=0 (present)
# Dingo: x=0 (present)

phylo_data <- data.frame(
  species = c("Fox", "Dingo", "Dog"),
  x = c(12, 0, 0),  # Time before present in Mya
  y = c(1, 3, 2),   # Y positions for layout
  stringsAsFactors = FALSE
)

# Branch data (in millions of years)
branches <- data.frame(
  x_start = c(12, 12, 0.008, 0.008, 0),
  x_end = c(12, 0.008, 0.008, 0, 0),
  y_start = c(1, 2.5, 2.5, 3, 2.5),
  y_end = c(2.5, 2.5, 3, 3, 2)
)

# Create plot
p <- ggplot() +
  # Draw branches
  geom_segment(data = branches,
               aes(x = x_start, xend = x_end, y = y_start, yend = y_end),
               linewidth = 1.5, color = "black") +

  # Add node points
  geom_point(data = phylo_data,
             aes(x = x, y = y),
             size = 4, color = "black") +

  # Add species labels
  geom_text(data = phylo_data,
            aes(x = x, y = y, label = species),
            hjust = -0.2, size = 6, fontface = "italic") +

  # Reverse x-axis for "time before present"
  scale_x_reverse(
    name = "Time (millions of years ago)",
    breaks = seq(0, 12, 2),
    labels = seq(0, 12, 2),
    limits = c(13, -0.5)
  ) +

  # Y axis
  scale_y_continuous(limits = c(0.5, 3.5)) +

  # Theme
  theme_classic() +
  theme(
    plot.margin = margin(10, 40, 10, 10),
    panel.grid.major.x = element_line(color = "gray90", linewidth = 0.5),
    axis.text.y = element_blank(),
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y = element_blank(),
    axis.text.x = element_text(size = 10),
    axis.title.x = element_text(size = 11, face = "bold", margin = margin(t = 10)),
    axis.ticks.x = element_line(),
    axis.line.x = element_line()
  )

# Save figure with better aspect ratio
ggsave(
  filename = file.path(output_dir, "Figure1A_Phylogeny_SIMPLE.pdf"),
  plot = p,
  width = 10,
  height = 4,
  dpi = 600,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure1A_Phylogeny_SIMPLE.png"),
  plot = p,
  width = 10,
  height = 4,
  dpi = 600,
  device = "png"
)

cat("\n=== Simple Phylogeny Complete ===\n")
cat("Clean cladogram with:\n")
cat("  - Fox at 12 Mya (divergence point)\n")
cat("  - Dog and Dingo at 0 Mya (present)\n")
cat("  - Dog-Dingo split visible at ~0.008 Mya\n")
cat("  - Horizontal branch lengths show divergence times\n")
