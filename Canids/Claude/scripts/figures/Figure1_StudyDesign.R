#!/usr/bin/env Rscript
# Figure 1: Study Design and Phylogeny
# Three-species comparative design with timeline

library(ggplot2)
library(ggtree)
library(ape)
library(patchwork)
library(cowplot)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ============================================================================
# Panel A: Phylogenetic Tree with Branch Labels
# ============================================================================

# Create phylogenetic tree (Newick format)
tree_string <- "(Fox:12,(Dingo:0.05,Dog:0.05)Domestication:11.95)Root;"
tree <- read.tree(text = tree_string)

# Create tree plot with ggtree
p_tree <- ggtree(tree, size = 1.5) +
  # Add species labels
  geom_tiplab(size = 6, fontface = "italic", offset = 0.5) +
  # Add node labels
  geom_nodelab(aes(label = label), size = 5, hjust = -0.2, vjust = -0.5) +
  # Highlight test branch (Dog)
  geom_hilight(node = 3, fill = "red", alpha = 0.3, extend = 0.5) +
  # Add annotation for test branch
  geom_cladelab(node = 3, label = "TEST BRANCH\n(Selection tested)",
                color = "red", fontsize = 4, offset = 2, barsize = 1.5) +
  # Add annotation for control branch
  geom_cladelab(node = 2, label = "CONTROL",
                color = "blue", fontsize = 4, offset = 7, barsize = 1) +
  # Expand plot limits
  xlim(0, 20) +
  # Add title
  ggtitle("Three-Species Phylogenetic Design") +
  theme_tree2() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Panel B: Timeline and Divergence Events
# ============================================================================

# Create timeline data (using years ago for log scale compatibility)
# Add small offset to avoid log(0) issues
timeline_data <- data.frame(
  event = c("Dog-Fox\ndivergence", "Dog-Dingo\ndivergence", "Modern\nbreeds"),
  time = c(12000000, 8000, 100),  # years ago: 12 Mya, 8 kya, ~100 years (modern breeds)
  time_label = c("~12 Mya", "~8,000 ya", "Modern\nbreeds"),
  y = c(1, 1, 1),
  color = c("outgroup", "control", "test")
)

p_timeline <- ggplot(timeline_data, aes(x = time, y = y)) +
  # Event points
  geom_point(aes(color = color), size = 10, alpha = 0.8) +
  # Event labels
  geom_text(aes(label = event), vjust = -1.8, size = 4.5, fontface = "bold") +
  # Time labels
  geom_text(aes(label = time_label), vjust = 2.8, size = 4, fontface = "bold") +
  # Color scale
  scale_color_manual(values = c("outgroup" = "gray40",
                                  "control" = "#4ECDC4",
                                  "test" = "#FF6B6B")) +
  # Add vertical lines at events
  geom_vline(xintercept = c(12000000, 8000, 100), linetype = "dashed",
             alpha = 0.3, size = 0.8) +
  # LOG SCALE x-axis (time flows right to left, past to present)
  scale_x_log10(
    breaks = c(100, 1000, 10000, 100000, 1000000, 10000000),
    labels = c("100 ya", "1 kya", "10 kya", "100 kya", "1 Mya", "10 Mya"),
    limits = c(50, 20000000)
  ) +
  ylim(0.4, 1.6) +
  labs(
    title = "Evolutionary Timeline (Log Scale)",
    x = "Time before present (years ago, log scale)",
    y = ""
  ) +
  annotation_logticks(sides = "b") +  # Add log scale ticks
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title.x = element_text(size = 11, face = "bold"),
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_line(color = "gray90", size = 0.3),
    legend.position = "none",
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Panel C: Study Design Schematic - IMPROVED
# ============================================================================

# Using a cleaner design with properly connected arrows
p_schematic <- ggplot() +
  # COLUMN 1: Species boxes
  annotate("rect", xmin = 0.5, xmax = 1.9, ymin = 2.7, ymax = 3.3,
           fill = "#FF6B6B", color = "black", size = 1.2, alpha = 0.7) +
  annotate("text", x = 1.2, y = 3,
           label = "Dog\n(Modern breeds)", size = 3.8, fontface = "bold") +

  annotate("rect", xmin = 0.5, xmax = 1.9, ymin = 1.7, ymax = 2.3,
           fill = "#4ECDC4", color = "black", size = 1.2, alpha = 0.7) +
  annotate("text", x = 1.2, y = 2,
           label = "Dingo\n(Ancient)", size = 3.8, fontface = "bold") +

  annotate("rect", xmin = 0.5, xmax = 1.9, ymin = 0.7, ymax = 1.3,
           fill = "#95A5A6", color = "black", size = 1.2, alpha = 0.7) +
  annotate("text", x = 1.2, y = 1,
           label = "Fox\n(Wild)", size = 3.8, fontface = "bold") +

  # ARROWS from species to selective context
  geom_curve(aes(x = 1.9, y = 3, xend = 2.6, yend = 3),
             arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
             curvature = 0, size = 1.2, color = "black") +
  geom_curve(aes(x = 1.9, y = 2, xend = 2.6, yend = 2),
             arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
             curvature = 0, size = 1.2, color = "black") +
  geom_curve(aes(x = 1.9, y = 1, xend = 2.6, yend = 1),
             arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
             curvature = 0, size = 1.2, color = "black") +

  # COLUMN 2: Selective context boxes
  annotate("rect", xmin = 2.6, xmax = 4.2, ymin = 2.7, ymax = 3.3,
           fill = "#FFE5E5", color = "black", size = 1.2) +
  annotate("text", x = 3.4, y = 3,
           label = "Artificial selection\nBreed formation", size = 3.5, fontface = "bold") +

  annotate("rect", xmin = 2.6, xmax = 4.2, ymin = 1.7, ymax = 2.3,
           fill = "#E0F7F4", color = "black", size = 1.2) +
  annotate("text", x = 3.4, y = 2,
           label = "Ancient domestication\nNo breed selection", size = 3.5, fontface = "bold") +

  annotate("rect", xmin = 2.6, xmax = 4.2, ymin = 0.7, ymax = 1.3,
           fill = "#F0F0F0", color = "black", size = 1.2) +
  annotate("text", x = 3.4, y = 1,
           label = "Wild canid\nNo domestication", size = 3.5, fontface = "bold") +

  # ARROWS from selective context to results (converging)
  geom_curve(aes(x = 4.2, y = 3, xend = 4.8, yend = 2.3),
             arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
             curvature = -0.3, size = 1.2, color = "black") +
  geom_curve(aes(x = 4.2, y = 2, xend = 4.8, yend = 2.1),
             arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
             curvature = 0.1, size = 1.2, color = "black") +
  geom_curve(aes(x = 4.2, y = 1, xend = 4.8, yend = 1.7),
             arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
             curvature = 0.3, size = 1.2, color = "black") +

  # COLUMN 3: Results box
  annotate("rect", xmin = 4.8, xmax = 6.4, ymin = 1.5, ymax = 2.5,
           fill = "#FFA726", color = "black", size = 1.5, alpha = 0.8) +
  annotate("text", x = 5.6, y = 2.15,
           label = "430 genes under\ndog-specific selection", size = 4.2, fontface = "bold") +
  annotate("text", x = 5.6, y = 1.75,
           label = "Wnt pathway enriched\n(p = 0.041)", size = 3.8, fontface = "bold",
           color = "darkred") +

  # Set limits and theme
  xlim(0, 7) +
  ylim(0.5, 3.5) +
  labs(title = "Study Design Overview") +
  theme_void() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.margin = margin(15, 15, 15, 15)
  )

# ============================================================================
# Panel D: Key Statistics
# ============================================================================

# Create statistics data
stats_data <- data.frame(
  metric = c("Genes analyzed", "Dog-specific selected", "Annotation success",
             "Wnt pathway enrichment", "Tier 1 validation genes"),
  value = c("17,046", "430 (2.5%)", "337 (78.4%)", "p = 0.041", "6 genes"),
  y = c(5, 4, 3, 2, 1)
)

p_stats <- ggplot(stats_data, aes(x = 1, y = y)) +
  geom_tile(width = 2, height = 0.8, fill = "white", color = "black", size = 1) +
  geom_text(aes(label = paste0(metric, ": ", value)),
            size = 4, fontface = "bold", hjust = 0.5) +
  xlim(0, 2) +
  ylim(0, 6) +
  labs(title = "Key Results Summary") +
  theme_void() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.margin = margin(10, 10, 10, 10)
  )

# ============================================================================
# Combine All Panels
# ============================================================================

# Combine using patchwork
figure1 <- (p_tree | p_timeline) / (p_schematic | p_stats) +
  plot_annotation(
    title = "Figure 1: Study Design and Three-Species Phylogenetic Approach",
    subtitle = "Isolating domestication-specific selection in modern dog breeds",
    caption = paste0("(A) Phylogenetic tree showing three-species design. Dog branch (red) is the test branch where selection is tested.\n",
                    "(B) Evolutionary timeline from dog-fox divergence (~12 Mya) to present.\n",
                    "(C) Study design schematic showing species, selective pressures, and key findings.\n",
                    "(D) Summary of key statistical results."),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      plot.caption = element_text(size = 10, hjust = 0)
    )
  )

# Save figure
ggsave(
  filename = file.path(output_dir, "Figure1_StudyDesign.pdf"),
  plot = figure1,
  width = 14,
  height = 10,
  dpi = 300,
  device = "pdf"
)

ggsave(
  filename = file.path(output_dir, "Figure1_StudyDesign.png"),
  plot = figure1,
  width = 14,
  height = 10,
  dpi = 300,
  device = "png"
)

cat("Figure 1 created successfully!\n")
cat("Saved to:\n")
cat("  - manuscript/figures/Figure1_StudyDesign.pdf\n")
cat("  - manuscript/figures/Figure1_StudyDesign.png\n")
