#!/usr/bin/env Rscript
# Figure 1A: Phylogenetic Tree with Log-Scale Timeline
# Publication-quality cladogram showing Dog+Dingo clade with Fox outgroup

library(ggplot2)
library(ggtree)
library(ape)
library(tidytree)
library(ggrepel)
library(scales)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ============================================================================
# Create Phylogenetic Tree with Proper Branch Lengths (Log-scale compatible)
# ============================================================================

# Divergence times (years ago):
# - Dog-Fox split: 12 million years ago (12,000,000 ya)
# - Dog-Dingo split: 8,000 years ago (domestication)
# - Modern breeds: ~200 years ago

# For log-scale visualization, we use years ago directly
# Branch lengths are in millions of years for cleaner visualization

# Create tree with proper topology: ((Dog, Dingo), Fox)
# Branch lengths approximate actual divergence times
tree_string <- "((Dog:0.008,Dingo:0.008):11.992,Fox:12):0;"
tree <- read.tree(text = tree_string)

# Get tree data
tree_data <- fortify(tree)

# Add node labels and information
tree_data$label_display <- tree_data$label
tree_data$label_display[is.na(tree_data$label)] <- ""

# Add time points (millions of years ago from root)
tree_data$time_mya <- 12 - tree_data$x

# ============================================================================
# Create Enhanced Cladogram with Integrated Timeline
# ============================================================================

# Base colors
color_dog <- "#E74C3C"      # Red for dog (test lineage)
color_dingo <- "#3498DB"    # Blue for dingo (control)
color_fox <- "#95A5A6"      # Gray for fox (outgroup)
color_clade <- "#9B59B6"    # Purple for clade

# Create the tree plot
p_tree <- ggtree(tree, size = 2, color = "black") +
  # Highlight the Dog+Dingo clade
  geom_hilight(node = 4, fill = color_clade, alpha = 0.15, extend = 0.0015) +

  # Add clade bracket for Dog+Dingo
  geom_cladelab(node = 4, label = "Canis lupus",
                offset = 0.0018, barsize = 2,
                fontsize = 5, fontface = "italic",
                align = TRUE, color = "black") +

  # Add tip labels with colors
  geom_tiplab(aes(label = label),
              size = 6, fontface = "bold.italic",
              offset = 0.0003) +

  # Add tip points colored by species
  geom_tippoint(aes(color = label), size = 8, alpha = 0.8) +
  scale_color_manual(values = c("Dog" = color_dog,
                                  "Dingo" = color_dingo,
                                  "Fox" = color_fox),
                      guide = "none") +

  # Extend x-axis for labels
  xlim(0, 0.018) +

  theme_tree2(bgcolor = "white") +
  theme(
    plot.margin = margin(20, 20, 20, 20),
    panel.grid.major.x = element_line(color = "gray90", size = 0.5),
    panel.grid.minor.x = element_line(color = "gray95", size = 0.3),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank()
  )

# ============================================================================
# Add Timeline Annotations with Log Scale
# ============================================================================

# Key evolutionary events
events <- data.frame(
  time_ya = c(12000000, 8000, 200),  # years ago
  time_mya = c(12, 0.008, 0.0002),   # millions of years ago
  event = c("Dog-Fox\ndivergence",
            "Domestication\n(Dog-Dingo split)",
            "Modern breed\nformation"),
  y_pos = c(-0.5, -0.5, -0.5),
  color = c(color_fox, color_clade, color_dog)
)

# Add timeline as a separate ggplot layer
p_timeline_axis <- ggplot() +
  # Timeline axis
  geom_segment(aes(x = 0, xend = 12.5, y = 0, yend = 0),
               arrow = arrow(length = unit(0.3, "cm"), type = "closed"),
               size = 1.2, color = "black") +

  # Event points
  geom_point(data = events,
             aes(x = time_mya, y = y_pos, color = color),
             size = 8, alpha = 0.8) +
  scale_color_identity() +

  # Event labels
  geom_text_repel(data = events,
                  aes(x = time_mya, y = y_pos, label = event),
                  size = 3.5, fontface = "bold",
                  nudge_y = -0.3,
                  box.padding = 0.5,
                  segment.color = "gray50",
                  segment.size = 0.5) +

  # Time scale markers
  geom_point(data = data.frame(x = c(12, 10, 1, 0.1, 0.01, 0.001)),
             aes(x = x, y = 0.15),
             size = 2, color = "black") +
  geom_text(data = data.frame(x = c(12, 10, 1, 0.1, 0.01, 0.001),
                               label = c("12 Mya", "10 Mya", "1 Mya",
                                        "100 kya", "10 kya", "1 kya")),
            aes(x = x, y = 0.3, label = label),
            size = 3, angle = 45, hjust = 0, vjust = 0) +

  # Axis label
  annotate("text", x = 6, y = -1.3,
           label = "Time before present (log scale)",
           size = 5, fontface = "bold") +

  # Log scale transformation
  scale_x_log10(
    limits = c(0.0005, 15),
    breaks = c(0.001, 0.01, 0.1, 1, 10),
    labels = trans_format("log10", math_format(10^.x))
  ) +

  ylim(-1.5, 0.5) +

  theme_void() +
  theme(
    plot.margin = margin(10, 20, 20, 20),
    panel.background = element_rect(fill = "white", color = NA),
    axis.text.x = element_text(size = 9, angle = 45, hjust = 1)
  )

# ============================================================================
# Add Annotations for Test Branch
# ============================================================================

p_tree_annotated <- p_tree +
  # Test branch annotation (Dog)
  annotate("segment", x = 0.012, xend = 0.0145,
           y = 3, yend = 3,
           arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
           color = color_dog, size = 1.5) +
  annotate("text", x = 0.015, y = 3,
           label = "TEST BRANCH\n(Selection tested here)",
           color = color_dog, size = 4, fontface = "bold",
           hjust = 0) +

  # Control annotation (Dingo)
  annotate("segment", x = 0.012, xend = 0.0145,
           y = 2, yend = 2,
           arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
           color = color_dingo, size = 1.5) +
  annotate("text", x = 0.015, y = 2,
           label = "CONTROL\n(Ancient domesticate)",
           color = color_dingo, size = 4, fontface = "bold",
           hjust = 0) +

  # Outgroup annotation (Fox)
  annotate("segment", x = 0.012, xend = 0.0145,
           y = 1, yend = 1,
           arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
           color = color_fox, size = 1.5) +
  annotate("text", x = 0.015, y = 1,
           label = "OUTGROUP\n(Wild canid)",
           color = color_fox, size = 4, fontface = "bold",
           hjust = 0) +

  # Title
  ggtitle("Three-Species Phylogenetic Design with Log-Scale Timeline") +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5,
                              margin = margin(b = 15))
  )

# ============================================================================
# Combine Tree and Timeline
# ============================================================================

library(patchwork)

p_combined <- p_tree_annotated / p_timeline_axis +
  plot_layout(heights = c(3, 1)) +
  plot_annotation(
    caption = paste0(
      "Phylogenetic relationships of the three study species. ",
      "Dog (Canis lupus familiaris) and Dingo (C. l. dingo) form a monophyletic clade within Canis lupus, ",
      "with Red Fox (Vulpes vulpes) as outgroup. Timeline shows major divergence events on a log scale: ",
      "Dog-Fox split (~12 Mya), domestication event creating Dog-Dingo split (~8 kya), ",
      "and modern breed formation (~200 ya). Selection is tested exclusively on the dog branch (red)."
    ),
    theme = theme(
      plot.caption = element_text(size = 9, hjust = 0, margin = margin(t = 10))
    )
  )

# ============================================================================
# Save Figure
# ============================================================================

ggsave(
  filename = file.path(output_dir, "Figure1A_Phylogeny_Timeline_IMPROVED.pdf"),
  plot = p_combined,
  width = 14,
  height = 10,
  dpi = 600,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure1A_Phylogeny_Timeline_IMPROVED.png"),
  plot = p_combined,
  width = 14,
  height = 10,
  dpi = 600,
  device = "png"
)

cat("\n=== Figure 1A IMPROVED Complete ===\n")
cat("Saved to:\n")
cat("  - manuscript/figures/Figure1A_Phylogeny_Timeline_IMPROVED.pdf\n")
cat("  - manuscript/figures/Figure1A_Phylogeny_Timeline_IMPROVED.png\n")
cat("\nKey improvements:\n")
cat("  - Proper cladogram showing Dog+Dingo clade with Fox as outgroup\n")
cat("  - Log-scale timeline integrated below tree\n")
cat("  - Clear visualization of three major events:\n")
cat("    * Dog-Fox divergence (12 Mya)\n")
cat("    * Domestication/Dog-Dingo split (8 kya)\n")
cat("    * Modern breed formation (200 ya)\n")
cat("  - Color-coded species roles (Test, Control, Outgroup)\n")
cat("  - Publication-quality aesthetics\n")
