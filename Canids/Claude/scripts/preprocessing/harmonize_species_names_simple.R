#!/usr/bin/env Rscript
# harmonize_species_names_simple.R
# Create species mapping without argparse dependency

library(tidyverse)

# Template for Canidae species with genome data availability
species_template <- tribble(
  ~scientific_name,      ~ncbi_label,          ~ensembl_label, ~trait_label,      ~common_name,        ~family,
  "Canis lupus",         "Canis_lupus",        "canlup",       "Canis lupus",     "Gray wolf",         "Canidae",
  "Canis familiaris",    "Canis_familiaris",   "canfam",       "Canis familiaris","Domestic dog",      "Canidae",
  "Canis latrans",       "Canis_latrans",      "canlat",       "Canis latrans",   "Coyote",            "Canidae",
  "Canis aureus",        "Canis_aureus",       "canaur",       "Canis aureus",    "Golden jackal",     "Canidae",
  "Canis mesomelas",     "Canis_mesomelas",    "canmes",       "Canis mesomelas", "Black-backed jackal", "Canidae",
  "Canis simensis",      "Canis_simensis",     "cansim",       "Canis simensis",  "Ethiopian wolf",    "Canidae",
  "Lycaon pictus",       "Lycaon_pictus",      "lycpic",       "Lycaon pictus",   "African wild dog",  "Canidae",
  "Cuon alpinus",        "Cuon_alpinus",       "cuoalp",       "Cuon alpinus",    "Dhole",             "Canidae",
  "Vulpes vulpes",       "Vulpes_vulpes",      "vulvul",       "Vulpes vulpes",   "Red fox",           "Canidae",
  "Vulpes lagopus",      "Vulpes_lagopus",     "vullag",       "Vulpes lagopus",  "Arctic fox",        "Canidae",
  "Vulpes zerda",        "Vulpes_zerda",       "vulzer",       "Vulpes zerda",    "Fennec fox",        "Canidae",
  "Urocyon cinereoargenteus", "Urocyon_cinereoargenteus", "urocin", "Urocyon cinereoargenteus", "Gray fox", "Canidae",
  "Nyctereutes procyonoides", "Nyctereutes_procyonoides", "nycpro", "Nyctereutes procyonoides", "Raccoon dog", "Canidae",
  "Otocyon megalotis",   "Otocyon_megalotis",  "otomeg",       "Otocyon megalotis", "Bat-eared fox",   "Canidae",
  "Chrysocyon brachyurus", "Chrysocyon_brachyurus", "chrbra",  "Chrysocyon brachyurus", "Maned wolf",  "Canidae",
  "Speothos venaticus",  "Speothos_venaticus", "speven",       "Speothos venaticus", "Bush dog",       "Canidae"
)

# Add genome availability and quality info
species_template <- species_template %>%
  mutate(
    genome_status = case_when(
      scientific_name == "Canis familiaris" ~ "chromosome_level",
      scientific_name %in% c("Canis lupus", "Vulpes vulpes", "Vulpes lagopus") ~ "chromosome_level",
      scientific_name %in% c("Lycaon pictus", "Cuon alpinus") ~ "scaffold_level",
      scientific_name %in% c("Canis latrans", "Nyctereutes procyonoides") ~ "scaffold_level",
      TRUE ~ "check_ncbi"
    ),
    priority = case_when(
      scientific_name %in% c("Canis lupus", "Canis familiaris", "Lycaon pictus", "Cuon alpinus") ~ "high",
      scientific_name %in% c("Vulpes vulpes", "Canis latrans") ~ "high",
      TRUE ~ "medium"
    ),
    sociality = case_when(
      scientific_name %in% c("Canis lupus", "Lycaon pictus", "Cuon alpinus") ~ "pack",
      scientific_name %in% c("Canis latrans") ~ "facultative",
      TRUE ~ "solitary"
    ),
    habitat_type = case_when(
      scientific_name %in% c("Lycaon pictus", "Canis lupus") ~ "open",
      scientific_name %in% c("Urocyon cinereoargenteus", "Nyctereutes procyonoides") ~ "forest",
      scientific_name == "Vulpes zerda" ~ "desert",
      scientific_name == "Vulpes lagopus" ~ "arctic",
      TRUE ~ "mixed"
    )
  )

# Save mapping table
dir.create("config", recursive = TRUE, showWarnings = FALSE)
write_tsv(species_template, "config/species_map.tsv")

cat("Species mapping table created: config/species_map.tsv\n")
cat(sprintf("Total species: %d\n", nrow(species_template)))

# Save species list
species_list <- species_template %>%
  pull(ncbi_label)

writeLines(species_list, "config/species_list.txt")
cat(sprintf("Species list created: config/species_list.txt\n"))

# Print summary by trait
cat("\n=== Species Summary ===\n")
cat("\nBy Sociality:\n")
print(table(species_template$sociality))

cat("\nBy Habitat:\n")
print(table(species_template$habitat_type))

cat("\nBy Genome Status:\n")
print(table(species_template$genome_status))

cat("\nBy Priority:\n")
print(table(species_template$priority))

cat("\n=== High Priority Species ===\n")
high_priority <- species_template %>%
  filter(priority == "high") %>%
  select(scientific_name, common_name, genome_status, sociality, habitat_type)

print(high_priority, n = Inf)

cat("\nDone!\n")
