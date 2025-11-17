#!/usr/bin/env Rscript
# harmonize_species_names.R
# Create a master species name mapping table to ensure consistency across datasets

library(tidyverse)
library(argparse)

# Parse command line arguments
parser <- ArgumentParser(description = 'Create species name mapping table')
parser$add_argument('--output', type = 'character', default = 'config/species_map.tsv',
                    help = 'Output path for species mapping table')
parser$add_argument('--species_list', type = 'character',
                    help = 'Optional: existing species list to populate')
args <- parser$parse_args()

# Template for Canidae species
# You should expand this based on your actual species set
species_template <- tribble(
  ~scientific_name,      ~ncbi_label,          ~ensembl_label, ~trait_label,      ~common_name,        ~family,
  "Canis lupus",         "Canis_lupus",        "canlup",       "Canis lupus",     "Gray wolf",         "Canidae",
  "Canis familiaris",    "Canis_familiaris",   "canfam",       "Canis familiaris","Domestic dog",      "Canidae",
  "Canis latrans",       "Canis_latrans",      "canlat",       "Canis latrans",   "Coyote",            "Canidae",
  "Canis aureus",        "Canis_aureus",       "canaur",       "Canis aureus",    "Golden jackal",     "Canidae",
  "Canis mesomelas",     "Canis_mesomelas",    "canmes",       "Canis mesomelas", "Black-backed jackal", "Canidae",
  "Canis adustus",       "Canis_adustus",      "canadus",      "Canis adustus",   "Side-striped jackal", "Canidae",
  "Canis simensis",      "Canis_simensis",     "cansim",       "Canis simensis",  "Ethiopian wolf",    "Canidae",
  "Lycaon pictus",       "Lycaon_pictus",      "lycpic",       "Lycaon pictus",   "African wild dog",  "Canidae",
  "Cuon alpinus",        "Cuon_alpinus",       "cuoalp",       "Cuon alpinus",    "Dhole",             "Canidae",
  "Vulpes vulpes",       "Vulpes_vulpes",      "vulvul",       "Vulpes vulpes",   "Red fox",           "Canidae",
  "Vulpes lagopus",      "Vulpes_lagopus",     "vullag",       "Vulpes lagopus",  "Arctic fox",        "Canidae",
  "Vulpes zerda",        "Vulpes_zerda",       "vulzer",       "Vulpes zerda",    "Fennec fox",        "Canidae",
  "Vulpes macrotis",     "Vulpes_macrotis",    "vulmac",       "Vulpes macrotis", "Kit fox",           "Canidae",
  "Vulpes corsac",       "Vulpes_corsac",      "vulcor",       "Vulpes corsac",   "Corsac fox",        "Canidae",
  "Urocyon cinereoargenteus", "Urocyon_cinereoargenteus", "urocin", "Urocyon cinereoargenteus", "Gray fox", "Canidae",
  "Urocyon littoralis",  "Urocyon_littoralis", "urolit",       "Urocyon littoralis", "Island fox",     "Canidae",
  "Nyctereutes procyonoides", "Nyctereutes_procyonoides", "nycpro", "Nyctereutes procyonoides", "Raccoon dog", "Canidae",
  "Otocyon megalotis",   "Otocyon_megalotis",  "otomeg",       "Otocyon megalotis", "Bat-eared fox",   "Canidae",
  "Chrysocyon brachyurus", "Chrysocyon_brachyurus", "chrbra",  "Chrysocyon brachyurus", "Maned wolf",  "Canidae",
  "Speothos venaticus",  "Speothos_venaticus", "speven",       "Speothos venaticus", "Bush dog",       "Canidae"
)

# Add notes column for tracking data source quality
species_template <- species_template %>%
  mutate(
    genome_available = case_when(
      scientific_name %in% c("Canis lupus", "Canis familiaris", "Vulpes vulpes") ~ "high_quality",
      scientific_name %in% c("Lycaon pictus", "Vulpes lagopus", "Cuon alpinus") ~ "available",
      TRUE ~ "check"
    ),
    notes = ""
  )

# Save the mapping table
dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
write_tsv(species_template, args$output)

cat(sprintf("Species mapping table created: %s\n", args$output))
cat(sprintf("Total species: %d\n", nrow(species_template)))
cat("\nNext steps:\n")
cat("1. Verify species names against your genome assemblies\n")
cat("2. Check trait database names and update trait_label column\n")
cat("3. Update genome_available status based on NCBI/Ensembl availability\n")
cat("4. Use this table in all downstream scripts for consistent naming\n")

# Also create a simple species list file for convenience
species_list <- species_template %>%
  pull(ncbi_label)

species_list_path <- file.path(dirname(args$output), "species_list.txt")
writeLines(species_list, species_list_path)
cat(sprintf("\nSimple species list created: %s\n", species_list_path))
