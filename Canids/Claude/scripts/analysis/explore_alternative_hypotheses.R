#!/usr/bin/env Rscript
# Explore Alternative Hypotheses and Neural Crest Genes
# Comprehensive analysis of significant genes beyond Wnt/neurotransmitter focus

library(dplyr)
library(tidyr)

# Load data
cat("Loading selection results...\n")
results <- read.delim("data/selection_results/results_3species_dog_only_ANNOTATED.tsv",
                      header = TRUE, stringsAsFactors = FALSE)

cat(sprintf("Total genes: %d\n", nrow(results)))
cat(sprintf("Known genes: %d\n", sum(results$gene_symbol != "Unknown")))

# Calculate Bonferroni threshold
n_tests <- 17046
bonferroni_threshold <- 0.05 / n_tests
cat(sprintf("Bonferroni threshold: p < %.2e\n", bonferroni_threshold))

# Filter for significant genes
sig_genes <- results %>%
  filter(dog_pvalue < bonferroni_threshold,
         gene_symbol != "Unknown") %>%
  arrange(dog_pvalue)

cat(sprintf("\nSignificant known genes: %d\n\n", nrow(sig_genes)))

# ============================================================================
# Define gene sets for alternative hypotheses
# ============================================================================

# Neural crest development genes
neural_crest_keywords <- c(
  "SOX", "SNAI", "TWIST", "PAX3", "PAX7", "FOXD3", "MSX", "DLX",
  "TFAP2", "ZEB", "neural crest", "NC ", "crest cell"
)

# Craniofacial development (overlaps with neural crest)
craniofacial_keywords <- c(
  "cranio", "facial", "skull", "mandib", "maxilla", "jaw", "palat",
  "RUNX2", "MSX", "DLX", "HOXA", "HOXB", "HOXC", "HOXD",
  "BMP", "FGF", "SHH", "WNT"
)

# Pigmentation
pigmentation_keywords <- c(
  "pigment", "melano", "color", "colour", "coat", "tyrosinase", "TYR",
  "MITF", "KIT", "MC1R", "ASIP", "PMEL", "DCT", "TYRP", "OCA",
  "SLC45A2", "SLC24A"
)

# Behavior and temperament
behavior_keywords <- c(
  "behav", "aggress", "fear", "anxiety", "social", "tameness", "docil",
  "serotonin", "dopamine", "oxytocin", "vasopressin", "GABA", "glutamate",
  "HTR", "DRD", "OXTR", "AVPR", "MAOA", "COMT", "SLC6A4",
  "orexin", "HCRTR"
)

# Immune function
immune_keywords <- c(
  "immun", "cytokine", "interleukin", "interferon", "chemokine",
  "MHC", "HLA", "TCR", "BCR", "CD[0-9]", "IL[0-9]", "TNF", "TLR",
  "complement", "antibody", "T cell", "B cell"
)

# Metabolism and growth
metabolism_keywords <- c(
  "metabol", "growth", "IGF", "insulin", "thyroid", "hormone",
  "GH", "GHBP", "STAT", "JAK", "SOCS"
)

# Stress response
stress_keywords <- c(
  "stress", "cortisol", "glucocorticoid", "adrenalin", "CRH", "ACTH",
  "HPA axis", "NR3C"
)

# Cardiovascular/domestication syndrome
cardiac_keywords <- c(
  "heart", "cardiac", "vascular", "endothel", "blood vessel",
  "VEGF", "angiogen"
)

# ============================================================================
# Function to search genes by keywords
# ============================================================================

search_genes <- function(data, keywords, category_name) {
  pattern <- paste(keywords, collapse = "|")
  matches <- data %>%
    filter(grepl(pattern, gene_symbol, ignore.case = TRUE) |
           grepl(pattern, description, ignore.case = TRUE)) %>%
    arrange(dog_pvalue) %>%
    mutate(category = category_name)

  return(matches)
}

# ============================================================================
# Search each category
# ============================================================================

cat("=== SEARCHING GENE CATEGORIES ===\n\n")

neural_crest <- search_genes(sig_genes, neural_crest_keywords, "Neural Crest")
cat(sprintf("Neural Crest: %d genes\n", nrow(neural_crest)))

craniofacial <- search_genes(sig_genes, craniofacial_keywords, "Craniofacial")
cat(sprintf("Craniofacial: %d genes\n", nrow(craniofacial)))

pigmentation <- search_genes(sig_genes, pigmentation_keywords, "Pigmentation")
cat(sprintf("Pigmentation: %d genes\n", nrow(pigmentation)))

behavior <- search_genes(sig_genes, behavior_keywords, "Behavior/Temperament")
cat(sprintf("Behavior/Temperament: %d genes\n", nrow(behavior)))

immune <- search_genes(sig_genes, immune_keywords, "Immune Function")
cat(sprintf("Immune Function: %d genes\n", nrow(immune)))

metabolism <- search_genes(sig_genes, metabolism_keywords, "Metabolism/Growth")
cat(sprintf("Metabolism/Growth: %d genes\n", nrow(metabolism)))

stress <- search_genes(sig_genes, stress_keywords, "Stress Response")
cat(sprintf("Stress Response: %d genes\n", nrow(stress)))

cardiac <- search_genes(sig_genes, cardiac_keywords, "Cardiovascular")
cat(sprintf("Cardiovascular: %d genes\n", nrow(cardiac)))

# ============================================================================
# Combine all categorized genes
# ============================================================================

all_categorized <- bind_rows(
  neural_crest,
  craniofacial,
  pigmentation,
  behavior,
  immune,
  metabolism,
  stress,
  cardiac
)

# ============================================================================
# Find top candidates in each category
# ============================================================================

cat("\n=== TOP CANDIDATES BY CATEGORY ===\n\n")

categories <- unique(all_categorized$category)

for (cat_name in categories) {
  cat(sprintf("\n%s:\n", cat_name))
  cat(sprintf("%s\n", paste(rep("-", nchar(cat_name)), collapse = "")))

  top_genes <- all_categorized %>%
    filter(category == cat_name) %>%
    arrange(dog_pvalue) %>%
    head(10) %>%
    select(gene_symbol, dog_pvalue, dog_omega, description)

  if (nrow(top_genes) > 0) {
    for (i in 1:nrow(top_genes)) {
      cat(sprintf("%d. %s (p=%.2e, ω=%.2f)\n   %s\n",
                  i,
                  top_genes$gene_symbol[i],
                  top_genes$dog_pvalue[i],
                  top_genes$dog_omega[i],
                  substr(top_genes$description[i], 1, 70)))
    }
  } else {
    cat("  No genes found\n")
  }
}

# ============================================================================
# Find genes NOT in our categories (potentially novel)
# ============================================================================

cat("\n\n=== POTENTIALLY NOVEL CANDIDATES ===\n")
cat("(Top 20 significant genes not in predefined categories)\n\n")

novel_genes <- sig_genes %>%
  anti_join(all_categorized, by = "gene_symbol") %>%
  arrange(dog_pvalue) %>%
  head(20) %>%
  select(gene_symbol, dog_pvalue, dog_omega, description)

for (i in 1:nrow(novel_genes)) {
  cat(sprintf("%d. %s (p=%.2e, ω=%.2f)\n   %s\n",
              i,
              novel_genes$gene_symbol[i],
              novel_genes$dog_pvalue[i],
              novel_genes$dog_omega[i],
              substr(novel_genes$description[i], 1, 70)))
}

# ============================================================================
# Save detailed results
# ============================================================================

write.table(all_categorized,
            file = "data/selection_results/categorized_genes_alternative_hypotheses.tsv",
            sep = "\t", row.names = FALSE, quote = FALSE)

write.table(novel_genes,
            file = "data/selection_results/novel_candidate_genes.tsv",
            sep = "\t", row.names = FALSE, quote = FALSE)

# Summary statistics
summary_stats <- all_categorized %>%
  group_by(category) %>%
  summarize(
    n_genes = n(),
    median_pvalue = median(dog_pvalue),
    median_omega = median(dog_omega),
    mean_omega = mean(dog_omega),
    min_pvalue = min(dog_pvalue)
  ) %>%
  arrange(desc(n_genes))

write.table(summary_stats,
            file = "data/selection_results/alternative_hypotheses_summary.tsv",
            sep = "\t", row.names = FALSE, quote = FALSE)

cat("\n\n=== FILES SAVED ===\n")
cat("1. data/selection_results/categorized_genes_alternative_hypotheses.tsv\n")
cat("2. data/selection_results/novel_candidate_genes.tsv\n")
cat("3. data/selection_results/alternative_hypotheses_summary.tsv\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
