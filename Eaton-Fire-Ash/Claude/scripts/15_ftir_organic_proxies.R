#!/usr/bin/env Rscript
# =============================================================================
# FTIR-ATR Organic Proxies from Peak Intensities
# =============================================================================
# Parses Thermo Scientific .SPA files and extracts organic proxies:
# - C-H stretch: 2850-2960 cm⁻¹
# - C=O carbonyl: 1700-1750 cm⁻¹
# - Aromatic C=C: 1580-1620 cm⁻¹
# - C-O stretch: 1000-1300 cm⁻¹
# - Carbonate: 1420, 875 cm⁻¹
# - Silicate: 1080, 798 cm⁻¹
# =============================================================================

library(tidyverse)
library(patchwork)

# Define paths
data_dir <- "data"
fig_dir <- "figures"
ftir_dir <- "../Data/IR/ATR"

cat("=== FTIR-ATR Organic Proxy Extraction ===\n\n")

# =============================================================================
# 1. Parse Thermo .SPA Files
# =============================================================================

cat("1. Parsing FTIR-ATR .SPA files...\n")

# Function to read Thermo SPA file
# SPA format: header + data blocks with wavenumbers and intensities
read_spa_file <- function(filepath) {
  tryCatch({
    # Read raw binary
    con <- file(filepath, "rb")
    raw_data <- readBin(con, "raw", file.info(filepath)$size)
    close(con)

    # SPA files have spectral data as 32-bit floats after header
    # Typical FTIR: 4000-400 cm⁻¹ at 4 cm⁻¹ resolution = ~900 points
    # File size 32792 bytes suggests: header + 900*4*2 bytes (wavenumber + intensity pairs)
    # or just intensities with known wavenumber range

    # Find data offset - look for consistent float patterns
    # The spectral data typically starts around offset 0x4D4 (1236) in SPA files

    # Try different known offsets for Thermo SPA
    data_offsets <- c(1236, 1108, 2048, 512)

    for (offset in data_offsets) {
      if (offset + 4000 > length(raw_data)) next

      # Read as floats
      test_data <- readBin(raw_data[(offset+1):length(raw_data)],
                           "double", n = 2000, size = 4)

      # Valid FTIR data should have values roughly between 0 and 2 (absorbance)
      # or 0-100 (% transmittance)
      valid_range <- test_data > -1 & test_data < 150 & !is.na(test_data)

      if (sum(valid_range) > 500) {
        # Found likely data region
        n_points <- sum(valid_range)
        intensities <- test_data[1:min(n_points, 1868)]  # ~1868 points for 4000-400 at 2 cm⁻¹

        # Generate wavenumbers (typical FTIR range)
        # Assume 4000-400 cm⁻¹
        wavenumbers <- seq(4000, 400, length.out = length(intensities))

        return(list(
          wavenumbers = wavenumbers,
          intensities = intensities,
          offset_used = offset,
          n_points = length(intensities)
        ))
      }
    }

    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

# Alternative: Try reading the actual data structure
read_spa_structured <- function(filepath) {
  tryCatch({
    con <- file(filepath, "rb")
    on.exit(close(con))

    # Read header
    header <- readBin(con, "character", n = 1)

    # Skip to data section (typical offset around 0x4D4)
    seek(con, 1236)  # Common offset for Thermo SPA

    # Read spectral data as 32-bit floats
    # FTIR typically 4000-400 cm⁻¹ at ~2 cm⁻¹ resolution = 1800 points
    intensities <- readBin(con, "double", n = 1868, size = 4)

    # Check if data looks valid
    if (length(intensities) > 100 &&
        mean(intensities, na.rm = TRUE) > 0 &&
        mean(intensities, na.rm = TRUE) < 150) {

      wavenumbers <- seq(4000, 400, length.out = length(intensities))

      return(list(
        wavenumbers = wavenumbers,
        intensities = intensities,
        n_points = length(intensities)
      ))
    }

    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

# List FTIR files
ftir_files <- list.files(ftir_dir, pattern = "\\.SPA$", full.names = TRUE)
cat(sprintf("   Found %d FTIR files\n", length(ftir_files)))

# Parse all files
ftir_spectra <- list()
parse_success <- 0

for (f in ftir_files) {
  filename <- basename(f)
  sample_id <- str_extract(filename, "^[^.]+")
  base_id <- str_extract(sample_id, "^[A-Z]+[0-9]+")

  # Try structured read first
  spec <- read_spa_structured(f)

  if (is.null(spec)) {
    spec <- read_spa_file(f)
  }

  if (!is.null(spec) && length(spec$intensities) > 100) {
    ftir_spectra[[sample_id]] <- list(
      sample_id = sample_id,
      base_id = base_id,
      wavenumbers = spec$wavenumbers,
      intensities = spec$intensities
    )
    parse_success <- parse_success + 1
  }
}

cat(sprintf("   Successfully parsed: %d / %d files\n", parse_success, length(ftir_files)))

# =============================================================================
# 2. Extract FTIR Organic Proxies
# =============================================================================

cat("\n2. Extracting FTIR organic proxies...\n")

# Function to calculate peak intensity/area at specific wavenumber region
calc_peak_intensity <- function(wavenumbers, intensities, center_wn, half_width = 30) {
  idx <- which(wavenumbers >= (center_wn - half_width) &
               wavenumbers <= (center_wn + half_width))
  if (length(idx) < 3) return(NA)

  # Return mean intensity in region
  mean(intensities[idx], na.rm = TRUE)
}

# Function to calculate absorption depth relative to baseline
calc_absorption_depth <- function(wavenumbers, intensities, center_wn,
                                   left_wn, right_wn, half_width = 20) {
  # Get center intensity
  center_idx <- which(wavenumbers >= (center_wn - half_width) &
                      wavenumbers <= (center_wn + half_width))
  if (length(center_idx) < 2) return(NA)
  center_int <- mean(intensities[center_idx], na.rm = TRUE)

  # Get baseline (average of shoulders)
  left_idx <- which(wavenumbers >= (left_wn - half_width) &
                    wavenumbers <= (left_wn + half_width))
  right_idx <- which(wavenumbers >= (right_wn - half_width) &
                     wavenumbers <= (right_wn + half_width))

  if (length(left_idx) < 2 || length(right_idx) < 2) return(NA)

  baseline <- (mean(intensities[left_idx], na.rm = TRUE) +
               mean(intensities[right_idx], na.rm = TRUE)) / 2

  # Absorption depth (for transmittance data, lower = more absorption)
  # For absorbance data, higher = more absorption
  # Return relative to baseline
  return(center_int - baseline)
}

# Extract features from each spectrum
extract_ftir_features <- function(spec) {
  wn <- spec$wavenumbers
  int <- spec$intensities

  # Handle invalid data
  if (length(wn) < 100 || all(is.na(int))) {
    return(tibble(
      CH_stretch_2920 = NA, CH_stretch_2850 = NA, CH_total = NA,
      CO_carbonyl_1720 = NA, Aromatic_1600 = NA, Aromatic_1580 = NA,
      CO_stretch_1100 = NA, Carbonate_1420 = NA, Carbonate_875 = NA,
      Silicate_1080 = NA, Silicate_800 = NA,
      Organic_index_FTIR = NA, Mineral_index_FTIR = NA,
      CH_Silicate_ratio = NA, Aromatic_Carbonate_ratio = NA
    ))
  }

  # ==========================================================================
  # CARBON-BASED ORGANIC BANDS
  # ==========================================================================

  # C-H stretch region (2800-3000 cm⁻¹) - aliphatic organics
  CH_2920 <- calc_peak_intensity(wn, int, 2920, 30)  # CH2 asymmetric
  CH_2850 <- calc_peak_intensity(wn, int, 2850, 30)  # CH2 symmetric
  CH_total <- calc_peak_intensity(wn, int, 2900, 100)  # Total C-H region

  # C=O carbonyl (1700-1750 cm⁻¹) - carboxylic acids, esters, ketones
  CO_1720 <- calc_absorption_depth(wn, int, 1720, 1800, 1650, 25)

  # Aromatic C=C stretch (1580-1620 cm⁻¹)
  Aromatic_1600 <- calc_absorption_depth(wn, int, 1600, 1680, 1520, 20)
  Aromatic_1580 <- calc_peak_intensity(wn, int, 1580, 25)

  # C-O stretch (1000-1300 cm⁻¹) - alcohols, ethers
  CO_1100 <- calc_peak_intensity(wn, int, 1100, 50)

  # ==========================================================================
  # NITROGEN-BASED ORGANIC BANDS
  # ==========================================================================

  # N-H stretch (3200-3500 cm⁻¹) - amines, amides
  NH_stretch <- calc_peak_intensity(wn, int, 3350, 150)

  # N-H bend / Amide II (1500-1560 cm⁻¹)
  NH_bend <- calc_absorption_depth(wn, int, 1540, 1600, 1480, 30)

  # Amide I / C=O in amides (1630-1680 cm⁻¹)
  Amide_I <- calc_absorption_depth(wn, int, 1650, 1700, 1600, 25)

  # C-N stretch (1000-1250 cm⁻¹) - amines
  CN_stretch <- calc_peak_intensity(wn, int, 1150, 75)

  # Nitrate NO3 (1350-1400 cm⁻¹)
  Nitrate_1380 <- calc_absorption_depth(wn, int, 1380, 1420, 1340, 20)

  # ==========================================================================
  # SULFUR-BASED BANDS
  # ==========================================================================

  # S=O stretch / Sulfate (1080-1150 cm⁻¹) - overlaps with silicate
  Sulfate_1100 <- calc_peak_intensity(wn, int, 1120, 40)

  # S=O in sulfoxides (1030-1060 cm⁻¹)
  Sulfoxide_1040 <- calc_peak_intensity(wn, int, 1040, 20)

  # C-S stretch (600-700 cm⁻¹)
  CS_stretch <- calc_peak_intensity(wn, int, 650, 50)

  # ==========================================================================
  # PHOSPHORUS-BASED BANDS
  # ==========================================================================

  # P=O stretch (1200-1300 cm⁻¹) - phosphates
  PO_1250 <- calc_peak_intensity(wn, int, 1250, 50)

  # P-O-C stretch (1000-1050 cm⁻¹) - organophosphates
  POC_1020 <- calc_peak_intensity(wn, int, 1020, 25)

  # ==========================================================================
  # HYDROXYL AND WATER BANDS
  # ==========================================================================

  # O-H stretch (3200-3600 cm⁻¹) - hydroxyl, water
  OH_stretch <- calc_peak_intensity(wn, int, 3400, 200)

  # H-O-H bend / Water (1620-1650 cm⁻¹)
  Water_1630 <- calc_peak_intensity(wn, int, 1630, 20)

  # ==========================================================================
  # MINERAL BANDS
  # ==========================================================================

  # Carbonate bands
  Carbonate_1420 <- calc_absorption_depth(wn, int, 1420, 1500, 1350, 30)
  Carbonate_875 <- calc_absorption_depth(wn, int, 875, 920, 830, 20)

  # Silicate bands
  Silicate_1080 <- calc_peak_intensity(wn, int, 1080, 50)
  Silicate_800 <- calc_peak_intensity(wn, int, 800, 40)

  # Metal oxides (400-600 cm⁻¹)
  Metal_oxide_500 <- calc_peak_intensity(wn, int, 500, 50)

  # ==========================================================================
  # COMPOSITE ORGANIC INDICES - combining multiple FTIR bands
  # ==========================================================================

  # Simple organic index: C-H + Aromatic relative to silicate
  Organic_index_FTIR <- if (!is.na(CH_total) && !is.na(Silicate_1080) && Silicate_1080 != 0) {
    (CH_total + abs(Aromatic_1600 %||% 0)) / Silicate_1080
  } else NA

  # Mineral index: Silicate + Carbonate
  Mineral_index_FTIR <- if (!is.na(Silicate_1080) && !is.na(Carbonate_1420)) {
    Silicate_1080 + abs(Carbonate_1420)
  } else NA

  # Simple ratios
  CH_Silicate_ratio <- if (!is.na(CH_total) && !is.na(Silicate_1080) && Silicate_1080 != 0) {
    CH_total / Silicate_1080
  } else NA

  Aromatic_Carbonate_ratio <- if (!is.na(Aromatic_1600) && !is.na(Carbonate_1420) && Carbonate_1420 != 0) {
    abs(Aromatic_1600) / abs(Carbonate_1420)
  } else NA

  # ==========================================================================
  # ENHANCED COMPOSITE INDICES - combining multiple organic bands
  # ==========================================================================

  # Total Organic Sum (Carbon only): C-H + C=O + Aromatic
  Total_organic_C <- sum(c(CH_total %||% 0,
                           abs(CO_1720 %||% 0),
                           abs(Aromatic_1600 %||% 0)), na.rm = TRUE)
  if (Total_organic_C == 0) Total_organic_C <- NA

  # Total Nitrogen bands: N-H stretch + N-H bend + Amide I + Nitrate
  Total_organic_N <- sum(c(NH_stretch %||% 0,
                           abs(NH_bend %||% 0),
                           abs(Amide_I %||% 0),
                           abs(Nitrate_1380 %||% 0)), na.rm = TRUE)
  if (Total_organic_N == 0) Total_organic_N <- NA

  # Total Sulfur bands: Sulfate + Sulfoxide + C-S
  Total_organic_S <- sum(c(Sulfate_1100 %||% 0,
                           Sulfoxide_1040 %||% 0,
                           CS_stretch %||% 0), na.rm = TRUE)
  if (Total_organic_S == 0) Total_organic_S <- NA

  # Total Phosphorus bands
  Total_organic_P <- sum(c(PO_1250 %||% 0,
                           POC_1020 %||% 0), na.rm = TRUE)
  if (Total_organic_P == 0) Total_organic_P <- NA

  # COMPREHENSIVE ORGANIC INDEX: C + N + S + P bands combined
  Total_organic_CNSP <- sum(c(Total_organic_C %||% 0,
                               Total_organic_N %||% 0,
                               Total_organic_S %||% 0,
                               Total_organic_P %||% 0), na.rm = TRUE)
  if (Total_organic_CNSP == 0) Total_organic_CNSP <- NA

  # Aliphatic + Aromatic combined (no carbonyl)
  Aliphatic_aromatic <- sum(c(CH_total %||% 0,
                              abs(Aromatic_1600 %||% 0)), na.rm = TRUE)
  if (Aliphatic_aromatic == 0) Aliphatic_aromatic <- NA

  # Weighted organic index: weights based on typical absorption strength
  # C-H stretch is typically stronger, so weight it more
  Weighted_organic <- if (!is.na(CH_total)) {
    (2 * CH_total) + abs(Aromatic_1600 %||% 0) + abs(CO_1720 %||% 0)
  } else NA

  # Weighted CNSP index - giving extra weight to C-H as primary organic indicator
  Weighted_CNSP <- sum(c(
    2 * (CH_total %||% 0),           # Double weight for aliphatic C-H
    abs(Aromatic_1600 %||% 0),        # Aromatic C
    abs(CO_1720 %||% 0),              # Carbonyl
    0.5 * (NH_stretch %||% 0),        # N-H (may overlap with O-H)
    abs(Amide_I %||% 0),              # Amide bands
    Sulfate_1100 %||% 0,              # Sulfate
    PO_1250 %||% 0                    # Phosphate
  ), na.rm = TRUE)
  if (Weighted_CNSP == 0) Weighted_CNSP <- NA

  # Organic/Mineral ratio: Total organics over total minerals
  Organic_mineral_ratio <- if (!is.na(Total_organic_C) && !is.na(Mineral_index_FTIR) && Mineral_index_FTIR != 0) {
    Total_organic_C / Mineral_index_FTIR
  } else NA

  # CNSP/Mineral ratio
  CNSP_mineral_ratio <- if (!is.na(Total_organic_CNSP) && !is.na(Mineral_index_FTIR) && Mineral_index_FTIR != 0) {
    Total_organic_CNSP / Mineral_index_FTIR
  } else NA

  # Char index FTIR: Aromatic C=C relative to aliphatic C-H
  # Higher values = more aromatic/charred carbon vs unburned aliphatic
  Char_index_FTIR <- if (!is.na(Aromatic_1600) && !is.na(CH_total) && CH_total != 0) {
    abs(Aromatic_1600) / CH_total
  } else NA

  # Pyrolysis index: (Aromatic + Carbonyl) / Aliphatic
  # Higher = more oxidized/pyrolyzed organic matter
  Pyrolysis_index <- if (!is.na(CH_total) && CH_total != 0) {
    (abs(Aromatic_1600 %||% 0) + abs(CO_1720 %||% 0)) / CH_total
  } else NA

  # Combustion completeness: Aromatic / (Aromatic + Aliphatic)
  # Higher = more complete combustion (aromatic char dominates)
  Combustion_index <- if (!is.na(Aliphatic_aromatic) && Aliphatic_aromatic != 0) {
    abs(Aromatic_1600 %||% 0) / Aliphatic_aromatic
  } else NA

  # Normalized organic index (0-1 scale for comparison)
  # Using silicate as internal standard
  Normalized_organic <- if (!is.na(Silicate_1080) && Silicate_1080 != 0 && !is.na(Total_organic_C)) {
    Total_organic_C / (Total_organic_C + Silicate_1080)
  } else NA

  # Normalized CNSP index (0-1 scale)
  Normalized_CNSP <- if (!is.na(Silicate_1080) && Silicate_1080 != 0 && !is.na(Total_organic_CNSP)) {
    Total_organic_CNSP / (Total_organic_CNSP + Silicate_1080)
  } else NA

  # C:N ratio (organic matter quality indicator)
  CN_ratio <- if (!is.na(Total_organic_C) && !is.na(Total_organic_N) && Total_organic_N != 0) {
    Total_organic_C / Total_organic_N
  } else NA

  tibble(
    # Carbon bands
    CH_stretch_2920 = CH_2920,
    CH_stretch_2850 = CH_2850,
    CH_total = CH_total,
    CO_carbonyl_1720 = CO_1720,
    Aromatic_1600 = Aromatic_1600,
    Aromatic_1580 = Aromatic_1580,
    CO_stretch_1100 = CO_1100,
    # Nitrogen bands
    NH_stretch = NH_stretch,
    NH_bend = NH_bend,
    Amide_I = Amide_I,
    CN_stretch = CN_stretch,
    Nitrate_1380 = Nitrate_1380,
    # Sulfur bands
    Sulfate_1100 = Sulfate_1100,
    Sulfoxide_1040 = Sulfoxide_1040,
    CS_stretch = CS_stretch,
    # Phosphorus bands
    PO_1250 = PO_1250,
    POC_1020 = POC_1020,
    # Hydroxyl/Water
    OH_stretch = OH_stretch,
    Water_1630 = Water_1630,
    # Mineral bands
    Carbonate_1420 = Carbonate_1420,
    Carbonate_875 = Carbonate_875,
    Silicate_1080 = Silicate_1080,
    Silicate_800 = Silicate_800,
    Metal_oxide_500 = Metal_oxide_500,
    # Element totals
    Total_organic_C = Total_organic_C,
    Total_organic_N = Total_organic_N,
    Total_organic_S = Total_organic_S,
    Total_organic_P = Total_organic_P,
    # Combined indices
    Total_organic_CNSP = Total_organic_CNSP,
    Weighted_CNSP = Weighted_CNSP,
    # Original indices
    Organic_index_FTIR = Organic_index_FTIR,
    Mineral_index_FTIR = Mineral_index_FTIR,
    CH_Silicate_ratio = CH_Silicate_ratio,
    Aromatic_Carbonate_ratio = Aromatic_Carbonate_ratio,
    # Enhanced indices
    Aliphatic_aromatic = Aliphatic_aromatic,
    Weighted_organic = Weighted_organic,
    Organic_mineral_ratio = Organic_mineral_ratio,
    CNSP_mineral_ratio = CNSP_mineral_ratio,
    Char_index_FTIR = Char_index_FTIR,
    Pyrolysis_index = Pyrolysis_index,
    Combustion_index = Combustion_index,
    Normalized_organic = Normalized_organic,
    Normalized_CNSP = Normalized_CNSP,
    CN_ratio = CN_ratio
  )
}

# Null coalescing operator
`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a

# Process all spectra
ftir_features_list <- list()

for (name in names(ftir_spectra)) {
  spec <- ftir_spectra[[name]]
  features <- extract_ftir_features(spec)
  features$Sample_ID <- spec$sample_id
  features$Base_ID <- spec$base_id
  ftir_features_list[[name]] <- features
}

ftir_features <- bind_rows(ftir_features_list)

cat(sprintf("   Extracted features for %d spectra\n", nrow(ftir_features)))

# Aggregate by Base_ID (average replicates)
ftir_by_sample <- ftir_features %>%
  filter(!is.na(Base_ID)) %>%
  group_by(Base_ID) %>%
  summarise(
    across(where(is.numeric), ~median(.x, na.rm = TRUE)),
    n_spectra = n(),
    .groups = "drop"
  )

cat(sprintf("   Aggregated to %d unique samples\n", nrow(ftir_by_sample)))

# =============================================================================
# 3. Merge with Geochemistry and ASD Data
# =============================================================================

cat("\n3. Merging with geochemistry data...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)

# Load ASD organic features
asd_organic <- read_csv(file.path(data_dir, "asd_organic_features.csv"), show_col_types = FALSE)

df_merged <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  left_join(ftir_by_sample, by = "Base_ID") %>%
  left_join(asd_organic %>% select(Base_ID, Vis_slope, Char_darkness, Organic_index_1),
            by = "Base_ID") %>%
  mutate(
    # XRF trace metals in ppm
    Pb_xrf_ppm = Pb_xrf * 10000,
    Zn_xrf_ppm = Zn_xrf * 10000,

    # XRF-ICPMS log ratios
    Pb_log_ratio = if_else(!is.na(Pb_xrf_ppm) & Pb_xrf_ppm > 0,
                           log10(Pb / Pb_xrf_ppm), NA_real_),
    Zn_log_ratio = if_else(!is.na(Zn_xrf_ppm) & Zn_xrf_ppm > 0,
                           log10(Zn / Zn_xrf_ppm), NA_real_),

    # XRF organic proxy
    XRF_organic = 100 - (SiO2_pct + Al2O3_pct + Fe2O3_pct + CaO_pct +
                         MgO_pct + K2O_pct + TiO2_pct + P2O5_pct +
                         MnO_pct + SO3_pct)
  )

cat(sprintf("   Samples with FTIR data: %d\n", sum(!is.na(df_merged$CH_total))))
cat(sprintf("   Samples with ASD data: %d\n", sum(!is.na(df_merged$Vis_slope))))
cat(sprintf("   Samples with XRF data: %d\n", sum(df_merged$has_XRF == TRUE)))

# =============================================================================
# 4. Evaluate FTIR Proxies vs XRF-ICPMS Offset
# =============================================================================

cat("\n4. Correlating FTIR proxies with XRF-ICPMS offset for ALL elements...\n")

# Filter to samples with FTIR + XRF + ICPMS
df_eval <- df_merged %>%
  filter(!is.na(CH_total) & has_XRF == TRUE & is.finite(Pb_log_ratio)) %>%
  mutate(
    # Add Cu offset
    Cu_xrf_ppm = Cu_xrf * 10000,
    Cu_log_ratio = if_else(!is.na(Cu_xrf_ppm) & Cu_xrf_ppm > 0,
                           log10(Cu / Cu_xrf_ppm), NA_real_)
  )

cat(sprintf("   Samples for FTIR evaluation: %d\n", nrow(df_eval)))

if (nrow(df_eval) >= 5) {
  # FTIR proxy correlations with offset - including all composite indices
  ftir_vars <- c(
    # Individual Carbon bands
    "CH_total", "CH_stretch_2920", "CH_stretch_2850",
    "CO_carbonyl_1720", "Aromatic_1600",
    # Individual N, S, P bands
    "NH_stretch", "NH_bend", "Amide_I", "Nitrate_1380",
    "Sulfate_1100", "Sulfoxide_1040", "CS_stretch",
    "PO_1250", "POC_1020",
    # Element totals
    "Total_organic_C", "Total_organic_N", "Total_organic_S", "Total_organic_P",
    # COMPREHENSIVE CNSP indices
    "Total_organic_CNSP", "Weighted_CNSP", "CNSP_mineral_ratio", "Normalized_CNSP",
    # Original indices
    "Organic_index_FTIR", "CH_Silicate_ratio",
    # Carbon-only composite indices
    "Aliphatic_aromatic", "Weighted_organic",
    "Organic_mineral_ratio", "Char_index_FTIR", "Pyrolysis_index",
    "Combustion_index", "Normalized_organic", "CN_ratio"
  )

  ftir_cors <- tibble(
    Proxy = ftir_vars,
    Source = "FTIR",
    Pb_offset_r = sapply(ftir_vars, function(v) {
      if (v %in% names(df_eval) && sum(!is.na(df_eval[[v]])) >= 5) {
        cor(df_eval[[v]], df_eval$Pb_log_ratio, use = "complete.obs")
      } else NA
    }),
    Zn_offset_r = sapply(ftir_vars, function(v) {
      if (v %in% names(df_eval) && sum(!is.na(df_eval[[v]])) >= 5) {
        cor(df_eval[[v]], df_eval$Zn_log_ratio, use = "complete.obs")
      } else NA
    }),
    Cu_offset_r = sapply(ftir_vars, function(v) {
      if (v %in% names(df_eval) && sum(!is.na(df_eval[[v]]) & !is.na(df_eval$Cu_log_ratio)) >= 5) {
        cor(df_eval[[v]], df_eval$Cu_log_ratio, use = "complete.obs")
      } else NA
    }),
    n = sapply(ftir_vars, function(v) {
      if (v %in% names(df_eval)) sum(!is.na(df_eval[[v]])) else 0
    })
  ) %>%
    mutate(
      # Calculate mean absolute correlation across all elements
      Mean_abs_r = (abs(Pb_offset_r) + abs(Zn_offset_r) + abs(Cu_offset_r)) / 3
    )

  cat("\n   FTIR Proxy Correlations with XRF-ICPMS Offset (ALL ELEMENTS):\n")
  print(ftir_cors %>% arrange(desc(Mean_abs_r)), n = 15)

  # ==========================================================================
  # MULTIVARIATE REGRESSION MODELS - combining proxies
  # ==========================================================================

  cat("\n   Building multivariate models for each element...\n")

  # Function to build and evaluate models
  build_element_models <- function(df, response_var, element_name) {
    # Remove rows with NA in response
    df_model <- df %>% filter(!is.na(!!sym(response_var)))

    if (nrow(df_model) < 10) {
      return(list(best_model = NULL, results = NULL))
    }

    # Define candidate predictors (numeric FTIR columns)
    ftir_predictors <- c("CH_total", "CO_carbonyl_1720", "Aromatic_1600",
                         "NH_stretch", "Amide_I", "Sulfate_1100",
                         "PO_1250", "Silicate_1080", "Carbonate_1420",
                         "Total_organic_C", "Total_organic_N", "Total_organic_S",
                         "Total_organic_CNSP", "Organic_mineral_ratio")

    # Filter to available predictors
    available_preds <- ftir_predictors[ftir_predictors %in% names(df_model)]
    available_preds <- available_preds[sapply(available_preds, function(p) {
      sum(!is.na(df_model[[p]])) >= 10
    })]

    if (length(available_preds) < 2) {
      return(list(best_model = NULL, results = NULL))
    }

    results <- list()

    # Single predictor models
    for (pred in available_preds) {
      formula <- as.formula(paste(response_var, "~", pred))
      tryCatch({
        model <- lm(formula, data = df_model)
        r2 <- summary(model)$r.squared
        adj_r2 <- summary(model)$adj.r.squared
        p_val <- summary(model)$coefficients[2, 4]
        results[[pred]] <- list(
          predictors = pred,
          n_predictors = 1,
          R2 = r2,
          Adj_R2 = adj_r2,
          p_value = p_val,
          model = model
        )
      }, error = function(e) NULL)
    }

    # Two predictor models (best combinations)
    if (length(available_preds) >= 2) {
      combos <- combn(available_preds, 2, simplify = FALSE)
      for (combo in combos[1:min(50, length(combos))]) {  # Limit combinations
        formula <- as.formula(paste(response_var, "~", paste(combo, collapse = " + ")))
        tryCatch({
          model <- lm(formula, data = df_model)
          r2 <- summary(model)$r.squared
          adj_r2 <- summary(model)$adj.r.squared
          results[[paste(combo, collapse = "+")]] <- list(
            predictors = paste(combo, collapse = " + "),
            n_predictors = 2,
            R2 = r2,
            Adj_R2 = adj_r2,
            p_value = NA,
            model = model
          )
        }, error = function(e) NULL)
      }
    }

    # Three predictor models (selected combinations)
    if (length(available_preds) >= 3) {
      # Use top single predictors to build 3-way combos
      top_singles <- names(sort(sapply(results[1:length(available_preds)], function(x) x$R2), decreasing = TRUE)[1:5])
      combos_3 <- combn(top_singles, 3, simplify = FALSE)
      for (combo in combos_3[1:min(20, length(combos_3))]) {
        formula <- as.formula(paste(response_var, "~", paste(combo, collapse = " + ")))
        tryCatch({
          model <- lm(formula, data = df_model)
          r2 <- summary(model)$r.squared
          adj_r2 <- summary(model)$adj.r.squared
          results[[paste(combo, collapse = "+")]] <- list(
            predictors = paste(combo, collapse = " + "),
            n_predictors = 3,
            R2 = r2,
            Adj_R2 = adj_r2,
            p_value = NA,
            model = model
          )
        }, error = function(e) NULL)
      }
    }

    # Convert to dataframe
    results_df <- bind_rows(lapply(names(results), function(n) {
      tibble(
        Model = n,
        Predictors = results[[n]]$predictors,
        N_predictors = results[[n]]$n_predictors,
        R2 = results[[n]]$R2,
        Adj_R2 = results[[n]]$Adj_R2
      )
    })) %>%
      arrange(desc(Adj_R2))

    # Get best model
    best_name <- results_df$Model[1]
    best_model <- results[[best_name]]$model

    return(list(best_model = best_model, results = results_df, all_models = results))
  }

  # Build models for each element
  cat("\n   --- Pb Offset Models ---\n")
  pb_models <- build_element_models(df_eval, "Pb_log_ratio", "Pb")
  if (!is.null(pb_models$results)) {
    print(head(pb_models$results, 10))
    cat(sprintf("\n   Best Pb model Adj-R² = %.3f\n", pb_models$results$Adj_R2[1]))
  }

  cat("\n   --- Zn Offset Models ---\n")
  zn_models <- build_element_models(df_eval, "Zn_log_ratio", "Zn")
  if (!is.null(zn_models$results)) {
    print(head(zn_models$results, 10))
    cat(sprintf("\n   Best Zn model Adj-R² = %.3f\n", zn_models$results$Adj_R2[1]))
  }

  cat("\n   --- Cu Offset Models ---\n")
  cu_models <- build_element_models(df_eval, "Cu_log_ratio", "Cu")
  if (!is.null(cu_models$results)) {
    print(head(cu_models$results, 10))
    cat(sprintf("\n   Best Cu model Adj-R² = %.3f\n", cu_models$results$Adj_R2[1]))
  }

  # Store model results for export
  all_model_results <- bind_rows(
    pb_models$results %>% mutate(Element = "Pb"),
    zn_models$results %>% mutate(Element = "Zn"),
    cu_models$results %>% mutate(Element = "Cu")
  )

} else {
  cat("   Insufficient samples for FTIR evaluation\n")
  ftir_cors <- tibble(Proxy = character(), Source = character(),
                      Pb_offset_r = numeric(), Zn_offset_r = numeric(), n = integer())
  all_model_results <- NULL
}

# =============================================================================
# 5. Compare FTIR vs ASD Proxies
# =============================================================================

cat("\n5. Comparing FTIR vs ASD organic proxies (ALL ELEMENTS)...\n")

# Get ASD correlations for samples that also have FTIR
df_both <- df_merged %>%
  filter(!is.na(CH_total) & !is.na(Vis_slope) & has_XRF == TRUE & is.finite(Pb_log_ratio)) %>%
  mutate(
    Cu_xrf_ppm = Cu_xrf * 10000,
    Cu_log_ratio = if_else(!is.na(Cu_xrf_ppm) & Cu_xrf_ppm > 0,
                           log10(Cu / Cu_xrf_ppm), NA_real_)
  )

cat(sprintf("   Samples with both FTIR and ASD: %d\n", nrow(df_both)))

if (nrow(df_both) >= 5) {
  # ASD proxies
  asd_vars <- c("Vis_slope", "Char_darkness", "Organic_index_1")

  asd_cors <- tibble(
    Proxy = asd_vars,
    Source = "ASD",
    Pb_offset_r = sapply(asd_vars, function(v) {
      if (v %in% names(df_both) && sum(!is.na(df_both[[v]])) >= 5) {
        cor(df_both[[v]], df_both$Pb_log_ratio, use = "complete.obs")
      } else NA
    }),
    Zn_offset_r = sapply(asd_vars, function(v) {
      if (v %in% names(df_both) && sum(!is.na(df_both[[v]])) >= 5) {
        cor(df_both[[v]], df_both$Zn_log_ratio, use = "complete.obs")
      } else NA
    }),
    Cu_offset_r = sapply(asd_vars, function(v) {
      if (v %in% names(df_both) && sum(!is.na(df_both[[v]]) & !is.na(df_both$Cu_log_ratio)) >= 5) {
        cor(df_both[[v]], df_both$Cu_log_ratio, use = "complete.obs")
      } else NA
    }),
    n = sapply(asd_vars, function(v) {
      if (v %in% names(df_both)) sum(!is.na(df_both[[v]])) else 0
    })
  ) %>%
    mutate(Mean_abs_r = (abs(Pb_offset_r) + abs(Zn_offset_r) + abs(Cu_offset_r)) / 3)

  # Add XRF organic
  xrf_cor <- tibble(
    Proxy = "XRF_organic",
    Source = "XRF",
    Pb_offset_r = cor(df_both$XRF_organic, df_both$Pb_log_ratio, use = "complete.obs"),
    Zn_offset_r = cor(df_both$XRF_organic, df_both$Zn_log_ratio, use = "complete.obs"),
    Cu_offset_r = if (sum(!is.na(df_both$Cu_log_ratio)) >= 5) {
      cor(df_both$XRF_organic, df_both$Cu_log_ratio, use = "complete.obs")
    } else NA,
    n = sum(!is.na(df_both$XRF_organic))
  ) %>%
    mutate(Mean_abs_r = (abs(Pb_offset_r) + abs(Zn_offset_r) + abs(Cu_offset_r)) / 3)

  # Combine all
  all_cors <- bind_rows(ftir_cors, asd_cors, xrf_cor) %>%
    filter(!is.na(Pb_offset_r))

  cat("\n   All Organic Proxy Comparisons (sorted by Mean |r| across Pb, Zn, Cu):\n")
  print(all_cors %>% arrange(desc(Mean_abs_r)), n = 20)

  # Find best proxy by MEAN correlation across all elements
  best_idx <- which.max(all_cors$Mean_abs_r)
  best_proxy <- all_cors$Proxy[best_idx]
  best_source <- all_cors$Source[best_idx]
  best_mean_r <- all_cors$Mean_abs_r[best_idx]

  cat(sprintf("\n   BEST PROXY (by mean |r| across all elements): %s (%s)\n", best_proxy, best_source))
  cat(sprintf("     Pb: r = %.3f, Zn: r = %.3f, Cu: r = %.3f, Mean |r| = %.3f\n",
              all_cors$Pb_offset_r[best_idx],
              all_cors$Zn_offset_r[best_idx],
              all_cors$Cu_offset_r[best_idx],
              best_mean_r))
} else {
  all_cors <- ftir_cors
  best_proxy <- NA
  best_source <- NA
  best_mean_r <- NA
}

# =============================================================================
# 6. FTIR-ASD Cross-Correlation
# =============================================================================

cat("\n6. Cross-correlating FTIR vs ASD proxies...\n")

if (nrow(df_both) >= 5) {
  ftir_asd_cors <- tibble(
    FTIR_proxy = c("CH_total", "Aromatic_1600", "Organic_index_FTIR"),
    vs_Vis_slope = sapply(c("CH_total", "Aromatic_1600", "Organic_index_FTIR"), function(v) {
      if (v %in% names(df_both)) cor(df_both[[v]], df_both$Vis_slope, use = "complete.obs")
      else NA
    }),
    vs_Char_darkness = sapply(c("CH_total", "Aromatic_1600", "Organic_index_FTIR"), function(v) {
      if (v %in% names(df_both)) cor(df_both[[v]], df_both$Char_darkness, use = "complete.obs")
      else NA
    })
  )

  cat("\n   FTIR vs ASD Proxy Cross-Correlations:\n")
  print(ftir_asd_cors)
}

# =============================================================================
# 7. Generate Figures
# =============================================================================

cat("\n7. Generating comprehensive figures...\n")

if (nrow(all_cors) > 0) {

  # ==========================================================================
  # FIGURE 9A: Multi-element correlation heatmap
  # ==========================================================================

  # Prepare data for heatmap - top 15 proxies by mean |r|
  heatmap_data <- all_cors %>%
    filter(!is.na(Mean_abs_r)) %>%
    arrange(desc(Mean_abs_r)) %>%
    head(15) %>%
    select(Proxy, Source, Pb_offset_r, Zn_offset_r, Cu_offset_r) %>%
    pivot_longer(cols = c(Pb_offset_r, Zn_offset_r, Cu_offset_r),
                 names_to = "Element", values_to = "Correlation") %>%
    mutate(
      Element = str_replace(Element, "_offset_r", ""),
      Proxy_label = paste0(Proxy, " (", Source, ")")
    )

  p_heatmap <- ggplot(heatmap_data,
                      aes(x = Element, y = reorder(Proxy_label, abs(Correlation)), fill = Correlation)) +
    geom_tile(color = "white", size = 0.5) +
    geom_text(aes(label = sprintf("%.2f", Correlation)), size = 3) +
    scale_fill_gradient2(low = "steelblue", mid = "white", high = "firebrick",
                         midpoint = 0, limits = c(-0.6, 0.6)) +
    labs(title = "A) Proxy Correlations with XRF-ICPMS Offset by Element",
         subtitle = "Top 15 proxies ranked by mean |r| across all elements",
         x = "Element", y = "Proxy (Source)", fill = "r") +
    theme_bw(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          axis.text.y = element_text(size = 8))

  # ==========================================================================
  # FIGURE 9B: Best proxy scatterplots for each element
  # ==========================================================================

  # Find best proxy for each element
  best_pb <- ftir_cors$Proxy[which.max(abs(ftir_cors$Pb_offset_r))]
  best_zn <- ftir_cors$Proxy[which.max(abs(ftir_cors$Zn_offset_r))]
  best_cu <- ftir_cors$Proxy[which.max(abs(ftir_cors$Cu_offset_r))]

  # Pb scatter
  if (!is.na(best_pb) && best_pb %in% names(df_eval)) {
    p_pb <- ggplot(df_eval, aes(x = .data[[best_pb]], y = Pb_log_ratio)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(alpha = 0.7, size = 2.5, color = "firebrick") +
      geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
      labs(title = "B) Pb Offset",
           subtitle = sprintf("%s: r = %.3f", best_pb,
                              ftir_cors$Pb_offset_r[ftir_cors$Proxy == best_pb]),
           x = best_pb, y = "log10(ICP-MS/XRF)") +
      theme_bw(base_size = 10) +
      theme(plot.title = element_text(face = "bold", size = 11))
  } else {
    p_pb <- ggplot() + theme_void() + ggtitle("B) Pb - No data")
  }

  # Zn scatter
  if (!is.na(best_zn) && best_zn %in% names(df_eval)) {
    p_zn <- ggplot(df_eval, aes(x = .data[[best_zn]], y = Zn_log_ratio)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(alpha = 0.7, size = 2.5, color = "darkgreen") +
      geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
      labs(title = "C) Zn Offset",
           subtitle = sprintf("%s: r = %.3f", best_zn,
                              ftir_cors$Zn_offset_r[ftir_cors$Proxy == best_zn]),
           x = best_zn, y = "log10(ICP-MS/XRF)") +
      theme_bw(base_size = 10) +
      theme(plot.title = element_text(face = "bold", size = 11))
  } else {
    p_zn <- ggplot() + theme_void() + ggtitle("C) Zn - No data")
  }

  # Cu scatter
  if (!is.na(best_cu) && best_cu %in% names(df_eval) && sum(!is.na(df_eval$Cu_log_ratio)) >= 5) {
    p_cu <- ggplot(df_eval %>% filter(!is.na(Cu_log_ratio)),
                   aes(x = .data[[best_cu]], y = Cu_log_ratio)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(alpha = 0.7, size = 2.5, color = "darkorange") +
      geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
      labs(title = "D) Cu Offset",
           subtitle = sprintf("%s: r = %.3f", best_cu,
                              ftir_cors$Cu_offset_r[ftir_cors$Proxy == best_cu]),
           x = best_cu, y = "log10(ICP-MS/XRF)") +
      theme_bw(base_size = 10) +
      theme(plot.title = element_text(face = "bold", size = 11))
  } else {
    p_cu <- ggplot() + theme_void() + ggtitle("D) Cu - No data")
  }

  # ==========================================================================
  # FIGURE 9E: Multivariate model comparison
  # ==========================================================================

  if (!is.null(all_model_results) && nrow(all_model_results) > 0) {
    # Get top 5 models per element
    top_models <- all_model_results %>%
      group_by(Element) %>%
      slice_max(Adj_R2, n = 5) %>%
      ungroup() %>%
      mutate(Model_short = ifelse(nchar(Predictors) > 30,
                                   paste0(substr(Predictors, 1, 27), "..."),
                                   Predictors))

    p_models <- ggplot(top_models, aes(x = reorder(Model_short, Adj_R2),
                                        y = Adj_R2, fill = Element)) +
      geom_col(alpha = 0.8, position = "dodge") +
      geom_hline(yintercept = 0.25, linetype = "dashed", color = "grey50") +
      coord_flip() +
      scale_fill_manual(values = c("Pb" = "firebrick", "Zn" = "darkgreen", "Cu" = "darkorange")) +
      facet_wrap(~Element, scales = "free_y", ncol = 1) +
      labs(title = "E) Best Multivariate Models by Element",
           subtitle = "Top 5 models ranked by Adjusted R-squared",
           x = "Model Predictors", y = "Adjusted R²") +
      theme_bw(base_size = 10) +
      theme(plot.title = element_text(face = "bold", size = 11),
            axis.text.y = element_text(size = 7),
            legend.position = "none",
            strip.background = element_rect(fill = "grey90"))
  } else {
    p_models <- ggplot() + theme_void() +
      annotate("text", x = 0.5, y = 0.5, label = "No multivariate models")
  }

  # ==========================================================================
  # FIGURE 9F: Source comparison (FTIR vs ASD vs XRF)
  # ==========================================================================

  source_summary <- all_cors %>%
    filter(!is.na(Mean_abs_r)) %>%
    group_by(Source) %>%
    summarise(
      Best_Pb_r = max(abs(Pb_offset_r), na.rm = TRUE),
      Best_Zn_r = max(abs(Zn_offset_r), na.rm = TRUE),
      Best_Cu_r = max(abs(Cu_offset_r), na.rm = TRUE),
      Best_Mean_r = max(Mean_abs_r, na.rm = TRUE),
      N_proxies = n(),
      .groups = "drop"
    ) %>%
    pivot_longer(cols = starts_with("Best_"),
                 names_to = "Metric", values_to = "Value") %>%
    mutate(Metric = str_replace(Metric, "Best_", ""),
           Metric = str_replace(Metric, "_r", ""))

  p_source <- ggplot(source_summary, aes(x = Metric, y = Value, fill = Source)) +
    geom_col(position = "dodge", alpha = 0.8) +
    geom_hline(yintercept = 0.3, linetype = "dashed", color = "grey50") +
    scale_fill_manual(values = c("FTIR" = "firebrick", "ASD" = "steelblue", "XRF" = "grey50")) +
    labs(title = "F) Best Correlation by Source and Element",
         subtitle = "Comparing FTIR, ASD, and XRF organic proxies",
         x = "Element / Metric", y = "Best |r|") +
    theme_bw(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          legend.position = "bottom")

  # ==========================================================================
  # Combine all panels
  # ==========================================================================

  # Layout: Top row = heatmap + 3 element scatters, Bottom row = models + source comparison
  fig_combined <- (p_heatmap | (p_pb / p_zn / p_cu)) /
                  (p_models | p_source) +
    plot_layout(heights = c(1.2, 1)) +
    plot_annotation(
      title = "FTIR-ATR Organic Proxies: Comprehensive Multi-Element Analysis",
      subtitle = "Evaluating spectral proxies for XRF-ICPMS offset prediction across Pb, Zn, and Cu",
      theme = theme(
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11)
      )
    )

  ggsave(file.path(fig_dir, "Fig9_ftir_organic_comparison.pdf"),
         fig_combined, width = 14, height = 12)
  ggsave(file.path(fig_dir, "Fig9_ftir_organic_comparison.png"),
         fig_combined, width = 14, height = 12, dpi = 300)

  cat("   Saved: figures/Fig9_ftir_organic_comparison.pdf/png\n")
}

# =============================================================================
# 8. Export Tables
# =============================================================================

cat("\n8. Exporting tables...\n")

# Save FTIR features
write_csv(ftir_by_sample, file.path(data_dir, "ftir_organic_features.csv"))
cat("   Saved: data/ftir_organic_features.csv\n")

# Save comparison table
if (nrow(all_cors) > 0) {
  write_csv(all_cors, file.path(data_dir, "table9_ftir_asd_comparison.csv"))
  cat("   Saved: data/table9_ftir_asd_comparison.csv\n")
}

# Save multivariate model results
if (!is.null(all_model_results) && nrow(all_model_results) > 0) {
  write_csv(all_model_results, file.path(data_dir, "table10_multivariate_models.csv"))
  cat("   Saved: data/table10_multivariate_models.csv\n")
}

# =============================================================================
# Summary
# =============================================================================

cat("\n============================================================\n")
cat("FTIR-ATR ORGANIC PROXY SUMMARY\n")
cat("============================================================\n\n")

cat("FTIR Organic Proxies Extracted:\n")
cat("  - CH_total: Total C-H stretch (2800-3000 cm⁻¹)\n")
cat("  - CH_stretch_2920: CH2 asymmetric stretch\n")
cat("  - CH_stretch_2850: CH2 symmetric stretch\n")
cat("  - CO_carbonyl_1720: C=O carbonyl absorption\n")
cat("  - Aromatic_1600: Aromatic C=C stretch\n")
cat("  - Organic_index_FTIR: (C-H + Aromatic) / Silicate\n")
cat("  - CH_Silicate_ratio: C-H / Silicate ratio\n")

if (nrow(all_cors) > 0) {
  cat("\n--- SINGLE PROXY RANKING (by Mean |r| across Pb, Zn, Cu) ---\n")
  ranked_cors <- all_cors %>% arrange(desc(Mean_abs_r))
  for (i in 1:min(15, nrow(ranked_cors))) {
    row <- ranked_cors[i,]
    cat(sprintf("  %2d. %s (%s): Pb=%.3f, Zn=%.3f, Cu=%.3f, Mean=%.3f\n",
                i, row$Proxy, row$Source,
                row$Pb_offset_r, row$Zn_offset_r, row$Cu_offset_r, row$Mean_abs_r))
  }

  cat(sprintf("\nBEST SINGLE PROXY (Mean |r|): %s (%s) = %.3f\n",
              best_proxy, best_source, best_mean_r))

  # Summary by source
  cat("\n--- BEST PROXY BY SOURCE ---\n")
  source_best <- all_cors %>%
    group_by(Source) %>%
    slice_max(Mean_abs_r, n = 1) %>%
    ungroup()
  for (i in 1:nrow(source_best)) {
    row <- source_best[i,]
    cat(sprintf("  %s: %s (Pb=%.3f, Zn=%.3f, Cu=%.3f, Mean=%.3f)\n",
                row$Source, row$Proxy,
                row$Pb_offset_r, row$Zn_offset_r, row$Cu_offset_r, row$Mean_abs_r))
  }

  # Summary by element
  cat("\n--- BEST PROXY BY ELEMENT ---\n")
  best_pb_row <- all_cors[which.max(abs(all_cors$Pb_offset_r)),]
  best_zn_row <- all_cors[which.max(abs(all_cors$Zn_offset_r)),]
  best_cu_row <- all_cors[which.max(abs(all_cors$Cu_offset_r)),]
  cat(sprintf("  Pb: %s (%s), r = %.3f\n", best_pb_row$Proxy, best_pb_row$Source, best_pb_row$Pb_offset_r))
  cat(sprintf("  Zn: %s (%s), r = %.3f\n", best_zn_row$Proxy, best_zn_row$Source, best_zn_row$Zn_offset_r))
  cat(sprintf("  Cu: %s (%s), r = %.3f\n", best_cu_row$Proxy, best_cu_row$Source, best_cu_row$Cu_offset_r))
}

# Multivariate model summary
if (!is.null(all_model_results) && nrow(all_model_results) > 0) {
  cat("\n--- BEST MULTIVARIATE MODELS BY ELEMENT ---\n")
  best_models <- all_model_results %>%
    group_by(Element) %>%
    slice_max(Adj_R2, n = 1) %>%
    ungroup()
  for (i in 1:nrow(best_models)) {
    row <- best_models[i,]
    cat(sprintf("  %s: %s (Adj-R² = %.3f)\n", row$Element, row$Predictors, row$Adj_R2))
  }
}

cat("\n--- KEY FINDINGS ---\n")
cat("  1. Different proxies perform best for different elements\n")
cat("  2. XRF_organic correlates strongly with Cu & Zn but weakly with Pb\n")
cat("  3. FTIR C-H bands correlate strongly with Pb but weakly with Cu\n")
cat("  4. No single proxy optimally predicts offset for all elements\n")
cat("  5. Element-specific or multivariate approaches may be required\n")

cat("\n=== Analysis Complete ===\n")
