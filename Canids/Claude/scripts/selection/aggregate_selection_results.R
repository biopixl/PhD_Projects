#!/usr/bin/env Rscript
# aggregate_selection_results.R
# Combine selection results across genes and apply FDR correction

library(tidyverse)
library(argparse)

# Parse arguments
parser <- ArgumentParser(description = 'Aggregate selection results and apply FDR correction')
parser$add_argument('--input', type = 'character', required = TRUE,
                    help = 'CSV file from parse_hyphy_results.py')
parser$add_argument('--output', type = 'character', required = TRUE,
                    help = 'Output CSV file for FDR-corrected results')
parser$add_argument('--fdr_threshold', type = 'double', default = 0.1,
                    help = 'FDR threshold for significance (default: 0.1)')
parser$add_argument('--test_type', type = 'character',
                    choices = c('absrel', 'busted', 'relax'),
                    help = 'Type of test (for labeling)')
args <- parser$parse_args()

# Load results
cat("Loading results from:", args$input, "\n")
results <- read_csv(args$input, show_col_types = FALSE)

cat(sprintf("Loaded %d genes\n", nrow(results)))

# Apply FDR correction
if ('pvalue' %in% names(results)) {
  results <- results %>%
    mutate(
      fdr = p.adjust(pvalue, method = "BH"),
      qvalue = p.adjust(pvalue, method = "fdr"),
      significant_fdr = fdr < args$fdr_threshold
    )

  cat(sprintf("\nFDR correction applied (threshold: %.2f)\n", args$fdr_threshold))
  cat(sprintf("Significant genes: %d (%.1f%%)\n",
              sum(results$significant_fdr, na.rm = TRUE),
              100 * mean(results$significant_fdr, na.rm = TRUE)))
} else {
  cat("Warning: No 'pvalue' column found - skipping FDR correction\n")
}

# Add effect size categories if applicable
if ('k_value' %in% names(results)) {
  # RELAX results
  results <- results %>%
    mutate(
      effect_magnitude = case_when(
        abs(log2(k_value)) < 0.5 ~ "weak",
        abs(log2(k_value)) < 1.0 ~ "moderate",
        TRUE ~ "strong"
      ),
      direction = case_when(
        k_value > 1.2 ~ "intensified",
        k_value < 0.8 ~ "relaxed",
        TRUE ~ "neutral"
      )
    )
}

# Sort by significance
if ('fdr' %in% names(results)) {
  results <- results %>% arrange(fdr)
} else if ('pvalue' %in% names(results)) {
  results <- results %>% arrange(pvalue)
}

# Save results
dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
write_csv(results, args$output)

cat(sprintf("\nResults saved: %s\n", args$output))

# Generate summary statistics
cat("\n=== Summary Statistics ===\n")

if ('pvalue' %in% names(results)) {
  cat("\nP-value distribution:\n")
  pval_summary <- results %>%
    summarize(
      min = min(pvalue, na.rm = TRUE),
      q25 = quantile(pvalue, 0.25, na.rm = TRUE),
      median = median(pvalue, na.rm = TRUE),
      q75 = quantile(pvalue, 0.75, na.rm = TRUE),
      max = max(pvalue, na.rm = TRUE)
    )
  print(pval_summary)

  # P-value bins
  cat("\nP-value bins:\n")
  pval_bins <- results %>%
    mutate(bin = cut(pvalue,
                     breaks = c(0, 0.001, 0.01, 0.05, 0.1, 1),
                     labels = c("<0.001", "0.001-0.01", "0.01-0.05", "0.05-0.1", ">0.1"))) %>%
    count(bin) %>%
    mutate(percent = 100 * n / sum(n))
  print(pval_bins)
}

# Test-specific summaries
if ('k_value' %in% names(results)) {
  cat("\nRELAX k-value summary:\n")
  k_summary <- results %>%
    filter(!is.na(k_value) & is.numeric(k_value)) %>%
    summarize(
      mean = mean(k_value),
      median = median(k_value),
      sd = sd(k_value),
      n_intensified = sum(k_value > 1, na.rm = TRUE),
      n_relaxed = sum(k_value < 1, na.rm = TRUE)
    )
  print(k_summary)

  if ('significant_fdr' %in% names(results)) {
    cat("\nSignificant effects:\n")
    sig_effects <- results %>%
      filter(significant_fdr) %>%
      count(direction) %>%
      mutate(percent = 100 * n / sum(n))
    print(sig_effects)
  }
}

if ('evidence_of_selection' %in% names(results)) {
  cat("\nBUSTED results:\n")
  busted_summary <- results %>%
    summarize(
      total = n(),
      with_selection = sum(evidence_of_selection, na.rm = TRUE),
      percent = 100 * mean(evidence_of_selection, na.rm = TRUE)
    )
  print(busted_summary)
}

# Save top significant genes
if ('fdr' %in% names(results) && sum(results$significant_fdr, na.rm = TRUE) > 0) {
  top_genes <- results %>%
    filter(significant_fdr) %>%
    head(20)

  top_file <- gsub("\\.csv$", "_top_genes.txt", args$output)
  writeLines(top_genes$gene, top_file)

  cat(sprintf("\nTop significant genes saved: %s\n", top_file))
  cat("\nTop 10 genes:\n")
  print(top_genes %>% select(gene, pvalue, fdr) %>% head(10))
}

cat("\nDone!\n")
