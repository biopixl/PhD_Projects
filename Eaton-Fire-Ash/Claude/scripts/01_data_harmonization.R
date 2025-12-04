#!/usr/bin/env Rscript
# =============================================================================
# 01_data_harmonization.R
# Eaton Fire Ash Study - Data Harmonization Pipeline
# =============================================================================

library(tidyverse)
library(sf)
library(readr)

# Set paths
data_dir <- "../Data"
output_dir <- "data"

cat("=== Eaton Fire Ash Data Harmonization ===\n\n")

# -----------------------------------------------------------------------------
# 1. Load ICP-MS Data
# -----------------------------------------------------------------------------
cat("1. Loading ICP-MS data...\n")

icpms <- read_csv(file.path(data_dir, "EFA_ICPMS_PPM.csv"), show_col_types = FALSE)

# Clean column names and extract Base_ID
icpms <- icpms %>%
  rename(Base_ID = EFA.ID) %>%
  mutate(
    Base_ID = as.character(Base_ID),
    Sample_Type = factor(alq.type, levels = c("ASH", "SOIL"))
  ) %>%
  # Standardize coordinate column names
  rename(Latitude = Lat, Longitude = Lon)

cat(sprintf("   Loaded %d samples with %d elements\n", nrow(icpms), ncol(icpms) - 6))

# -----------------------------------------------------------------------------
# 2. Load XRF Data
# -----------------------------------------------------------------------------
cat("2. Loading XRF data...\n")

xrf <- read_csv(file.path(data_dir, "EFA_XRF_%.csv"), show_col_types = FALSE)

# Extract Base_ID from XRF ID format (e.g., "JPL86_bkB.S" -> "JPL86")
xrf <- xrf %>%
  mutate(
    Base_ID = str_extract(EFA.ID, "^[^_]+"),
    Base_ID = ifelse(is.na(Base_ID), EFA.ID, Base_ID)
  ) %>%
  rename(Latitude_xrf = lat, Longitude_xrf = lon)

# Rename XRF element columns to avoid collision with ICP-MS
xrf_elements <- xrf %>%
  select(-EFA.ID, -EFA.ID.XRF, -type, -Latitude_xrf, -Longitude_xrf, -Base_ID) %>%
  names()

xrf <- xrf %>%
  rename_with(~ paste0(.x, "_xrf"), all_of(xrf_elements))

cat(sprintf("   Loaded %d samples with %d XRF measurements\n", nrow(xrf), length(xrf_elements)))

# -----------------------------------------------------------------------------
# 3. Load ASD Spectroscopy Metadata
# -----------------------------------------------------------------------------
cat("3. Loading ASD spectroscopy metadata...\n")

# Unzip and read spectroscopy metadata
asd_zip <- file.path(data_dir, "Field Spectroscopy.zip")
asd_meta <- read_csv(unz(asd_zip, "Eaton Fire Ash Sampling - Spectroscopy Metadata 20250728.csv"),
                     show_col_types = FALSE)

# Extract Base_ID from ASD format (e.g., "JPL06_bkA" -> "JPL06")
asd_meta <- asd_meta %>%
  rename(ASD_ID = EFA.ID) %>%
  mutate(
    Base_ID = str_extract(ASD_ID, "^[^_]+"),
    Base_ID = ifelse(is.na(Base_ID), ASD_ID, Base_ID),
    ASD_Date = as.Date(asd_date, format = "%m/%d/%y")
  ) %>%
  rename(Latitude_asd = latitude, Longitude_asd = longitude)

cat(sprintf("   Loaded %d ASD measurements\n", nrow(asd_meta)))

# -----------------------------------------------------------------------------
# 4. Load ATR-FTIR File List
# -----------------------------------------------------------------------------
cat("4. Scanning ATR-FTIR files...\n")

ftir_files <- list.files(file.path(data_dir, "IR/ATR"), pattern = "\\.SPA$", full.names = FALSE)
ftir_meta <- tibble(
  FTIR_file = ftir_files,
  Base_ID = str_extract(ftir_files, "^[^_]+")
) %>%
  filter(!str_detect(Base_ID, "BLANK|Evident|PBP|pXRF"))

cat(sprintf("   Found %d FTIR spectra\n", nrow(ftir_meta)))

# -----------------------------------------------------------------------------
# 5. Build Master Sample Crosswalk
# -----------------------------------------------------------------------------
cat("5. Building sample crosswalk...\n")

# Get unique Base_IDs from each source
ids_icpms <- unique(icpms$Base_ID)
ids_xrf <- unique(xrf$Base_ID)
ids_asd <- unique(asd_meta$Base_ID)
ids_ftir <- unique(ftir_meta$Base_ID)

# Create crosswalk
all_ids <- unique(c(ids_icpms, ids_xrf, ids_asd, ids_ftir))

crosswalk <- tibble(Base_ID = all_ids) %>%
  mutate(
    has_ICPMS = Base_ID %in% ids_icpms,
    has_XRF = Base_ID %in% ids_xrf,
    has_ASD = Base_ID %in% ids_asd,
    has_FTIR = Base_ID %in% ids_ftir,
    n_datasets = has_ICPMS + has_XRF + has_ASD + has_FTIR,
    Data_Tier = case_when(
      n_datasets == 4 ~ 1L,
      n_datasets >= 2 ~ 2L,
      TRUE ~ 3L
    )
  )

cat("\n   Sample coverage summary:\n")
print(table(crosswalk$n_datasets))
cat(sprintf("\n   TIER 1 (all 4 datasets): %d samples\n", sum(crosswalk$Data_Tier == 1)))
cat(sprintf("   TIER 2 (2-3 datasets): %d samples\n", sum(crosswalk$Data_Tier == 2)))

# -----------------------------------------------------------------------------
# 6. Create Harmonized Master Dataset
# -----------------------------------------------------------------------------
cat("\n6. Creating harmonized master dataset...\n")

# Start with ICP-MS as base (has coordinates and full geochemistry)
df_master <- icpms %>%
  select(Base_ID, Latitude, Longitude, Sample_Type, everything()) %>%
  select(-EFA.ID.XRF, -EFA.ID.ICPMS, -alq.type)

# Join crosswalk info
df_master <- df_master %>%
  left_join(crosswalk %>% select(Base_ID, has_ICPMS, has_XRF, has_ASD, has_FTIR, Data_Tier),
            by = "Base_ID")

# Join XRF major elements (select key oxides)
xrf_subset <- xrf %>%
  select(Base_ID,
         SiO2_pct = Si1O2_xrf,
         Al2O3_pct = Al2O3_xrf,
         Fe2O3_pct = Fe2O3_xrf,
         CaO_pct = Ca1O1_xrf,
         MgO_pct = Mg1O1_xrf,
         Na2O_pct = Na2O1_xrf,
         K2O_pct = K2O1_xrf,
         TiO2_pct = Ti1O2_xrf,
         P2O5_pct = P2O5_xrf,
         MnO_pct = Mn1O2_xrf,
         SO3_pct = S1O3_xrf,
         Pb_xrf = Pb1O1_xrf,
         Zn_xrf = Zn1O1_xrf,
         Cu_xrf = Cu1O1_xrf) %>%
  distinct(Base_ID, .keep_all = TRUE)

df_master <- df_master %>%
  left_join(xrf_subset, by = "Base_ID")

# -----------------------------------------------------------------------------
# 7. Calculate Derived Indices and EPA Exceedances
# -----------------------------------------------------------------------------
cat("7. Calculating derived indices and EPA exceedances...\n")

# EPA Regional Screening Levels (residential soil, mg/kg = ppm)
EPA_RSL <- list(
  Pb = 400,
  As = 0.68,
  Cd = 70,
  Cr = 5.6,  # Cr(VI) - conservative
  Cu = 3100,
  Ni = 1500,
  Zn = 23000,
  Mn = 1800,
  Ba = 15000
)

df_master <- df_master %>%
  mutate(
    # EPA exceedance flags
    Pb_exceed_RSL = Pb > EPA_RSL$Pb,
    As_exceed_RSL = As > EPA_RSL$As,
    Cd_exceed_RSL = Cd > EPA_RSL$Cd,
    Cr_exceed_RSL = Cr > EPA_RSL$Cr,
    Cu_exceed_RSL = Cu > EPA_RSL$Cu,
    Ni_exceed_RSL = Ni > EPA_RSL$Ni,
    Zn_exceed_RSL = Zn > EPA_RSL$Zn,
    Mn_exceed_RSL = Mn > EPA_RSL$Mn,

    # Count exceedances
    N_exceedances = rowSums(across(ends_with("_exceed_RSL")), na.rm = TRUE),

    # Derived ratios
    Ca_Mg_ratio = Ca / (Mg + 0.001),
    Fe_Al_ratio = Fe / (Al + 0.001),
    Si_Al_ratio = ifelse(!is.na(SiO2_pct) & !is.na(Al2O3_pct),
                         SiO2_pct / (Al2O3_pct + 0.001), NA),
    Pb_Zn_ratio = Pb / (Zn + 0.001),

    # Total toxic metals
    Total_Toxics_ppm = Pb + As + Cd + Cr + Ni,

    # Sum of REE (if available)
    Sum_REE_ppm = La + Ce + Pr + Nd + Sm + Eu + Gd,

    # Metal load classification
    Metal_Load_Class = factor(case_when(
      `Sum of Metals` < 100000 ~ "Low",
      `Sum of Metals` < 200000 ~ "Medium",
      `Sum of Metals` < 300000 ~ "High",
      TRUE ~ "Extreme"
    ), levels = c("Low", "Medium", "High", "Extreme"))
  )

# -----------------------------------------------------------------------------
# 8. Create Spatial Features for QGIS
# -----------------------------------------------------------------------------
cat("8. Creating spatial features for QGIS...\n")

# Create sf object
df_master_sf <- df_master %>%
  filter(!is.na(Longitude) & !is.na(Latitude)) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)

# Save as GeoPackage (QGIS-compatible)
st_write(df_master_sf, file.path(output_dir, "eaton_ash_samples.gpkg"),
         layer = "samples", delete_layer = TRUE, quiet = TRUE)

cat("   Saved: data/eaton_ash_samples.gpkg\n")

# Also save as shapefile for compatibility
st_write(df_master_sf, file.path("qgis", "eaton_ash_samples.shp"),
         delete_layer = TRUE, quiet = TRUE)
cat("   Saved: qgis/eaton_ash_samples.shp\n")

# -----------------------------------------------------------------------------
# 9. Save Outputs
# -----------------------------------------------------------------------------
cat("9. Saving output files...\n")

# Save master CSV
write_csv(df_master, file.path(output_dir, "df_master.csv"))
cat("   Saved: data/df_master.csv\n")

# Save crosswalk
write_csv(crosswalk, file.path(output_dir, "sample_crosswalk.csv"))
cat("   Saved: data/sample_crosswalk.csv\n")

# Save ASD metadata with Base_ID
write_csv(asd_meta, file.path(output_dir, "asd_metadata.csv"))
cat("   Saved: data/asd_metadata.csv\n")

# -----------------------------------------------------------------------------
# 10. Summary Statistics
# -----------------------------------------------------------------------------
cat("\n=== SUMMARY ===\n\n")

cat("Master dataset dimensions:", nrow(df_master), "samples x", ncol(df_master), "variables\n\n")

cat("Sample types:\n")
print(table(df_master$Sample_Type))

cat("\nData tier distribution:\n")
print(table(df_master$Data_Tier))

cat("\nEPA RSL Exceedances (ASH samples only):\n")
ash_only <- df_master %>% filter(Sample_Type == "ASH")
exceedance_summary <- tibble(
  Metal = c("Pb", "As", "Cd", "Cr", "Cu", "Ni", "Zn", "Mn"),
  RSL_ppm = c(400, 0.68, 70, 5.6, 3100, 1500, 23000, 1800),
  N_exceed = c(
    sum(ash_only$Pb_exceed_RSL, na.rm = TRUE),
    sum(ash_only$As_exceed_RSL, na.rm = TRUE),
    sum(ash_only$Cd_exceed_RSL, na.rm = TRUE),
    sum(ash_only$Cr_exceed_RSL, na.rm = TRUE),
    sum(ash_only$Cu_exceed_RSL, na.rm = TRUE),
    sum(ash_only$Ni_exceed_RSL, na.rm = TRUE),
    sum(ash_only$Zn_exceed_RSL, na.rm = TRUE),
    sum(ash_only$Mn_exceed_RSL, na.rm = TRUE)
  ),
  Pct_exceed = round(N_exceed / nrow(ash_only) * 100, 1)
)
print(exceedance_summary)

cat("\nKey metal concentration ranges (ASH samples, ppm):\n")
metal_ranges <- ash_only %>%
  summarise(
    across(c(Pb, As, Cd, Cr, Cu, Zn, Ni, Fe, Ca, Mn),
           list(min = ~min(., na.rm = TRUE),
                median = ~median(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  ) %>%
  pivot_longer(everything(), names_to = c("Metal", "Stat"), names_sep = "_") %>%
  pivot_wider(names_from = Stat, values_from = value)
print(metal_ranges)

cat("\n=== Data Harmonization Complete ===\n")
