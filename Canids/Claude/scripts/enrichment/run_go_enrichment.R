#!/usr/bin/env Rscript
# run_go_enrichment.R
# Perform GO term enrichment analysis on genes under selection

library(tidyverse)
library(gprofiler2)
library(argparse)

# Parse arguments
parser <- ArgumentParser(description = 'GO enrichment analysis')
parser$add_argument('--genes', type = 'character', required = TRUE,
                    help = 'File with gene list (one per line) or CSV with gene column')
parser$add_argument('--gene_col', type = 'character', default = 'gene',
                    help = 'Column name for genes if input is CSV')
parser$add_argument('--output', type = 'character', required = TRUE,
                    help = 'Output CSV file for enrichment results')
parser$add_argument('--organism', type = 'character', default = 'hsapiens',
                    help = 'Organism for enrichment (hsapiens, mmusculus, clfamiliaris)')
parser$add_argument('--sources', type = 'character',
                    default = 'GO:BP,GO:MF,GO:CC,KEGG,REAC',
                    help = 'Data sources (comma-separated)')
parser$add_argument('--correction', type = 'character', default = 'fdr',
                    help = 'Multiple testing correction method')
args <- parser$parse_args()

cat("GO enrichment analysis\n")
cat("======================\n\n")

# Load gene list
if (grepl("\\.csv$", args$genes)) {
  cat("Loading genes from CSV:", args$genes, "\n")
  genes_df <- read_csv(args$genes, show_col_types = FALSE)

  if (!(args$gene_col %in% names(genes_df))) {
    cat(sprintf("ERROR: Column '%s' not found in CSV\n", args$gene_col))
    cat("Available columns:", paste(names(genes_df), collapse = ", "), "\n")
    quit(status = 1)
  }

  genes <- genes_df[[args$gene_col]]
} else {
  cat("Loading genes from text file:", args$genes, "\n")
  genes <- readLines(args$genes)
}

# Remove NA and empty strings
genes <- genes[!is.na(genes) & genes != ""]

cat(sprintf("Input genes: %d\n", length(genes)))
cat(sprintf("Organism: %s\n", args$organism))
cat(sprintf("Sources: %s\n", args$sources))
cat("\n")

# Convert sources string to vector
sources <- strsplit(args$sources, ",")[[1]]

# Run gprofiler2
cat("Running gprofiler2...\n")

tryCatch({
  gostres <- gost(
    query = genes,
    organism = args$organism,
    sources = sources,
    correction_method = args$correction,
    evcodes = TRUE,
    significant = FALSE  # Return all results, filter later
  )

  if (is.null(gostres) || is.null(gostres$result)) {
    cat("No enrichment results returned\n")
    quit(status = 0)
  }

  results <- gostres$result

  cat(sprintf("Total terms tested: %d\n", nrow(results)))

  # Filter for significance
  significant <- results %>%
    filter(p_value < 0.05) %>%
    arrange(p_value)

  cat(sprintf("Significant terms (p < 0.05): %d\n", nrow(significant)))

  # Add additional annotations
  results <- results %>%
    mutate(
      log10p = -log10(p_value),
      fold_enrichment = (intersection_size / query_size) / (term_size / effective_domain_size),
      genes_annotated = intersection_size
    )

  # Save full results
  dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
  write_csv(results, args$output)

  cat(sprintf("\nFull results saved: %s\n", args$output))

  # Save significant results separately
  sig_output <- gsub("\\.csv$", "_significant.csv", args$output)
  write_csv(significant, sig_output)

  cat(sprintf("Significant results saved: %s\n", sig_output))

  # Print top enriched terms by source
  cat("\n=== Top Enriched Terms ===\n")

  for (src in unique(significant$source)) {
    top_terms <- significant %>%
      filter(source == src) %>%
      arrange(p_value) %>%
      head(5)

    if (nrow(top_terms) > 0) {
      cat(sprintf("\n%s:\n", src))
      for (i in 1:nrow(top_terms)) {
        term <- top_terms[i, ]
        cat(sprintf("  %s (p=%.2e, %d genes)\n",
                    term$term_name,
                    term$p_value,
                    term$intersection_size))
      }
    }
  }

  # Create summary by source
  summary_by_source <- significant %>%
    group_by(source) %>%
    summarize(
      n_terms = n(),
      min_p = min(p_value),
      median_p = median(p_value)
    ) %>%
    arrange(n_terms)

  cat("\n=== Summary by Source ===\n")
  print(summary_by_source)

  # Generate Manhattan plot data
  manhattan_data <- results %>%
    filter(p_value < 0.1) %>%
    select(source, term_name, p_value, log10p, fold_enrichment, genes_annotated) %>%
    arrange(source, p_value)

  manhattan_file <- gsub("\\.csv$", "_manhattan.csv", args$output)
  write_csv(manhattan_data, manhattan_file)

  cat(sprintf("\nManhattan plot data saved: %s\n", manhattan_file))

  cat("\nDone!\n")

}, error = function(e) {
  cat(sprintf("ERROR running gprofiler2: %s\n", e$message))

  # Check if organism is valid
  cat("\nValid organisms include:\n")
  cat("  hsapiens - Human\n")
  cat("  mmusculus - Mouse\n")
  cat("  clfamiliaris - Dog\n")
  cat("  rnorvegicus - Rat\n")
  cat("\nIf using dog genes, consider mapping to human orthologs first\n")

  quit(status = 1)
})
