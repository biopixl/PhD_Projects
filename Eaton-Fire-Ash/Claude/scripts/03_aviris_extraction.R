#!/usr/bin/env Rscript
# =============================================================================
# 03_aviris_extraction.R
# Eaton Fire Ash Study - AVIRIS Product Extraction at Sample Locations
# =============================================================================

library(tidyverse)
library(sf)
library(terra)

cat("=== AVIRIS Product Extraction ===\n\n")

# Set paths
data_dir <- "../Data/AVIRIS"
output_dir <- "data"

# -----------------------------------------------------------------------------
# 1. Load Sample Locations
# -----------------------------------------------------------------------------
cat("1. Loading sample locations...\n")

df_master <- read_csv(file.path(output_dir, "df_master.csv"), show_col_types = FALSE)

# Create spatial points
pts <- df_master %>%
  filter(!is.na(Longitude) & !is.na(Latitude)) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)

cat(sprintf("   Loaded %d sample points\n", nrow(pts)))

# -----------------------------------------------------------------------------
# 2. Load and Extract Charash Fraction
# -----------------------------------------------------------------------------
cat("2. Extracting charash fraction...\n")

charash_file <- file.path(data_dir, "charash/eaton_1_20250111_av3_charash_fraction.tif")

if (file.exists(charash_file)) {
  charash <- rast(charash_file)
  cat(sprintf("   Charash raster: %d x %d pixels, CRS: %s\n",
              ncol(charash), nrow(charash), crs(charash, describe = TRUE)$name))

  # Transform points to raster CRS
  pts_proj <- st_transform(pts, crs(charash))

  # Extract values
  charash_vals <- extract(charash, vect(pts_proj))
  df_master$Charash_fraction <- charash_vals[, 2]

  cat(sprintf("   Extracted charash for %d points (%.0f%% valid)\n",
              nrow(pts), sum(!is.na(df_master$Charash_fraction)) / nrow(pts) * 100))
} else {
  cat("   WARNING: Charash file not found\n")
  df_master$Charash_fraction <- NA
}

# -----------------------------------------------------------------------------
# 3. Load and Extract dNBR
# -----------------------------------------------------------------------------
cat("3. Extracting dNBR (burn severity)...\n")

dnbr_file <- file.path(data_dir, "pcas/COG_Eaton_AV3_provisional_dNBR_866nm_2198nm_20240905-20250116.tif")

if (file.exists(dnbr_file)) {
  dnbr <- rast(dnbr_file)
  cat(sprintf("   dNBR raster: %d x %d pixels\n", ncol(dnbr), nrow(dnbr)))

  pts_proj <- st_transform(pts, crs(dnbr))
  dnbr_vals <- extract(dnbr, vect(pts_proj))
  df_master$dNBR <- dnbr_vals[, 2]

  cat(sprintf("   Extracted dNBR for %d points (%.0f%% valid)\n",
              nrow(pts), sum(!is.na(df_master$dNBR)) / nrow(pts) * 100))
} else {
  cat("   WARNING: dNBR file not found\n")
  df_master$dNBR <- NA
}

# -----------------------------------------------------------------------------
# 4. Load and Extract NBR (Multiple Dates)
# -----------------------------------------------------------------------------
cat("4. Extracting NBR time series...\n")

nbr_files <- list.files(file.path(data_dir, "nbrs"), pattern = "\\.tif$", full.names = TRUE)

if (length(nbr_files) > 0) {
  cat(sprintf("   Found %d NBR files\n", length(nbr_files)))

  # Use the largest file (likely the mosaic)
  nbr_sizes <- file.info(nbr_files)$size
  nbr_main <- nbr_files[which.max(nbr_sizes)]

  nbr <- rast(nbr_main)
  cat(sprintf("   Main NBR raster: %d x %d pixels\n", ncol(nbr), nrow(nbr)))

  pts_proj <- st_transform(pts, crs(nbr))
  nbr_vals <- extract(nbr, vect(pts_proj))

  if (ncol(nbr_vals) > 1) {
    df_master$NBR_postfire <- nbr_vals[, 2]
    cat(sprintf("   Extracted NBR for %d points\n", sum(!is.na(df_master$NBR_postfire))))
  }
} else {
  cat("   WARNING: No NBR files found\n")
  df_master$NBR_postfire <- NA
}

# -----------------------------------------------------------------------------
# 5. Load and Extract PCA Components
# -----------------------------------------------------------------------------
cat("5. Extracting PCA components...\n")

pca_files <- list.files(file.path(data_dir, "pcas"), pattern = "_pca\\.tif$", full.names = TRUE)

if (length(pca_files) > 0) {
  # Use largest PCA file
  pca_sizes <- file.info(pca_files)$size
  pca_main <- pca_files[which.max(pca_sizes)]

  pca <- rast(pca_main)
  n_layers <- nlyr(pca)
  cat(sprintf("   PCA raster: %d layers\n", n_layers))

  pts_proj <- st_transform(pts, crs(pca))
  pca_vals <- extract(pca, vect(pts_proj))

  # Add PC columns (up to 5)
  for (i in 1:min(5, n_layers)) {
    col_name <- paste0("PC", i)
    df_master[[col_name]] <- pca_vals[, i + 1]
  }

  cat(sprintf("   Extracted %d PC components\n", min(5, n_layers)))
} else {
  cat("   WARNING: No PCA files found\n")
}

# -----------------------------------------------------------------------------
# 6. Calculate Burn Severity Classes
# -----------------------------------------------------------------------------
cat("6. Calculating burn severity classes...\n")

df_master <- df_master %>%
  mutate(
    Burn_severity = case_when(
      is.na(dNBR) ~ NA_character_,
      dNBR < 0.1 ~ "Unburned/Low",
      dNBR < 0.27 ~ "Low-Moderate",
      dNBR < 0.44 ~ "Moderate",
      dNBR < 0.66 ~ "Moderate-High",
      TRUE ~ "High"
    ),
    Burn_severity = factor(Burn_severity,
                           levels = c("Unburned/Low", "Low-Moderate", "Moderate",
                                      "Moderate-High", "High"))
  )

cat("   Burn severity distribution:\n")
print(table(df_master$Burn_severity, useNA = "ifany"))

# -----------------------------------------------------------------------------
# 7. Save Updated Master Dataset
# -----------------------------------------------------------------------------
cat("\n7. Saving outputs...\n")

# Save updated master CSV
write_csv(df_master, file.path(output_dir, "df_master_aviris.csv"))
cat("   Saved: data/df_master_aviris.csv\n")

# Update GeoPackage
df_master_sf <- df_master %>%
  filter(!is.na(Longitude) & !is.na(Latitude)) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)

st_write(df_master_sf, file.path(output_dir, "eaton_ash_samples.gpkg"),
         layer = "samples_aviris", delete_layer = TRUE, quiet = TRUE)
cat("   Updated: data/eaton_ash_samples.gpkg (layer: samples_aviris)\n")

# Update shapefile for QGIS
st_write(df_master_sf, file.path("qgis", "eaton_ash_aviris.shp"),
         delete_layer = TRUE, quiet = TRUE)
cat("   Saved: qgis/eaton_ash_aviris.shp\n")

# -----------------------------------------------------------------------------
# 8. Summary
# -----------------------------------------------------------------------------
cat("\n=== AVIRIS EXTRACTION SUMMARY ===\n\n")

aviris_summary <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  summarise(
    N_samples = n(),
    Charash_valid = sum(!is.na(Charash_fraction)),
    Charash_mean = mean(Charash_fraction, na.rm = TRUE),
    dNBR_valid = sum(!is.na(dNBR)),
    dNBR_mean = mean(dNBR, na.rm = TRUE),
    dNBR_max = max(dNBR, na.rm = TRUE)
  )

cat("ASH samples AVIRIS coverage:\n")
print(aviris_summary)

# Correlation between AVIRIS products and metals
if (sum(!is.na(df_master$Charash_fraction)) > 5) {
  cat("\nCharash-Metal correlations:\n")
  ash_data <- df_master %>% filter(Sample_Type == "ASH" & !is.na(Charash_fraction))
  cor_charash <- cor(ash_data$Charash_fraction,
                     ash_data %>% select(Pb, Zn, Cu, Fe),
                     use = "pairwise.complete.obs")
  print(round(cor_charash, 3))
}

if (sum(!is.na(df_master$dNBR)) > 5) {
  cat("\ndNBR-Metal correlations:\n")
  ash_data <- df_master %>% filter(Sample_Type == "ASH" & !is.na(dNBR))
  cor_dnbr <- cor(ash_data$dNBR,
                  ash_data %>% select(Pb, Zn, Cu, Fe),
                  use = "pairwise.complete.obs")
  print(round(cor_dnbr, 3))
}

cat("\n=== AVIRIS Extraction Complete ===\n")
