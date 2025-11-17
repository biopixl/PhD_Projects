#!/usr/bin/env Rscript
# prune_phylogeny.R
# Prune published Carnivora phylogeny to Canidae species set

library(ape)
library(tidyverse)
library(argparse)

# Parse command line arguments
parser <- ArgumentParser(description = 'Prune phylogeny to Canidae species')
parser$add_argument('--tree', type = 'character', required = TRUE,
                    help = 'Input phylogeny (Newick format)')
parser$add_argument('--species_list', type = 'character', default = 'config/species_list.txt',
                    help = 'File with species to keep (one per line)')
parser$add_argument('--species_map', type = 'character', default = 'config/species_map.tsv',
                    help = 'Species mapping table (for name conversion)')
parser$add_argument('--output', type = 'character', default = 'data/phylogeny/canid_pruned.tre',
                    help = 'Output pruned tree')
parser$add_argument('--format', type = 'character', default = 'newick',
                    help = 'Output format (newick or nexus)')
args <- parser$parse_args()

cat("Loading phylogeny from:", args$tree, "\n")

# Read the tree
tree <- read.tree(args$tree)

cat(sprintf("Original tree: %d tips\n", length(tree$tip.label)))
cat(sprintf("Ultrametric: %s\n", is.ultrametric(tree)))
cat(sprintf("Binary: %s\n", is.binary(tree)))

# Load species list
species_to_keep <- readLines(args$species_list)
cat(sprintf("\nSpecies to retain: %d\n", length(species_to_keep)))

# Load species mapping in case tree uses different naming
species_map <- read_tsv(args$species_map, show_col_types = FALSE)

# Try to match tree tip labels to our species list
# The tree might use underscores, spaces, or different conventions
tree_tips <- tree$tip.label

# Function to try multiple name matching strategies
match_species <- function(tree_tips, target_species, species_map) {
  matched <- c()

  for (sp in target_species) {
    # Try exact match
    if (sp %in% tree_tips) {
      matched <- c(matched, sp)
      next
    }

    # Try with spaces instead of underscores
    sp_space <- gsub("_", " ", sp)
    if (sp_space %in% tree_tips) {
      matched <- c(matched, sp_space)
      next
    }

    # Try with underscores instead of spaces
    sp_underscore <- gsub(" ", "_", sp)
    if (sp_underscore %in% tree_tips) {
      matched <- c(matched, sp_underscore)
      next
    }

    # Try using species map
    map_matches <- species_map %>%
      filter(ncbi_label == sp | scientific_name == sp) %>%
      select(scientific_name, ncbi_label, trait_label) %>%
      gather(key = "type", value = "name") %>%
      pull(name) %>%
      unique()

    found <- intersect(map_matches, tree_tips)
    if (length(found) > 0) {
      matched <- c(matched, found[1])
      next
    }

    cat(sprintf("Warning: Could not match '%s' to tree\n", sp))
  }

  return(matched)
}

species_matched <- match_species(tree_tips, species_to_keep, species_map)

cat(sprintf("Successfully matched: %d species\n", length(species_matched)))

if (length(species_matched) == 0) {
  cat("\nERROR: No species could be matched to the tree!\n")
  cat("Tree tip labels (first 10):\n")
  print(head(tree_tips, 10))
  cat("\nTarget species (first 10):\n")
  print(head(species_to_keep, 10))
  quit(status = 1)
}

# Prune the tree
tips_to_drop <- setdiff(tree_tips, species_matched)
pruned_tree <- drop.tip(tree, tips_to_drop)

cat(sprintf("\nPruned tree: %d tips\n", length(pruned_tree$tip.label)))
cat(sprintf("Ultrametric: %s\n", is.ultrametric(pruned_tree)))

# Check if tree is still ultrametric (within tolerance)
if (!is.ultrametric(pruned_tree)) {
  cat("Warning: Tree is not ultrametric after pruning\n")
  cat("Attempting to force ultrametricity...\n")

  # Sometimes rounding errors cause this - try to fix
  pruned_tree <- chronos(pruned_tree)

  if (is.ultrametric(pruned_tree)) {
    cat("Successfully corrected tree to ultrametric\n")
  } else {
    cat("Warning: Tree still not ultrametric - selection tests may require ultrametric tree\n")
  }
}

# Standardize tip labels to match our ncbi_label convention
tip_map <- tibble(original = pruned_tree$tip.label) %>%
  left_join(
    species_map %>%
      select(scientific_name, ncbi_label) %>%
      mutate(
        name_underscore = gsub(" ", "_", scientific_name),
        name_space = gsub("_", " ", scientific_name)
      ) %>%
      gather(key = "type", value = "original", -ncbi_label) %>%
      distinct(original, ncbi_label),
    by = "original"
  )

# Update tip labels if mapping is available
if (sum(!is.na(tip_map$ncbi_label)) > 0) {
  pruned_tree$tip.label <- ifelse(
    is.na(tip_map$ncbi_label),
    tip_map$original,
    tip_map$ncbi_label
  )
  cat(sprintf("Standardized %d tip labels\n", sum(!is.na(tip_map$ncbi_label))))
}

# Save the pruned tree
dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)

if (args$format == "nexus") {
  write.nexus(pruned_tree, file = args$output)
} else {
  write.tree(pruned_tree, file = args$output)
}

cat(sprintf("\nPruned tree saved: %s\n", args$output))

# Print summary
cat("\nFinal species in tree:\n")
print(sort(pruned_tree$tip.label))

# Calculate basic tree statistics
cat("\nTree statistics:\n")
cat(sprintf("Total branch length: %.2f\n", sum(pruned_tree$edge.length)))
cat(sprintf("Tree height (root to tip): %.2f\n", max(node.depth.edgelength(pruned_tree))))
cat(sprintf("Mean branch length: %.2f\n", mean(pruned_tree$edge.length)))

# Plot the tree to PDF for visual inspection
pdf_path <- gsub("\\.(tre|tree|nwk|newick)$", ".pdf", args$output)
pdf(pdf_path, width = 10, height = 12)
plot(pruned_tree, cex = 0.8, main = "Pruned Canidae Phylogeny")
axisPhylo()
dev.off()
cat(sprintf("Tree plot saved: %s\n", pdf_path))
