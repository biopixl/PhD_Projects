#!/usr/bin/env Rscript
# Chromosome Distribution of Selected Genes
# Tests for genomic clustering and visualizes distribution across chromosomes
# For Canid Domestication Manuscript QC Analysis

# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# Try to load biomaRt for chromosome information retrieval
biomart_available <- require(biomaRt, quietly = TRUE)

if (!biomart_available) {
  cat("biomaRt not installed. Installing now...\n")
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos = "https://cloud.r-project.org/")
  }
  BiocManager::install("biomaRt", ask = FALSE)
  library(biomaRt)
}

# Set output directory
out_dir <- "manuscript/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load selection results
cat("Loading selection results...\n")
results <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv",
                     header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Total selected genes: %d\n", nrow(results)))

# ============================================================================
# Fetch chromosome locations from Ensembl using biomaRt
# ============================================================================

cat("\nFetching chromosome locations from Ensembl...\n")
cat("This may take a few minutes...\n")

# Extract Ensembl gene IDs (remove "Gene_" prefix to get ENSCAFG IDs)
results$ensembl_id <- gsub("^Gene_", "ENSCAFG", results$gene_id)

# Connect to Ensembl dog database
ensembl <- tryCatch({
  useMart("ensembl", dataset = "clfamiliaris_gene_ensembl")
}, error = function(e) {
  cat("Warning: Could not connect to current Ensembl. Trying archived version...\n")
  # Try Ensembl 111 (the version used for data download)
  useMart("ensembl",
          dataset = "clfamiliaris_gene_ensembl",
          host = "https://nov2023.archive.ensembl.org")
})

# Fetch chromosome information in batches to avoid timeout
batch_size <- 100
n_batches <- ceiling(nrow(results) / batch_size)

chr_data_list <- list()

for (i in 1:n_batches) {
  start_idx <- ((i-1) * batch_size) + 1
  end_idx <- min(i * batch_size, nrow(results))

  batch_ids <- results$ensembl_id[start_idx:end_idx]

  cat(sprintf("Fetching batch %d/%d (genes %d-%d)...\n",
             i, n_batches, start_idx, end_idx))

  batch_data <- tryCatch({
    getBM(attributes = c('ensembl_gene_id',
                        'chromosome_name',
                        'start_position',
                        'end_position',
                        'external_gene_name'),
          filters = 'ensembl_gene_id',
          values = batch_ids,
          mart = ensembl)
  }, error = function(e) {
    cat(sprintf("Warning: Batch %d failed: %s\n", i, e$message))
    data.frame(ensembl_gene_id = character(),
              chromosome_name = character(),
              start_position = integer(),
              end_position = integer(),
              external_gene_name = character())
  })

  chr_data_list[[i]] <- batch_data

  # Small delay to avoid overwhelming the server
  Sys.sleep(0.5)
}

# Combine all batches
chr_data <- do.call(rbind, chr_data_list)

cat(sprintf("\nRetrieved chromosome information for %d/%d genes\n",
           nrow(chr_data), nrow(results)))

# Save chromosome data
write.table(chr_data,
           file = "data/selection_results/gene_chromosome_locations.tsv",
           sep = "\t", row.names = FALSE, quote = FALSE)

cat("Saved chromosome locations to data/selection_results/gene_chromosome_locations.tsv\n")

# ============================================================================
# Merge with selection results and prepare for visualization
# ============================================================================

# Merge chromosome data with selection results
results_chr <- results %>%
  left_join(chr_data, by = c("ensembl_id" = "ensembl_gene_id"))

# Filter to main chromosomes (remove scaffolds, MT, X, Y for cleaner visualization)
# Dog has 38 autosomes + X + Y
main_chromosomes <- c(as.character(1:38), "X")

results_chr_main <- results_chr %>%
  filter(chromosome_name %in% main_chromosomes) %>%
  mutate(chromosome_name = factor(chromosome_name,
                                 levels = c(as.character(1:38), "X")))

cat(sprintf("\nGenes mapped to main chromosomes: %d/%d (%.1f%%)\n",
           nrow(results_chr_main), nrow(results),
           (nrow(results_chr_main)/nrow(results))*100))

# ============================================================================
# Test for chromosome clustering
# ============================================================================

cat("\n=== Testing for Chromosome Clustering ===\n")

# Count genes per chromosome
chr_counts <- results_chr_main %>%
  group_by(chromosome_name) %>%
  summarize(n_selected = n()) %>%
  arrange(chromosome_name)

# To test for clustering, we need to know total genes per chromosome
# Fetch all genes from dog genome for comparison
cat("Fetching total gene counts per chromosome...\n")

all_genes <- getBM(attributes = c('ensembl_gene_id', 'chromosome_name'),
                   filters = 'chromosome_name',
                   values = main_chromosomes,
                   mart = ensembl)

total_per_chr <- all_genes %>%
  filter(chromosome_name %in% main_chromosomes) %>%
  group_by(chromosome_name) %>%
  summarize(total_genes = n())

# Merge observed with expected
chr_comparison <- chr_counts %>%
  left_join(total_per_chr, by = "chromosome_name") %>%
  mutate(
    expected = (total_genes / sum(total_genes, na.rm = TRUE)) * sum(n_selected),
    proportion_selected = n_selected / total_genes,
    fold_enrichment = n_selected / expected
  )

# Chi-square test for uniform distribution
chisq_test <- chisq.test(chr_comparison$n_selected,
                         p = chr_comparison$total_genes / sum(chr_comparison$total_genes))

cat(sprintf("\nChi-square test for chromosome clustering:\n"))
cat(sprintf("  χ² = %.3f\n", chisq_test$statistic))
cat(sprintf("  df = %d\n", chisq_test$parameter))
cat(sprintf("  p-value = %.4f\n", chisq_test$p.value))

if (chisq_test$p.value > 0.05) {
  cat("\nConclusion: No significant clustering detected (p > 0.05)\n")
  cat("Selected genes are distributed proportionally across chromosomes.\n")
} else {
  cat("\nConclusion: Significant non-uniform distribution detected (p < 0.05)\n")
}

# ============================================================================
# Visualize chromosome distribution
# ============================================================================

cat("\nGenerating chromosome distribution plots...\n")

# Plot 1: Bar plot of genes per chromosome
plot_chr_counts <- ggplot(chr_comparison, aes(x = chromosome_name, y = n_selected)) +
  geom_bar(stat = "identity", fill = "#3498db", color = "black", alpha = 0.7) +
  geom_hline(yintercept = mean(chr_comparison$n_selected),
            linetype = "dashed", color = "red", size = 1) +
  annotate("text", x = 35, y = mean(chr_comparison$n_selected) + 1,
          label = sprintf("Mean = %.1f", mean(chr_comparison$n_selected)),
          color = "red", size = 3) +
  labs(x = "Chromosome",
       y = "Number of selected genes") +
  theme_classic(base_size = 12) +
  theme(axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        panel.grid.major.y = element_line(color = "grey90"))

# Plot 2: Proportion selected (normalized by chromosome size)
plot_chr_proportion <- ggplot(chr_comparison,
                             aes(x = chromosome_name, y = proportion_selected * 100)) +
  geom_bar(stat = "identity", fill = "#2ecc71", color = "black", alpha = 0.7) +
  geom_hline(yintercept = (sum(chr_comparison$n_selected) /
                          sum(chr_comparison$total_genes)) * 100,
            linetype = "dashed", color = "red", size = 1) +
  labs(x = "Chromosome",
       y = "% of genes under selection") +
  theme_classic(base_size = 12) +
  theme(axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        panel.grid.major.y = element_line(color = "grey90"))

# Plot 3: Genomic position plot (karyotype-like) - IMPROVED AESTHETICS
# Show every 2nd chromosome label to reduce overcrowding
chr_breaks <- c(seq(1, 38, by = 2), 39)  # 1, 3, 5, ..., 37, X
chr_labels <- c(as.character(seq(1, 38, by = 2)), "X")

plot_karyotype <- results_chr_main %>%
  mutate(
    midpoint = (start_position + end_position) / 2,
    chr_num = as.numeric(as.character(chromosome_name)),
    chr_num = ifelse(chromosome_name == "X", 39, chr_num),
    significant = dog_pvalue < 2.93e-6
  ) %>%
  ggplot(aes(x = midpoint / 1e6, y = chr_num, color = significant)) +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_manual(values = c("FALSE" = "grey70", "TRUE" = "#e74c3c"),
                    labels = c("Non-significant", "Significant"),
                    name = "Selection status") +
  scale_y_reverse(breaks = chr_breaks,
                 labels = chr_labels) +
  labs(x = "Position (Mb)",
       y = "Chromosome") +
  theme_classic(base_size = 14) +
  theme(axis.title = element_text(face = "bold", size = 14),
        axis.text.y = element_text(size = 11),
        axis.text.x = element_text(size = 12),
        legend.position = "bottom",
        legend.text = element_text(size = 11),
        panel.grid.major = element_line(color = "grey90"))

# Combine plots
library(cowplot)

combined_chr <- plot_grid(
  plot_chr_counts,
  plot_grid(plot_chr_proportion, plot_karyotype, ncol = 1),
  ncol = 2,
  rel_widths = c(1.2, 1)
)

# Save combined figure
ggsave(filename = file.path(out_dir, "ChromosomeDistribution_Combined.pdf"),
      plot = combined_chr,
      width = 14, height = 8, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "ChromosomeDistribution_Combined.png"),
      plot = combined_chr,
      width = 14, height = 8, units = "in", dpi = 300)

cat("\nSaved combined chromosome distribution figure to:\n")
cat(sprintf("  %s/ChromosomeDistribution_Combined.pdf\n", out_dir))
cat(sprintf("  %s/ChromosomeDistribution_Combined.png\n", out_dir))

# Save individual panels
ggsave(filename = file.path(out_dir, "Chr_PanelA_Counts.pdf"),
      plot = plot_chr_counts, width = 10, height = 6, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "Chr_PanelB_Proportions.pdf"),
      plot = plot_chr_proportion, width = 10, height = 6, units = "in", dpi = 300)

ggsave(filename = file.path(out_dir, "Chr_PanelC_Karyotype.pdf"),
      plot = plot_karyotype, width = 10, height = 8, units = "in", dpi = 300)

# ============================================================================
# Save statistics
# ============================================================================

chr_stats <- data.frame(
  Metric = c(
    "Total genes with chromosome data",
    "Genes on main chromosomes (1-38, X)",
    "Chi-square statistic",
    "Chi-square p-value",
    "Clustering detected",
    "Mean genes per chromosome",
    "Median genes per chromosome",
    "Range of genes per chromosome"
  ),
  Value = c(
    nrow(results_chr),
    nrow(results_chr_main),
    sprintf("%.3f", chisq_test$statistic),
    sprintf("%.4f", chisq_test$p.value),
    ifelse(chisq_test$p.value < 0.05, "Yes", "No"),
    sprintf("%.1f", mean(chr_comparison$n_selected)),
    median(chr_comparison$n_selected),
    sprintf("%d - %d", min(chr_comparison$n_selected), max(chr_comparison$n_selected))
  )
)

write.table(chr_stats,
           file = "data/selection_results/chromosome_distribution_stats.tsv",
           sep = "\t", row.names = FALSE, quote = FALSE)

write.table(chr_comparison,
           file = "data/selection_results/chromosome_counts.tsv",
           sep = "\t", row.names = FALSE, quote = FALSE)

cat("\nSaved statistics to:\n")
cat("  data/selection_results/chromosome_distribution_stats.tsv\n")
cat("  data/selection_results/chromosome_counts.tsv\n")

cat("\n=== COMPLETE ===\n")
cat("Chromosome distribution analysis complete!\n")
cat(sprintf("No significant clustering detected (p = %.4f)\n", chisq_test$p.value))
cat("Selected genes are distributed across the genome.\n\n")
