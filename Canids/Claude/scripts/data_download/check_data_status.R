#!/usr/bin/env Rscript
# check_data_status.R
# Verify all required data files are present and valid

library(tidyverse)
library(ape)

cat("=========================================\n")
cat("Canidae Data Status Check\n")
cat("=========================================\n\n")

# Check directory structure
cat("1. Checking directory structure...\n")
required_dirs <- c(
  "data/genomes",
  "data/annotations",
  "data/cds",
  "data/orthologs",
  "data/phylogeny",
  "data/traits_raw",
  "data/traits_clean",
  "config"
)

all_present <- TRUE
for (dir in required_dirs) {
  if (dir.exists(dir)) {
    cat(sprintf("  ✓ %s\n", dir))
  } else {
    cat(sprintf("  ✗ %s MISSING\n", dir))
    all_present <- FALSE
  }
}

if (!all_present) {
  cat("\nERROR: Some directories are missing\n")
  cat("Run: mkdir -p data/{genomes,annotations,cds,orthologs,phylogeny,traits_raw,traits_clean}\n")
  quit(status = 1)
}

cat("\n2. Checking configuration files...\n")

# Check species mapping
if (file.exists("config/species_map.tsv")) {
  species_map <- read_tsv("config/species_map.tsv", show_col_types = FALSE)
  cat(sprintf("  ✓ species_map.tsv (%d species)\n", nrow(species_map)))

  species_list <- species_map$ncbi_label
} else {
  cat("  ✗ config/species_map.tsv MISSING\n")
  cat("    Run: Rscript scripts/preprocessing/harmonize_species_names_simple.R\n")
  quit(status = 1)
}

cat("\n3. Checking genome data...\n")

# Check genomes
genome_files <- list.files("data/genomes", pattern = "\\.fa$", full.names = FALSE)
n_genomes <- length(genome_files)

if (n_genomes > 0) {
  cat(sprintf("  ✓ Found %d genome files\n", n_genomes))

  # Check file sizes
  for (gf in genome_files) {
    size_mb <- file.size(file.path("data/genomes", gf)) / 1024^2
    cat(sprintf("    - %s (%.1f MB)\n", gf, size_mb))
  }

  # Check which species have genomes
  genome_species <- gsub("\\.fa$", "", genome_files)
  missing_genomes <- setdiff(species_list, genome_species)

  if (length(missing_genomes) > 0) {
    cat(sprintf("\n  ⚠ Missing genomes for %d species:\n", length(missing_genomes)))
    for (sp in head(missing_genomes, 5)) {
      cat(sprintf("    - %s\n", sp))
    }
    if (length(missing_genomes) > 5) {
      cat(sprintf("    ... and %d more\n", length(missing_genomes) - 5))
    }
  }
} else {
  cat("  ✗ No genome files found\n")
  cat("    See DATA_SOURCES.md for download instructions\n")
  cat("    Or run: bash scripts/data_download/download_core_genomes.sh\n")
}

# Check annotations
annot_files <- list.files("data/annotations", pattern = "\\.gff", full.names = FALSE)
n_annot <- length(annot_files)
cat(sprintf("\n  Annotations: %d files\n", n_annot))

# Check CDS
cds_files <- list.files("data/cds", pattern = "\\.fa$", full.names = FALSE)
n_cds <- length(cds_files)
cat(sprintf("  CDS files: %d files\n", n_cds))

cat("\n4. Checking phylogeny...\n")

tree_files <- list.files("data/phylogeny", pattern = "\\.(tre|tree|nwk|newick)$", full.names = TRUE)

if (length(tree_files) > 0) {
  cat(sprintf("  ✓ Found %d tree file(s)\n", length(tree_files)))

  for (tf in tree_files) {
    tryCatch({
      tree <- read.tree(tf)
      cat(sprintf("    - %s: %d tips, ultrametric=%s\n",
                  basename(tf),
                  length(tree$tip.label),
                  is.ultrametric(tree)))

      # Check tip overlap with species list
      overlap <- intersect(tree$tip.label, species_list)
      cat(sprintf("      Overlap with species list: %d/%d\n",
                  length(overlap), length(species_list)))

    }, error = function(e) {
      cat(sprintf("    ✗ %s: Could not read tree\n", basename(tf)))
    })
  }
} else {
  cat("  ⚠ No phylogeny files found\n")
  cat("    A template tree is available: data/phylogeny/canidae_published.tre\n")
  cat("    See DATA_SOURCES.md for downloading published trees\n")
}

cat("\n5. Checking trait data...\n")

trait_files <- list.files("data/traits_raw", pattern = "\\.(csv|txt|tsv)$", full.names = FALSE)
n_traits <- length(trait_files)

if (n_traits > 0) {
  cat(sprintf("  ✓ Found %d trait files\n", n_traits))
  for (tf in trait_files) {
    cat(sprintf("    - %s\n", tf))
  }
} else {
  cat("  ⚠ No trait files found\n")
  cat("    Templates available:\n")
  cat("      - data/traits_raw/social_behavior_template.csv\n")
  cat("      - data/traits_raw/habitat_locomotion_template.csv\n")
  cat("    See DATA_SOURCES.md for data sources\n")
}

# Check cleaned traits
if (file.exists("data/traits_clean/canid_traits.tsv")) {
  traits <- read_tsv("data/traits_clean/canid_traits.tsv", show_col_types = FALSE)
  cat(sprintf("\n  ✓ Harmonized traits: %d species, %d variables\n",
              nrow(traits), ncol(traits)))
} else {
  cat("\n  ⚠ Harmonized trait data not yet created\n")
  cat("    Run: Rscript scripts/preprocessing/clean_trait_data.R\n")
}

cat("\n6. Checking ortholog data...\n")

ortholog_dirs <- list.dirs("data/orthologs", recursive = FALSE, full.names = FALSE)
n_orthologs <- length(ortholog_dirs)

if (n_orthologs > 0) {
  cat(sprintf("  ✓ Found %d ortholog groups\n", n_orthologs))

  # Sample a few to check structure
  sample_dirs <- head(ortholog_dirs, 3)
  for (od in sample_dirs) {
    protein_files <- list.files(file.path("data/orthologs", od),
                                pattern = "protein\\.fa$")
    cds_files <- list.files(file.path("data/orthologs", od),
                           pattern = "cds\\.fa$")

    cat(sprintf("    - %s: protein=%d, cds=%d\n",
                od, length(protein_files), length(cds_files)))
  }

  if (n_orthologs > 3) {
    cat(sprintf("    ... and %d more\n", n_orthologs - 3))
  }
} else {
  cat("  ✗ No ortholog data found\n")
  cat("    Download from Ensembl BioMart (see DATA_SOURCES.md)\n")
  cat("    Then run: python scripts/alignment/extract_cds.py\n")
}

cat("\n=========================================\n")
cat("SUMMARY\n")
cat("=========================================\n\n")

status <- list(
  genomes = n_genomes,
  annotations = n_annot,
  cds = n_cds,
  trees = length(tree_files),
  traits = n_traits,
  orthologs = n_orthologs
)

# Determine readiness
ready_for_analysis <- (
  n_genomes >= 4 &&
  n_cds >= 4 &&
  length(tree_files) >= 1 &&
  n_orthologs >= 100
)

if (ready_for_analysis) {
  cat("✓ READY FOR ANALYSIS\n\n")
  cat("Next steps:\n")
  cat("  1. Run alignment pipeline:\n")
  cat("     snakemake --cores 10 --use-conda\n\n")
} else {
  cat("⚠ NOT READY - Missing data\n\n")
  cat("Required (minimum):\n")
  cat(sprintf("  - Genomes: %d/4\n", n_genomes))
  cat(sprintf("  - CDS files: %d/4\n", n_cds))
  cat(sprintf("  - Phylogeny: %d/1\n", length(tree_files)))
  cat(sprintf("  - Ortholog groups: %d/100\n", n_orthologs))
  cat("\nSee DATA_SOURCES.md and QUICKSTART.md for instructions\n\n")
}

# Print recommended next action
if (n_genomes == 0) {
  cat("RECOMMENDED NEXT ACTION:\n")
  cat("  bash scripts/data_download/download_core_genomes.sh\n\n")
} else if (n_orthologs == 0) {
  cat("RECOMMENDED NEXT ACTION:\n")
  cat("  1. Download ortholog table from Ensembl BioMart\n")
  cat("  2. Run: python scripts/alignment/extract_cds.py \\\n")
  cat("       --orthologs data/orthologs/compara_table.tsv \\\n")
  cat("       --cds_dir data/cds/ \\\n")
  cat("       --out data/orthologs/\n\n")
} else if (length(tree_files) == 0) {
  cat("RECOMMENDED NEXT ACTION:\n")
  cat("  You can use the template tree to get started:\n")
  cat("  cp data/phylogeny/canidae_published.tre data/phylogeny/canid_pruned.tre\n\n")
}

cat("Done!\n")
