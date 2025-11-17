#!/usr/bin/env Rscript
# clean_trait_data.R
# Merge and harmonize trait data from multiple sources

library(tidyverse)
library(janitor)
library(argparse)

# Parse command line arguments
parser <- ArgumentParser(description = 'Clean and harmonize trait data')
parser$add_argument('--input', type = 'character', default = 'data/traits_raw/',
                    help = 'Directory containing raw trait CSV files')
parser$add_argument('--species_map', type = 'character', default = 'config/species_map.tsv',
                    help = 'Species name mapping table')
parser$add_argument('--output', type = 'character', default = 'data/traits_clean/canid_traits.tsv',
                    help = 'Output path for harmonized trait table')
args <- parser$parse_args()

# Load species mapping
species_map <- read_tsv(args$species_map, show_col_types = FALSE)

cat("Loading trait data from:", args$input, "\n")

# Function to load and standardize a trait file
load_trait_file <- function(filepath, name_col = "species") {
  df <- read_csv(filepath, show_col_types = FALSE) %>%
    clean_names()

  # Find the species name column (flexible matching)
  possible_name_cols <- c("species", "scientific_name", "name", "binomial", "taxon")
  name_col_found <- intersect(possible_name_cols, names(df))[1]

  if (!is.na(name_col_found)) {
    df <- df %>% rename(species = all_of(name_col_found))
  }

  return(df)
}

# Example: Create template trait dataset
# In practice, you would load actual files from data/traits_raw/
# For now, we create a template with key variables

cat("Creating template trait dataset...\n")
cat("Note: Replace this with actual data loading once you have raw files\n\n")

traits <- species_map %>%
  select(species = scientific_name) %>%
  mutate(
    # SOCIALITY VARIABLES
    pack_size_mean = case_when(
      species %in% c("Canis lupus", "Lycaon pictus", "Cuon alpinus") ~ runif(n(), 5, 15),
      species %in% c("Canis latrans") ~ runif(n(), 2, 6),
      TRUE ~ 1  # Solitary
    ),
    social_structure = case_when(
      species %in% c("Canis lupus", "Lycaon pictus", "Cuon alpinus") ~ "pack",
      species %in% c("Canis latrans", "Vulpes vulpes") ~ "facultative",
      TRUE ~ "solitary"
    ),
    cooperative_hunting = case_when(
      species %in% c("Canis lupus", "Lycaon pictus", "Cuon alpinus") ~ 1,
      TRUE ~ 0
    ),

    # HABITAT/CURSORIALITY VARIABLES
    habitat_openness = case_when(
      species %in% c("Canis lupus", "Lycaon pictus", "Vulpes macrotis") ~ runif(n(), 0.6, 0.9),
      species %in% c("Urocyon cinereoargenteus", "Nyctereutes procyonoides") ~ runif(n(), 0.1, 0.4),
      TRUE ~ runif(n(), 0.3, 0.7)
    ),
    cursoriality_score = case_when(
      species %in% c("Lycaon pictus", "Canis lupus") ~ runif(n(), 0.7, 1.0),
      species %in% c("Vulpes vulpes", "Canis latrans") ~ runif(n(), 0.4, 0.7),
      TRUE ~ runif(n(), 0.2, 0.5)
    ),
    limb_ratio = rnorm(n(), 0.5, 0.1),  # Placeholder - use morphometric data

    # ENVIRONMENTAL VARIABLES
    climate_mean_temp = rnorm(n(), 10, 8),
    climate_aridity_index = runif(n(), 0.2, 0.8),
    elevation_range_m = runif(n(), 500, 3000),

    # DOMESTICATION VARIABLES
    domestication_level = case_when(
      species == "Canis familiaris" ~ 1.0,
      species %in% c("Canis lupus") ~ 0.0,
      TRUE ~ 0.0
    ),
    human_association_score = case_when(
      species == "Canis familiaris" ~ 1.0,
      species %in% c("Vulpes vulpes", "Canis latrans") ~ runif(n(), 0.3, 0.6),
      TRUE ~ runif(n(), 0, 0.3)
    ),

    # LIFE HISTORY (typically from AnAge)
    max_longevity_years = case_when(
      species == "Canis lupus" ~ 20.6,
      species == "Canis familiaris" ~ 24.0,
      species == "Vulpes vulpes" ~ 15.0,
      TRUE ~ runif(n(), 8, 16)
    ),
    body_mass_kg = case_when(
      species == "Canis lupus" ~ runif(n(), 30, 60),
      species == "Vulpes vulpes" ~ runif(n(), 4, 8),
      species == "Lycaon pictus" ~ runif(n(), 18, 30),
      TRUE ~ runif(n(), 3, 25)
    ),

    # DIET
    diet_breadth = runif(n(), 0.3, 0.9),  # 0 = specialist, 1 = generalist
    carnivory_percent = runif(n(), 0.6, 1.0)
  )

# Map to standardized species names
traits <- traits %>%
  left_join(
    species_map %>% select(scientific_name, ncbi_label),
    by = c("species" = "scientific_name")
  ) %>%
  select(species = ncbi_label, everything(), -species) %>%
  arrange(species)

# Create categorical versions for some variables
traits <- traits %>%
  mutate(
    sociality_category = case_when(
      pack_size_mean >= 5 ~ "highly_social",
      pack_size_mean >= 2 ~ "moderately_social",
      TRUE ~ "solitary"
    ),
    habitat_category = case_when(
      habitat_openness >= 0.6 ~ "open",
      habitat_openness <= 0.4 ~ "closed",
      TRUE ~ "mixed"
    ),
    cursorial_category = case_when(
      cursoriality_score >= 0.7 ~ "highly_cursorial",
      cursoriality_score >= 0.4 ~ "moderately_cursorial",
      TRUE ~ "non_cursorial"
    )
  )

# Save cleaned data
dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
write_tsv(traits, args$output)

cat(sprintf("\nHarmonized trait data saved: %s\n", args$output))
cat(sprintf("Species: %d\n", nrow(traits)))
cat(sprintf("Variables: %d\n", ncol(traits)))

# Summary statistics
cat("\nTrait summary:\n")
cat("Sociality distribution:\n")
print(table(traits$sociality_category))

cat("\nHabitat distribution:\n")
print(table(traits$habitat_category))

cat("\nCursoriality distribution:\n")
print(table(traits$cursorial_category))

cat("\nMissing data summary:\n")
missing_summary <- traits %>%
  summarise(across(where(is.numeric), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  filter(n_missing > 0)

if (nrow(missing_summary) > 0) {
  print(missing_summary)
} else {
  cat("No missing data\n")
}

cat("\n=== IMPORTANT ===\n")
cat("This script currently creates TEMPLATE data with random/placeholder values.\n")
cat("You must replace this with actual data loading from:\n")
cat("  - AnAge database\n")
cat("  - PanTHERIA\n")
cat("  - IUCN habitat data\n")
cat("  - Published literature\n")
