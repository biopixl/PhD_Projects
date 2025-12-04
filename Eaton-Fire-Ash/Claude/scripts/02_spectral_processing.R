#!/usr/bin/env Rscript
# =============================================================================
# 02_spectral_processing.R
# Eaton Fire Ash Study - ASD Spectral Feature Extraction
# =============================================================================

library(tidyverse)
library(readr)

cat("=== ASD Spectral Feature Extraction ===\n\n")

# Set paths
data_dir <- "../Data"
output_dir <- "data"

# -----------------------------------------------------------------------------
# 1. Load ASD Spectral Data
# -----------------------------------------------------------------------------
cat("1. Loading ASD spectral data from zip...\n")

asd_zip <- file.path(data_dir, "Field Spectroscopy.zip")

# Load the main spectral measurements CSV
asd_spectra <- read_csv(unz(asd_zip, "Eaton Fire Ash Sampling - Spectroscopy Measurements 20250728.csv"),
                        show_col_types = FALSE)

cat(sprintf("   Loaded %d spectra with %d wavelength channels\n",
            nrow(asd_spectra), ncol(asd_spectra) - 1))

# Load metadata
asd_meta <- read_csv(file.path(output_dir, "asd_metadata.csv"), show_col_types = FALSE)

# -----------------------------------------------------------------------------
# 2. Reshape and Clean Spectral Data
# -----------------------------------------------------------------------------
cat("2. Processing spectral data...\n")

# The spectral data has wavelengths as columns
# First column is likely the file identifier
# Extract wavelength columns (numeric names from 350 to 2500)
wavelength_cols <- names(asd_spectra)[2:ncol(asd_spectra)]
wavelengths <- as.numeric(wavelength_cols)

# Check for valid wavelength range
valid_wl <- !is.na(wavelengths) & wavelengths >= 350 & wavelengths <= 2500

cat(sprintf("   Valid wavelength channels: %d (%.0f - %.0f nm)\n",
            sum(valid_wl), min(wavelengths[valid_wl]), max(wavelengths[valid_wl])))

# First column is EFA.ID (sample identifier)
names(asd_spectra)[1] <- "ASD_ID"

# Extract Base_ID from ASD_ID (e.g., "JPL06_bkA" -> "JPL06", "JPL02" -> "JPL02")
asd_spectra <- asd_spectra %>%
  mutate(
    Base_ID = str_extract(ASD_ID, "^[^_]+"),
    Base_ID = ifelse(is.na(Base_ID), ASD_ID, Base_ID)
  )

cat(sprintf("   Matched %d spectra to sample IDs\n", sum(!is.na(asd_spectra$Base_ID))))

# -----------------------------------------------------------------------------
# 3. Extract Spectral Features
# -----------------------------------------------------------------------------
cat("3. Extracting spectral features...\n")

# Function to calculate absorption depth at specific wavelength
calc_absorption_depth <- function(spectrum, wavelengths, target_wl, window = 20) {
  # Find indices within window
  idx <- which(abs(wavelengths - target_wl) <= window)
  if (length(idx) == 0) return(NA)

  # Get reflectance at target
  target_idx <- which.min(abs(wavelengths - target_wl))
  R_target <- spectrum[target_idx]

  # Get continuum (linear interpolation between shoulders)
  left_shoulder <- max(wavelengths[wavelengths < (target_wl - window)], na.rm = TRUE)
  right_shoulder <- min(wavelengths[wavelengths > (target_wl + window)], na.rm = TRUE)

  left_idx <- which.min(abs(wavelengths - left_shoulder))
  right_idx <- which.min(abs(wavelengths - right_shoulder))

  R_left <- spectrum[left_idx]
  R_right <- spectrum[right_idx]

  # Linear continuum at target
  continuum <- R_left + (R_right - R_left) * (target_wl - left_shoulder) / (right_shoulder - left_shoulder)

  # Absorption depth (normalized)
  depth <- 1 - R_target / continuum
  return(depth)
}

# Extract features for each spectrum
extract_features <- function(row, wavelengths, wl_cols) {
  spectrum <- as.numeric(row[wl_cols])

  # Handle missing or invalid data
  if (all(is.na(spectrum)) || sum(!is.na(spectrum)) < 100) {
    return(tibble(
      Slope_VIS = NA, Slope_NIR = NA, Slope_SWIR = NA,
      Depth_480nm = NA, Depth_530nm = NA, Depth_670nm = NA, Depth_870nm = NA,
      Depth_1400nm = NA, Depth_1900nm = NA, Depth_2200nm = NA, Depth_2300nm = NA,
      Albedo_VIS = NA, Albedo_NIR = NA, Albedo_SWIR = NA, Overall_albedo = NA,
      Fe_index = NA, Carbonate_index = NA, Char_index = NA
    ))
  }

  # Get reflectance at specific wavelengths
  get_R <- function(wl) {
    idx <- which.min(abs(wavelengths - wl))
    return(spectrum[idx])
  }

  # Slope calculations (linear fit)
  vis_idx <- which(wavelengths >= 400 & wavelengths <= 700)
  nir_idx <- which(wavelengths >= 700 & wavelengths <= 1300)
  swir_idx <- which(wavelengths >= 1500 & wavelengths <= 2400)

  Slope_VIS <- if (length(vis_idx) > 10) {
    coef(lm(spectrum[vis_idx] ~ wavelengths[vis_idx]))[2]
  } else NA

  Slope_NIR <- if (length(nir_idx) > 10) {
    coef(lm(spectrum[nir_idx] ~ wavelengths[nir_idx]))[2]
  } else NA

  Slope_SWIR <- if (length(swir_idx) > 10) {
    coef(lm(spectrum[swir_idx] ~ wavelengths[swir_idx]))[2]
  } else NA

  # Absorption depths at key wavelengths
  Depth_480nm <- calc_absorption_depth(spectrum, wavelengths, 480, 30)
  Depth_530nm <- calc_absorption_depth(spectrum, wavelengths, 530, 30)
  Depth_670nm <- calc_absorption_depth(spectrum, wavelengths, 670, 30)
  Depth_870nm <- calc_absorption_depth(spectrum, wavelengths, 870, 40)
  Depth_1400nm <- calc_absorption_depth(spectrum, wavelengths, 1400, 50)
  Depth_1900nm <- calc_absorption_depth(spectrum, wavelengths, 1900, 50)
  Depth_2200nm <- calc_absorption_depth(spectrum, wavelengths, 2200, 30)
  Depth_2300nm <- calc_absorption_depth(spectrum, wavelengths, 2300, 30)

  # Mean albedo by region
  Albedo_VIS <- mean(spectrum[vis_idx], na.rm = TRUE)
  Albedo_NIR <- mean(spectrum[nir_idx], na.rm = TRUE)
  Albedo_SWIR <- mean(spectrum[swir_idx], na.rm = TRUE)
  Overall_albedo <- mean(spectrum[wavelengths >= 400 & wavelengths <= 2400], na.rm = TRUE)

  # Spectral indices
  R670 <- get_R(670)
  R870 <- get_R(870)
  R2300 <- get_R(2300)
  R2330 <- get_R(2330)
  R2350 <- get_R(2350)
  R550 <- get_R(550)

  Fe_index <- (R870 - R670) / (R870 + R670 + 0.001)
  Carbonate_index <- 1 - R2330 / ((R2300 + R2350) / 2 + 0.001)
  Char_index <- 1 - Overall_albedo  # Darkness

  tibble(
    Slope_VIS = Slope_VIS * 10000,  # Scale for readability
    Slope_NIR = Slope_NIR * 10000,
    Slope_SWIR = Slope_SWIR * 10000,
    Depth_480nm = Depth_480nm,
    Depth_530nm = Depth_530nm,
    Depth_670nm = Depth_670nm,
    Depth_870nm = Depth_870nm,
    Depth_1400nm = Depth_1400nm,
    Depth_1900nm = Depth_1900nm,
    Depth_2200nm = Depth_2200nm,
    Depth_2300nm = Depth_2300nm,
    Albedo_VIS = Albedo_VIS,
    Albedo_NIR = Albedo_NIR,
    Albedo_SWIR = Albedo_SWIR,
    Overall_albedo = Overall_albedo,
    Fe_index = Fe_index,
    Carbonate_index = Carbonate_index,
    Char_index = Char_index
  )
}

# Get wavelength column indices
wl_cols <- which(names(asd_spectra) %in% wavelength_cols[valid_wl])
wl_values <- wavelengths[valid_wl]

cat("   Extracting features from each spectrum...\n")

# Apply feature extraction
features_list <- vector("list", nrow(asd_spectra))
for (i in seq_len(nrow(asd_spectra))) {
  features_list[[i]] <- extract_features(asd_spectra[i, ], wl_values, wl_cols)
  if (i %% 20 == 0) cat(sprintf("   Processed %d / %d spectra\n", i, nrow(asd_spectra)))
}

asd_features <- bind_rows(features_list)
asd_features <- bind_cols(
  asd_spectra %>% select(ASD_ID, Base_ID),
  asd_features
)

cat(sprintf("   Extracted %d features for %d spectra\n",
            ncol(asd_features) - 3, nrow(asd_features)))

# -----------------------------------------------------------------------------
# 4. Aggregate to Sample Level (average replicates)
# -----------------------------------------------------------------------------
cat("4. Aggregating to sample level...\n")

# Average features by Base_ID
asd_sample_features <- asd_features %>%
  filter(!is.na(Base_ID)) %>%
  group_by(Base_ID) %>%
  summarise(
    n_spectra = n(),
    across(Slope_VIS:Char_index, ~mean(.x, na.rm = TRUE)),
    .groups = "drop"
  )

cat(sprintf("   Aggregated to %d unique samples\n", nrow(asd_sample_features)))

# -----------------------------------------------------------------------------
# 5. Save Outputs
# -----------------------------------------------------------------------------
cat("5. Saving outputs...\n")

# Save individual spectrum features
write_csv(asd_features, file.path(output_dir, "asd_features_all.csv"))
cat("   Saved: data/asd_features_all.csv\n")

# Save sample-level features
write_csv(asd_sample_features, file.path(output_dir, "asd_features_sample.csv"))
cat("   Saved: data/asd_features_sample.csv\n")

# -----------------------------------------------------------------------------
# 6. Summary Statistics
# -----------------------------------------------------------------------------
cat("\n=== SPECTRAL FEATURE SUMMARY ===\n\n")

feature_summary <- asd_sample_features %>%
  select(-Base_ID, -n_spectra) %>%
  pivot_longer(everything(), names_to = "Feature", values_to = "Value") %>%
  group_by(Feature) %>%
  summarise(
    Min = min(Value, na.rm = TRUE),
    Median = median(Value, na.rm = TRUE),
    Max = max(Value, na.rm = TRUE),
    N_valid = sum(!is.na(Value)),
    .groups = "drop"
  )

print(feature_summary, n = 20)

cat("\n=== Spectral Processing Complete ===\n")
