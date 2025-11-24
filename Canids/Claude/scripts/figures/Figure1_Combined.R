#!/usr/bin/env Rscript
# Figure 1: Study Design - Combined phylogeny and workflow
# Panel A: Three-species phylogeny
# Panel B: Analysis workflow

library(magick)

# Set output directory
output_dir <- "manuscript/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Load the individual panel images
img_1A <- image_read(file.path(output_dir, "Figure1A_Phylogeny_SIMPLE.png"))
img_1B <- image_read(file.path(output_dir, "Figure1B_Workflow.png"))

# Stack vertically (labels will be added in manuscript)
combined <- image_append(c(img_1A, img_1B), stack = TRUE)

# Save combined figure
image_write(combined,
            path = file.path(output_dir, "Figure1_Combined.png"),
            format = "png", quality = 100, density = 600)

image_write(combined,
            path = file.path(output_dir, "Figure1_Combined.pdf"),
            format = "pdf", density = 600)

cat("\n=== Figure 1 Combined ===\n")
cat("Panel A: Three-species phylogeny (Dog-Dingo-Fox)\n")
cat("Panel B: Analysis workflow (Genomes → Pathways)\n")
cat("Format: 10\" width, stacked vertically\n")
cat("Saved to:\n")
cat("  - manuscript/figures/Figure1_Combined.pdf\n")
cat("  - manuscript/figures/Figure1_Combined.png\n")
