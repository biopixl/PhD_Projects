#!/usr/bin/env Rscript
# =============================================================================
# 07_qgis_layers.R
# Generate QGIS-compatible layers for mapping
# =============================================================================

library(tidyverse)
library(sf)

cat("=== Generating QGIS Map Layers ===\n\n")

# Set paths
data_dir <- "data"
qgis_dir <- "qgis"

# Create QGIS directory if needed
dir.create(qgis_dir, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Load Master Dataset with All Analysis Results
# -----------------------------------------------------------------------------
cat("1. Loading analysis results...\n")

df_master <- read_csv(file.path(data_dir, "df_master_aviris.csv"), show_col_types = FALSE)

# Load additional results
moran_results <- read_csv(file.path(data_dir, "moran_spatial_autocorrelation.csv"), show_col_types = FALSE)
epa_results <- read_csv(file.path(data_dir, "table3_epa_exceedance.csv"), show_col_types = FALSE)

cat(sprintf("   Loaded %d samples\n", nrow(df_master)))

# -----------------------------------------------------------------------------
# 2. Create Spatial Object with All Attributes
# -----------------------------------------------------------------------------
cat("\n2. Creating spatial features...\n")

# Filter to samples with coordinates
df_spatial <- df_master %>%
  filter(!is.na(Longitude) & !is.na(Latitude) & Sample_Type == "ASH")

# Create sf object
sf_samples <- st_as_sf(df_spatial, coords = c("Longitude", "Latitude"), crs = 4326)

# Transform to UTM Zone 11N for California
sf_samples_utm <- st_transform(sf_samples, 32611)

cat(sprintf("   Created spatial object with %d features\n", nrow(sf_samples)))

# -----------------------------------------------------------------------------
# 3. Add Classification Columns for Mapping
# -----------------------------------------------------------------------------
cat("\n3. Adding classification columns...\n")

# Risk classification based on multiple metals
sf_samples <- sf_samples %>%
  mutate(
    # Individual metal risk classes
    Pb_class = case_when(
      Pb > 1200 ~ "High (>3x RSL)",
      Pb > 400 ~ "Elevated (>RSL)",
      Pb > 200 ~ "Moderate",
      TRUE ~ "Low"
    ),
    As_class = case_when(
      As > 20 ~ "High (>30x RSL)",
      As > 5 ~ "Elevated",
      As > 0.68 ~ "Above RSL",
      TRUE ~ "Low"
    ),
    Cr_class = case_when(
      Cr > 100 ~ "High",
      Cr > 5.6 ~ "Above RSL",
      TRUE ~ "Low"
    ),

    # Overall contamination index
    Contamination_index = log10(Pb + 1) + log10(Zn + 1) + log10(Cu + 1) + log10(As * 10 + 1),

    # Risk tier
    Risk_tier = case_when(
      N_exceedances >= 4 ~ "Critical",
      N_exceedances >= 2 ~ "Elevated",
      N_exceedances >= 1 ~ "Moderate",
      TRUE ~ "Low"
    ),

    # Data tier label
    Data_tier_label = case_when(
      Data_Tier == 1 ~ "Tier 1 (Complete)",
      Data_Tier == 2 ~ "Tier 2 (ICP-MS + XRF)",
      Data_Tier == 3 ~ "Tier 3 (ICP-MS only)",
      TRUE ~ "Unknown"
    )
  )

# Add burn severity if available
if ("Burn_severity" %in% names(sf_samples)) {
  sf_samples <- sf_samples %>%
    mutate(
      Burn_severity = factor(Burn_severity,
                             levels = c("Unburned/Low", "Low-Moderate", "Moderate",
                                       "Moderate-High", "High"))
    )
}

# -----------------------------------------------------------------------------
# 4. Export Individual Metal Layers
# -----------------------------------------------------------------------------
cat("\n4. Exporting metal concentration layers...\n")

# Lead layer
st_write(sf_samples %>% select(Base_ID, Pb, Pb_class, Pb_exceed_RSL, geometry),
         file.path(qgis_dir, "pb_concentrations.gpkg"),
         layer = "lead", delete_layer = TRUE, quiet = TRUE)

# Zinc layer
st_write(sf_samples %>% select(Base_ID, Zn, Zn_exceed_RSL, geometry),
         file.path(qgis_dir, "zn_concentrations.gpkg"),
         layer = "zinc", delete_layer = TRUE, quiet = TRUE)

# Copper layer
st_write(sf_samples %>% select(Base_ID, Cu, Cu_exceed_RSL, geometry),
         file.path(qgis_dir, "cu_concentrations.gpkg"),
         layer = "copper", delete_layer = TRUE, quiet = TRUE)

# Arsenic layer
st_write(sf_samples %>% select(Base_ID, As, As_class, As_exceed_RSL, geometry),
         file.path(qgis_dir, "as_concentrations.gpkg"),
         layer = "arsenic", delete_layer = TRUE, quiet = TRUE)

# Chromium layer
st_write(sf_samples %>% select(Base_ID, Cr, Cr_class, Cr_exceed_RSL, geometry),
         file.path(qgis_dir, "cr_concentrations.gpkg"),
         layer = "chromium", delete_layer = TRUE, quiet = TRUE)

cat("   Saved: pb_concentrations.gpkg, zn_concentrations.gpkg, etc.\n")

# -----------------------------------------------------------------------------
# 5. Export Risk Assessment Layer
# -----------------------------------------------------------------------------
cat("\n5. Exporting risk assessment layer...\n")

risk_layer <- sf_samples %>%
  select(Base_ID,
         N_exceedances, Risk_tier,
         Pb_exceed_RSL, As_exceed_RSL, Cd_exceed_RSL, Cr_exceed_RSL,
         Cu_exceed_RSL, Ni_exceed_RSL, Zn_exceed_RSL, Mn_exceed_RSL,
         Total_Toxics_ppm, Contamination_index,
         geometry)

st_write(risk_layer, file.path(qgis_dir, "risk_assessment.gpkg"),
         layer = "epa_risk", delete_layer = TRUE, quiet = TRUE)
cat("   Saved: risk_assessment.gpkg\n")

# -----------------------------------------------------------------------------
# 6. Export AVIRIS-Integrated Layer
# -----------------------------------------------------------------------------
cat("\n6. Exporting AVIRIS-integrated layer...\n")

aviris_layer <- sf_samples %>%
  select(Base_ID,
         Charash_fraction, dNBR, NBR_postfire, Burn_severity,
         any_of(paste0("PC", 1:5)),
         Pb, Zn, Cu, Fe, Ca,
         geometry)

st_write(aviris_layer, file.path(qgis_dir, "aviris_samples.gpkg"),
         layer = "aviris_extraction", delete_layer = TRUE, quiet = TRUE)
cat("   Saved: aviris_samples.gpkg\n")

# -----------------------------------------------------------------------------
# 7. Export Data Quality/Tier Layer
# -----------------------------------------------------------------------------
cat("\n7. Exporting data tier layer...\n")

tier_layer <- sf_samples %>%
  select(Base_ID, Data_Tier, Data_tier_label,
         has_ICPMS, has_XRF, has_ASD, has_FTIR,
         geometry)

st_write(tier_layer, file.path(qgis_dir, "data_tiers.gpkg"),
         layer = "sample_tiers", delete_layer = TRUE, quiet = TRUE)
cat("   Saved: data_tiers.gpkg\n")

# -----------------------------------------------------------------------------
# 8. Export Master GeoPackage with All Layers
# -----------------------------------------------------------------------------
cat("\n8. Creating master GeoPackage...\n")

# Full dataset
st_write(sf_samples, file.path(qgis_dir, "eaton_fire_ash_master.gpkg"),
         layer = "all_samples", delete_layer = TRUE, quiet = TRUE)

# Add risk layer
st_write(risk_layer, file.path(qgis_dir, "eaton_fire_ash_master.gpkg"),
         layer = "risk_assessment", delete_layer = TRUE, quiet = TRUE)

# Add AVIRIS layer
st_write(aviris_layer, file.path(qgis_dir, "eaton_fire_ash_master.gpkg"),
         layer = "aviris_data", delete_layer = TRUE, quiet = TRUE)

cat("   Saved: eaton_fire_ash_master.gpkg (with multiple layers)\n")

# -----------------------------------------------------------------------------
# 9. Export Shapefiles for Compatibility
# -----------------------------------------------------------------------------
cat("\n9. Exporting shapefiles...\n")

# Select key columns for shapefile (10 char limit on names)
shp_data <- sf_samples %>%
  select(
    Base_ID,
    Pb, Zn, Cu, As, Cr, Fe, Ca, Al,
    Pb_excRSL = Pb_exceed_RSL,
    As_excRSL = As_exceed_RSL,
    N_exceed = N_exceedances,
    Risk_tier,
    Charash = Charash_fraction,
    dNBR,
    Burn_sev = Burn_severity,
    Data_Tier,
    geometry
  )

st_write(shp_data, file.path(qgis_dir, "eaton_ash_complete.shp"),
         delete_layer = TRUE, quiet = TRUE)
cat("   Saved: eaton_ash_complete.shp\n")

# -----------------------------------------------------------------------------
# 10. Create QGIS Style Files (QML)
# -----------------------------------------------------------------------------
cat("\n10. Creating QGIS style files...\n")

# Lead classification style
pb_style <- '<!DOCTYPE qgis PUBLIC \'http://mrcc.com/qgis.dtd\' \'SYSTEM\'>
<qgis>
  <renderer-v2 type="categorizedSymbol" attr="Pb_class">
    <categories>
      <category value="High (>3x RSL)" symbol="0" label="High (>3x RSL)"/>
      <category value="Elevated (>RSL)" symbol="1" label="Elevated (>RSL)"/>
      <category value="Moderate" symbol="2" label="Moderate"/>
      <category value="Low" symbol="3" label="Low"/>
    </categories>
    <symbols>
      <symbol type="marker" name="0"><layer><prop k="color" v="139,0,0,255"/><prop k="size" v="4"/></layer></symbol>
      <symbol type="marker" name="1"><layer><prop k="color" v="255,69,0,255"/><prop k="size" v="3.5"/></layer></symbol>
      <symbol type="marker" name="2"><layer><prop k="color" v="255,165,0,255"/><prop k="size" v="3"/></layer></symbol>
      <symbol type="marker" name="3"><layer><prop k="color" v="50,205,50,255"/><prop k="size" v="2.5"/></layer></symbol>
    </symbols>
  </renderer-v2>
</qgis>'

writeLines(pb_style, file.path(qgis_dir, "pb_classification.qml"))

# Risk tier style
risk_style <- '<!DOCTYPE qgis PUBLIC \'http://mrcc.com/qgis.dtd\' \'SYSTEM\'>
<qgis>
  <renderer-v2 type="categorizedSymbol" attr="Risk_tier">
    <categories>
      <category value="Critical" symbol="0" label="Critical"/>
      <category value="Elevated" symbol="1" label="Elevated"/>
      <category value="Moderate" symbol="2" label="Moderate"/>
      <category value="Low" symbol="3" label="Low"/>
    </categories>
    <symbols>
      <symbol type="marker" name="0"><layer><prop k="color" v="139,0,0,255"/><prop k="size" v="5"/></layer></symbol>
      <symbol type="marker" name="1"><layer><prop k="color" v="255,0,0,255"/><prop k="size" v="4"/></layer></symbol>
      <symbol type="marker" name="2"><layer><prop k="color" v="255,165,0,255"/><prop k="size" v="3"/></layer></symbol>
      <symbol type="marker" name="3"><layer><prop k="color" v="34,139,34,255"/><prop k="size" v="2.5"/></layer></symbol>
    </symbols>
  </renderer-v2>
</qgis>'

writeLines(risk_style, file.path(qgis_dir, "risk_classification.qml"))

cat("   Saved: pb_classification.qml, risk_classification.qml\n")

# -----------------------------------------------------------------------------
# 11. Summary
# -----------------------------------------------------------------------------
cat("\n", rep("=", 60), "\n", sep = "")
cat("QGIS LAYER GENERATION COMPLETE\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Generated files:\n\n")

cat("GeoPackages (recommended):\n")
cat("   - qgis/eaton_fire_ash_master.gpkg (all layers)\n")
cat("   - qgis/pb_concentrations.gpkg\n")
cat("   - qgis/zn_concentrations.gpkg\n")
cat("   - qgis/cu_concentrations.gpkg\n")
cat("   - qgis/as_concentrations.gpkg\n")
cat("   - qgis/cr_concentrations.gpkg\n")
cat("   - qgis/risk_assessment.gpkg\n")
cat("   - qgis/aviris_samples.gpkg\n")
cat("   - qgis/data_tiers.gpkg\n")

cat("\nShapefiles (legacy compatibility):\n")
cat("   - qgis/eaton_ash_complete.shp\n")

cat("\nStyle files:\n")
cat("   - qgis/pb_classification.qml\n")
cat("   - qgis/risk_classification.qml\n")

cat("\nTo use in QGIS:\n")
cat("   1. Add eaton_fire_ash_master.gpkg (contains all layers)\n")
cat("   2. Apply .qml style files via Layer Properties > Symbology\n")
cat("   3. Add AVIRIS rasters from Data/AVIRIS/ as basemaps\n")

cat("\n=== QGIS Layer Generation Complete ===\n")
