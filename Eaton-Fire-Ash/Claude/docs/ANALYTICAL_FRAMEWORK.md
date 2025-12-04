# Analytical Framework: Data Harmonization and Hypothesis Testing

## Document Purpose
This document provides the detailed analytical framework for harmonizing multi-modal datasets and testing each hypothesis in the Eaton Fire Ash manuscript.

---

## 1. SAMPLE ID HARMONIZATION

### 1.1 ID Naming Conventions Across Datasets

| Dataset | ID Format Example | Pattern | Notes |
|---------|-------------------|---------|-------|
| **ICP-MS** | `JPL06`, `1590`, `GPS02` | Base ID | Primary key |
| **ICP-MS (XRF link)** | `JPL06_bkB.S` | Base_aliquot.prep | Links to XRF |
| **XRF** | `JPL86_bkB.S` | Base_aliquot.prep | Matches ICP-MS link |
| **ASD Field Spec** | `JPL06_bkA` | Base_aliquot | Different aliquot (bkA vs bkB) |
| **ATR-FTIR** | `JPL06_bkB.S-1.SPA` | Base_aliquot.prep-replicate.ext | Same aliquot as XRF/ICP-MS |

### 1.2 Sample ID Crosswalk Table

The canonical **Base_ID** serves as the primary join key:

```
Base_ID Derivation Rules:
─────────────────────────
ICP-MS:    EFA.ID column directly (e.g., "JPL06", "1590", "GPS02")
XRF:       Extract before "_bkB" (e.g., "JPL86_bkB.S" → "JPL86")
ASD:       Extract before "_bkA" (e.g., "JPL06_bkA" → "JPL06")
ATR-FTIR:  Extract before "_bk" (e.g., "JPL06_bkB.S-1.SPA" → "JPL06")
```

### 1.3 Sample Coverage Matrix

| Base_ID | ICP-MS | XRF | ASD | ATR-FTIR | Type | Priority |
|---------|--------|-----|-----|----------|------|----------|
| JPL06 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL07 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL09 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL11 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL15 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL18 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL25 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL29 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL33 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL43 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL48 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL50 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL51 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL58 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL59 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL61 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL63 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL68 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL73 | ✓ | ✓ | ✓ | - | ASH | TIER 2 |
| JPL76 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL77 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL79 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL86 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL89 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| JPL94 | - | ✓ | ✓ | ✓ | ASH | TIER 2 |
| JPL95 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| GPS02 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| GPS03 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| GPS05 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| GPS09 | ✓ | ✓ | ✓ | ✓ | ASH | **TIER 1** |
| 1590 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| 1620 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| XPAH20 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| XPAH26 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| XPAH28 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| XPAH29 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| XPAH55 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| XPAH58 | ✓ | ✓ | - | ✓ | ASH | TIER 2 |
| 1637 | ✓ | - | - | - | SOIL | Control |
| 1643 | ✓ | - | - | - | SOIL | Control |
| 1648 | ✓ | - | - | - | SOIL | Control |

**TIER 1 samples (n≈30)**: Complete data across all 4 measurement types - use for all hypothesis testing
**TIER 2 samples (n≈10)**: Missing ASD or some other data - use for geochemistry-only analyses
**Control samples (n=3)**: Soil background - use for contamination baseline

---

## 2. HARMONIZED MASTER DATA FRAME SCHEMA

### 2.1 Primary Data Frame: `df_master`

```
STRUCTURE: df_master
════════════════════════════════════════════════════════════════════════════

IDENTIFIERS (5 columns)
├── Base_ID          : chr    # Primary key (e.g., "JPL06")
├── Lat              : num    # Decimal degrees WGS84
├── Lon              : num    # Decimal degrees WGS84
├── Sample_Type      : factor # "ASH", "SOIL"
└── Data_Tier        : int    # 1 = complete, 2 = partial, 3 = control

ICP-MS TRACE METALS (55+ columns, units: ppm)
├── Pb_ppm           : num    # Lead
├── Zn_ppm           : num    # Zinc
├── Cu_ppm           : num    # Copper
├── As_ppm           : num    # Arsenic
├── Cd_ppm           : num    # Cadmium
├── Cr_ppm           : num    # Chromium
├── Ni_ppm           : num    # Nickel
├── Mn_ppm           : num    # Manganese
├── Ba_ppm           : num    # Barium
├── Fe_ppm           : num    # Iron
├── Ca_ppm           : num    # Calcium
├── Al_ppm           : num    # Aluminum
├── ... (all 60+ elements)
└── Sum_Metals_ppm   : num    # Total metal loading

XRF MAJOR ELEMENTS (15 columns, units: wt%)
├── SiO2_pct         : num    # Silicon dioxide
├── Al2O3_pct        : num    # Aluminum oxide
├── Fe2O3_pct        : num    # Iron oxide
├── CaO_pct          : num    # Calcium oxide
├── MgO_pct          : num    # Magnesium oxide
├── Na2O_pct         : num    # Sodium oxide
├── K2O_pct          : num    # Potassium oxide
├── TiO2_pct         : num    # Titanium dioxide
├── P2O5_pct         : num    # Phosphorus pentoxide
├── MnO_pct          : num    # Manganese oxide
├── SO3_pct          : num    # Sulfur trioxide
└── LOI_pct          : num    # Loss on ignition (if available)

DERIVED GEOCHEMICAL INDICES (10 columns)
├── CIA              : num    # Chemical Index of Alteration
├── Ca_MgO_ratio     : num    # Calcium/Magnesium ratio
├── Fe_Al_ratio      : num    # Iron/Aluminum ratio
├── Si_Al_ratio      : num    # Silicon/Aluminum ratio
├── K_Na_ratio       : num    # Potassium/Sodium ratio
├── Sum_REE_ppm      : num    # Total rare earth elements
├── Pb_Zn_ratio      : num    # Lead/Zinc ratio
├── Total_Toxics_ppm : num    # Sum of Pb+As+Cd+Cr(VI)+Ni
├── Enrichment_Factor: num    # vs crustal average
└── Metal_Load_Class : factor # "Low", "Medium", "High", "Extreme"

EPA EXCEEDANCE FLAGS (8 columns)
├── Pb_exceed_RSL    : logical # TRUE if Pb > 400 ppm
├── As_exceed_RSL    : logical # TRUE if As > 0.68 ppm
├── Cd_exceed_RSL    : logical # TRUE if Cd > 70 ppm
├── Cr_exceed_RSL    : logical # TRUE if Cr > 5.6 ppm (as Cr VI)
├── Cu_exceed_RSL    : logical # TRUE if Cu > 3100 ppm
├── Ni_exceed_RSL    : logical # TRUE if Ni > 1500 ppm
├── Zn_exceed_RSL    : logical # TRUE if Zn > 23000 ppm
└── N_exceedances    : int     # Count of thresholds exceeded

════════════════════════════════════════════════════════════════════════════
```

### 2.2 Spectral Data Frames

#### 2.2.1 ASD Reflectance: `df_asd`

```
STRUCTURE: df_asd
════════════════════════════════════════════════════════════════════════════

IDENTIFIERS
├── Base_ID          : chr    # Primary key for joining
├── ASD_ID           : chr    # Original ASD filename
├── Collection_Date  : Date   # Measurement date

REFLECTANCE SPECTRA (2151 columns)
├── R_350nm          : num    # Reflectance at 350 nm
├── R_351nm          : num    # Reflectance at 351 nm
├── ...
└── R_2500nm         : num    # Reflectance at 2500 nm

SPECTRAL FEATURES (derived, 20+ columns)
├── Slope_VIS        : num    # Visible slope (400-700 nm)
├── Slope_NIR        : num    # NIR slope (700-1300 nm)
├── Depth_480nm      : num    # Fe³⁺ absorption depth
├── Depth_530nm      : num    # Fe³⁺ absorption depth
├── Depth_670nm      : num    # Fe³⁺ absorption depth
├── Depth_870nm      : num    # Fe³⁺ absorption depth
├── Depth_1400nm     : num    # OH absorption depth
├── Depth_1900nm     : num    # H2O absorption depth
├── Depth_2200nm     : num    # Al-OH absorption depth
├── Depth_2300nm     : num    # Carbonate absorption depth
├── SWIR1_mean       : num    # Mean reflectance 1550-1750 nm
├── SWIR2_mean       : num    # Mean reflectance 2100-2300 nm
├── Overall_albedo   : num    # Mean reflectance 400-2400 nm
├── Fe_index         : num    # (R870-R670)/(R870+R670)
├── Carbonate_index  : num    # Depth at 2330 nm
└── Char_index       : num    # Darkness metric

════════════════════════════════════════════════════════════════════════════
```

#### 2.2.2 ATR-FTIR: `df_ftir`

```
STRUCTURE: df_ftir
════════════════════════════════════════════════════════════════════════════

IDENTIFIERS
├── Base_ID          : chr    # Primary key for joining
├── FTIR_ID          : chr    # Original SPA filename

ABSORBANCE SPECTRA (~3600 columns at 1 cm⁻¹ resolution)
├── A_4000cm         : num    # Absorbance at 4000 cm⁻¹
├── A_3999cm         : num
├── ...
└── A_400cm          : num    # Absorbance at 400 cm⁻¹

MINERAL INDICES (derived, 15+ columns)
├── Carbonate_1420   : num    # Peak area 1400-1450 cm⁻¹
├── Carbonate_870    : num    # Peak height 870 cm⁻¹
├── Silicate_1000    : num    # Peak area 950-1100 cm⁻¹
├── Organic_CH       : num    # Peak area 2800-3000 cm⁻¹
├── Organic_aromatic : num    # Peak height 1600 cm⁻¹
├── Water_3400       : num    # Broad OH peak
├── Phosphate_1050   : num    # Peak height ~1050 cm⁻¹
├── Sulfate_1100     : num    # Peak height ~1100 cm⁻¹
├── ite_index        : num    # Calcite identification
├── Fe_oxide_600     : num    # Metal-O peak <700 cm⁻¹
├── Glass_amorphous  : num    # Broad silicate feature
└── Mineral_class    : factor # Dominant mineral phase

════════════════════════════════════════════════════════════════════════════
```

#### 2.2.3 AVIRIS Extracted Values: `df_aviris`

```
STRUCTURE: df_aviris
════════════════════════════════════════════════════════════════════════════

IDENTIFIERS
├── Base_ID          : chr    # Primary key for joining
├── Pixel_X          : int    # AVIRIS pixel column
├── Pixel_Y          : int    # AVIRIS pixel row

AVIRIS PRODUCTS
├── Charash_fraction : num    # Char/ash abundance (0-1)
├── dNBR             : num    # Differenced NBR
├── PC1              : num    # Principal component 1
├── PC2              : num    # Principal component 2
├── PC3              : num    # Principal component 3
├── NBR_prefire      : num    # Pre-fire NBR
├── NBR_postfire     : num    # Post-fire NBR

AVIRIS SPECTRA (224 bands)
├── AVIRIS_380nm     : num    # Reflectance band 1
├── ...
└── AVIRIS_2500nm    : num    # Reflectance band 224

════════════════════════════════════════════════════════════════════════════
```

### 2.3 Joined Analysis Data Frame: `df_analysis`

```
df_analysis = df_master
    |> left_join(df_asd_features, by = "Base_ID")
    |> left_join(df_ftir_features, by = "Base_ID")
    |> left_join(df_aviris, by = "Base_ID")
    |> filter(Data_Tier == 1)  # TIER 1 samples only for main analyses

Dimensions: ~30 rows × ~150 columns
```

---

## 3. HYPOTHESIS TESTING PROTOCOLS

### 3.1 PSQ-1: Metal Contamination Levels and Spatial Patterns

#### Hypothesis
> H1: >50% of ash samples exceed EPA RSLs for Pb, As; significant spatial clustering exists

#### Required Data
```r
df_psq1 <- df_master %>%
  filter(Sample_Type == "ASH") %>%
  select(Base_ID, Lat, Lon,
         Pb_ppm, As_ppm, Cd_ppm, Cr_ppm, Cu_ppm, Zn_ppm, Ni_ppm,
         Pb_exceed_RSL, As_exceed_RSL, N_exceedances)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | Descriptive statistics | `base` | Table 2: Summary stats |
| 2 | Exceedance calculation | `base` | Table 3: % exceeding RSLs |
| 3 | Shapiro-Wilk normality test | `stats` | Determine if parametric appropriate |
| 4 | Log-transform if needed | `base` | Normalized distributions |
| 5 | Spatial interpolation (IDW) | `gstat`, `sf` | Fig 3: Pb, Zn, Cu maps |
| 6 | Getis-Ord Gi* hotspot | `spdep` | Hotspot significance |
| 7 | Moran's I autocorrelation | `spdep` | Spatial clustering p-value |

#### Success Criteria
- [x] Calculate exceedance % for each metal vs EPA RSL
- [x] Moran's I significant at p < 0.05 for at least one metal
- [x] Gi* identifies ≥1 significant hotspot cluster

#### Code Template
```r
# Exceedance analysis
exceedance_summary <- df_psq1 %>%
  summarise(
    Pb_pct_exceed = mean(Pb_exceed_RSL, na.rm = TRUE) * 100,
    As_pct_exceed = mean(As_exceed_RSL, na.rm = TRUE) * 100,
    # ... other metals
  )

# Spatial analysis
library(spdep)
coords <- cbind(df_psq1$Lon, df_psq1$Lat)
nb <- knn2nb(knearneigh(coords, k = 5))
lw <- nb2listw(nb, style = "W")

moran_Pb <- moran.test(log(df_psq1$Pb_ppm + 1), lw)
gi_Pb <- localG(log(df_psq1$Pb_ppm + 1), lw)
```

---

### 3.2 PSQ-2: Spectral Prediction of Metal Concentrations

#### Hypothesis
> H2: Spectral features (Fe-oxides, organics, carbonates) correlate with Pb, Zn, Cu (R² > 0.5)

#### Required Data
```r
df_psq2 <- df_analysis %>%
  filter(!is.na(R_350nm)) %>%  # Has ASD data
  select(Base_ID,
         # Response variables
         Pb_ppm, Zn_ppm, Cu_ppm, As_ppm, Fe_ppm,
         # Predictor: full ASD spectrum
         starts_with("R_"),
         # Predictor: derived features
         Slope_VIS, Slope_NIR, Depth_480nm, Depth_530nm,
         Depth_670nm, Depth_870nm, Depth_2300nm,
         Fe_index, Carbonate_index, Char_index, Overall_albedo)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | Spectral preprocessing | `prospectr` | Smoothed, derivatives |
| 2 | Continuum removal | `prospectr` | Normalized absorption depths |
| 3 | Feature extraction | Custom | Absorption depths, indices |
| 4 | PLSR model fitting | `pls` | Calibration models |
| 5 | Cross-validation (LOOCV) | `pls` | R², RMSECV |
| 6 | Variable importance (VIP) | `pls` | Key wavelengths |
| 7 | Random Forest regression | `ranger` | Comparison model |
| 8 | Feature importance | `ranger` | Top predictors |

#### PLSR Model Specification
```r
# For each target metal (Pb, Zn, Cu, As)
library(pls)

# Using full spectrum
plsr_Pb_full <- plsr(log(Pb_ppm) ~ .,
                     data = df_spectra,
                     ncomp = 10,
                     validation = "LOO",
                     scale = TRUE)

# Using extracted features only
plsr_Pb_features <- plsr(log(Pb_ppm) ~ Slope_VIS + Slope_NIR +
                           Depth_480nm + Depth_530nm + Depth_670nm +
                           Depth_870nm + Depth_2300nm + Fe_index +
                           Carbonate_index + Char_index,
                         data = df_features,
                         ncomp = 5,
                         validation = "LOO")

# Select optimal components via RMSEP minimum
ncomp_opt <- which.min(RMSEP(plsr_Pb_full)$val[1, 1, ])
```

#### Random Forest Comparison
```r
library(ranger)

rf_Pb <- ranger(log(Pb_ppm) ~ .,
                data = df_features,
                num.trees = 500,
                importance = "permutation",
                mtry = 3)

# Extract importance
importance_Pb <- importance(rf_Pb) %>%
  sort(decreasing = TRUE) %>%
  head(10)
```

#### Success Criteria
- [x] PLSR R²cv > 0.5 for at least one metal (Pb, Zn, or Cu)
- [x] VIP identifies wavelengths consistent with mineralogical interpretation
- [x] RF and PLSR show consistent top features

#### Expected Key Features
| Feature | Expected Association | Physical Basis |
|---------|---------------------|----------------|
| Depth_670nm | Fe, Cu, As | Fe-oxide hosting |
| Depth_870nm | Fe, As | Goethite/hematite |
| Depth_2300nm | Ca, Sr, Ba | Carbonate fraction |
| Char_index | Organic-bound metals | Incomplete combustion |
| Slope_VIS | Total metal loading | Overall darkness |

---

### 3.3 PSQ-3: Mineralogical Metal Hosting (ATR-FTIR)

#### Hypothesis
> H3: ATR-FTIR reveals carbonates, Fe-oxides, and amorphous phases as primary metal hosts

#### Required Data
```r
df_psq3 <- df_analysis %>%
  filter(!is.na(Carbonate_1420)) %>%  # Has FTIR data
  select(Base_ID,
         # Metals
         Pb_ppm, Zn_ppm, Cu_ppm, Ca_ppm, Fe_ppm, Al_ppm,
         # FTIR mineral indices
         Carbonate_1420, Carbonate_870, Silicate_1000,
         Organic_CH, Organic_aromatic, Fe_oxide_600,
         Glass_amorphous, Phosphate_1050,
         # Major element context
         CaO_pct, SiO2_pct, Fe2O3_pct)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | FTIR peak identification | `ChemoSpec` | Mineral assignments |
| 2 | Peak area integration | Custom | Mineral abundance proxies |
| 3 | Correlation matrix | `corrplot` | Fig 7: Mineral-metal correlations |
| 4 | Partial correlations | `ppcor` | Control for matrix effects |
| 5 | Multiple regression | `stats` | Metal ~ Mineral predictors |
| 6 | Cluster analysis | `factoextra` | Mineral assemblage groups |

#### Mineral-Metal Association Tests
```r
# Correlation matrix
cor_matrix <- df_psq3 %>%
  select(Pb_ppm, Zn_ppm, Cu_ppm,
         Carbonate_1420, Silicate_1000, Organic_aromatic, Fe_oxide_600) %>%
  cor(use = "pairwise.complete.obs", method = "spearman")

# Partial correlations controlling for CaO
library(ppcor)
pcor_Pb_carbonate <- pcor.test(df_psq3$Pb_ppm,
                                df_psq3$Carbonate_1420,
                                df_psq3$CaO_pct)

# Multiple regression for metal partitioning
lm_Pb_minerals <- lm(log(Pb_ppm) ~ Carbonate_1420 + Silicate_1000 +
                       Organic_aromatic + Fe_oxide_600 + Glass_amorphous,
                     data = df_psq3)
```

#### Success Criteria
- [x] Significant correlations (p < 0.05) between mineral indices and metal concentrations
- [x] Multiple regression explains >30% of metal variance
- [x] Consistent mineral-metal associations across multiple metals

---

### 3.4 SSQ-1: AVIRIS Charash Validation

#### Hypothesis
> H4: Char fraction correlates with elevated metals due to incomplete combustion

#### Required Data
```r
df_ssq1 <- df_analysis %>%
  filter(!is.na(Charash_fraction)) %>%
  select(Base_ID, Lat, Lon,
         Charash_fraction, dNBR, PC1, PC2, PC3,
         Pb_ppm, Zn_ppm, Cu_ppm, Sum_Metals_ppm,
         Total_Toxics_ppm, N_exceedances)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | Extract AVIRIS at sample points | `terra`, `sf` | Point values |
| 2 | Scatter plots with regression | `ggplot2` | Fig 8: Charash vs metals |
| 3 | Pearson/Spearman correlation | `stats` | Correlation coefficients |
| 4 | Bootstrap confidence intervals | `boot` | CI for correlations |
| 5 | Multiple regression | `stats` | AVIRIS predictors of metals |

#### Code Template
```r
library(terra)
library(sf)

# Load AVIRIS charash raster
charash <- rast("Data/AVIRIS/charash/eaton_1_charash_fraction.tif")
dnbr <- rast("Data/AVIRIS/dnbr/COG_Eaton_dNBR.tif")

# Create sample points
pts <- st_as_sf(df_master, coords = c("Lon", "Lat"), crs = 4326)
pts <- st_transform(pts, crs(charash))

# Extract values
df_ssq1$Charash_fraction <- extract(charash, pts)[, 2]
df_ssq1$dNBR <- extract(dnbr, pts)[, 2]

# Correlation analysis
cor.test(df_ssq1$Charash_fraction, log(df_ssq1$Pb_ppm), method = "spearman")
cor.test(df_ssq1$dNBR, log(df_ssq1$Total_Toxics_ppm), method = "spearman")
```

#### Success Criteria
- [x] Significant correlation (p < 0.05) between charash fraction and at least one metal
- [x] R² > 0.3 for AVIRIS-metal relationship
- [x] dNBR shows expected relationship with contamination

---

### 3.5 SSQ-2: Spectral Endmember Classification

#### Hypothesis
> H5: PCA of ASD spectra reveals 3+ clusters matching ICP-MS geochemical groups

#### Required Data
```r
df_ssq2 <- df_analysis %>%
  filter(!is.na(R_350nm)) %>%
  select(Base_ID,
         # Full ASD spectrum for PCA
         starts_with("R_"),
         # Geochemical grouping variables
         CaO_pct, SiO2_pct, Fe2O3_pct,
         Pb_ppm, Zn_ppm, Ca_ppm, Fe_ppm,
         Metal_Load_Class)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | Spectral PCA | `stats` | PC scores and loadings |
| 2 | Determine # clusters | `NbClust` | Optimal k |
| 3 | K-means clustering | `stats` | Spectral groups |
| 4 | Geochemical PCA | `stats` | Chemical groups |
| 5 | Cross-tabulation | `base` | Spectral vs chemical groups |
| 6 | Discriminant analysis | `MASS` | Classification accuracy |
| 7 | Silhouette analysis | `cluster` | Cluster quality |

#### Code Template
```r
# Spectral PCA
spectra_matrix <- df_ssq2 %>% select(starts_with("R_")) %>% as.matrix()
pca_spectra <- prcomp(spectra_matrix, scale. = TRUE)

# Determine optimal clusters
library(NbClust)
nb <- NbClust(pca_spectra$x[, 1:5], method = "kmeans",
              min.nc = 2, max.nc = 6)

# K-means clustering
k_opt <- 3  # or from NbClust
km_spectra <- kmeans(pca_spectra$x[, 1:5], centers = k_opt, nstart = 25)
df_ssq2$Spectral_cluster <- factor(km_spectra$cluster)

# Geochemical PCA for comparison
geochem_matrix <- df_ssq2 %>%
  select(CaO_pct, SiO2_pct, Fe2O3_pct, Pb_ppm, Zn_ppm) %>%
  mutate(across(ends_with("_ppm"), log)) %>%
  as.matrix()
pca_geochem <- prcomp(geochem_matrix, scale. = TRUE)

# Cross-tabulation
km_geochem <- kmeans(pca_geochem$x[, 1:3], centers = k_opt, nstart = 25)
df_ssq2$Geochem_cluster <- factor(km_geochem$cluster)

table(df_ssq2$Spectral_cluster, df_ssq2$Geochem_cluster)

# Classification accuracy via LDA
library(MASS)
lda_model <- lda(Geochem_cluster ~ .,
                  data = df_ssq2 %>% select(Geochem_cluster, starts_with("R_")))
pred <- predict(lda_model)
mean(pred$class == df_ssq2$Geochem_cluster)  # Accuracy
```

#### Success Criteria
- [x] ≥3 distinct spectral clusters identified
- [x] Spectral clusters correspond to geochemical groups (>60% overlap)
- [x] LDA classification accuracy >70%

---

### 3.6 SSQ-3: Field vs Laboratory Spectroscopy Comparison

#### Hypothesis
> H6: ASD captures Fe/organic features; ATR-FTIR resolves carbonate/silicate mineralogy

#### Required Data
```r
df_ssq3 <- df_analysis %>%
  filter(!is.na(R_350nm) & !is.na(Carbonate_1420)) %>%
  select(Base_ID,
         # ASD features
         Depth_670nm, Depth_870nm, Depth_2300nm,
         Fe_index, Char_index, Overall_albedo,
         # FTIR features
         Carbonate_1420, Carbonate_870, Silicate_1000,
         Organic_aromatic, Fe_oxide_600,
         # Geochemistry for validation
         Fe_ppm, Ca_ppm, SiO2_pct, CaO_pct, Fe2O3_pct)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | Correlation: ASD features vs geochem | `stats` | ASD validation |
| 2 | Correlation: FTIR features vs geochem | `stats` | FTIR validation |
| 3 | Canonical correlation analysis | `CCA` | Shared variance |
| 4 | Unique variance partitioning | `vegan` | Variance explained |
| 5 | Feature complementarity table | Custom | Unique contributions |

#### Code Template
```r
# ASD-Geochemistry correlations
cor_asd <- cor(df_ssq3 %>% select(Depth_670nm, Depth_870nm, Fe_index, Char_index),
               df_ssq3 %>% select(Fe_ppm, Fe2O3_pct),
               use = "pairwise.complete.obs")

# FTIR-Geochemistry correlations
cor_ftir <- cor(df_ssq3 %>% select(Carbonate_1420, Silicate_1000),
                df_ssq3 %>% select(CaO_pct, SiO2_pct),
                use = "pairwise.complete.obs")

# Variance partitioning
library(vegan)
rda_full <- rda(df_ssq3 %>% select(Fe_ppm, Ca_ppm, Pb_ppm) %>% scale(),
                df_ssq3 %>% select(starts_with("Depth_"), Fe_index) %>% scale(),
                df_ssq3 %>% select(Carbonate_1420, Silicate_1000) %>% scale())
```

#### Expected Feature Complementarity

| Feature Type | ASD Strength | FTIR Strength |
|--------------|--------------|---------------|
| Iron oxides | **Strong** (670, 870 nm) | Moderate (<700 cm⁻¹) |
| Carbonates | Moderate (2300 nm) | **Strong** (1420, 870 cm⁻¹) |
| Silicates | Weak | **Strong** (1000 cm⁻¹) |
| Organics/char | **Strong** (VIS slope) | **Strong** (C-H, aromatic) |
| Clays | Moderate (2200 nm) | Moderate |
| Overall composition | Albedo/brightness | Mineral assemblage |

---

### 3.7 SSQ-4: XRF vs ICP-MS Method Comparison

#### Hypothesis
> H7: XRF accurately screens metals >100 ppm (RMSE <20%) but underestimates trace levels

#### Required Data
```r
df_ssq4 <- df_master %>%
  filter(!is.na(Pb_ppm) & !is.na(Pb_xrf_ppm)) %>%  # Has both measurements
  select(Base_ID,
         # ICP-MS values (reference)
         Pb_ppm, Zn_ppm, Cu_ppm, Fe_ppm, Mn_ppm, Ca_ppm,
         # XRF values (test)
         Pb_xrf_ppm, Zn_xrf_ppm, Cu_xrf_ppm, Fe_xrf_pct, Mn_xrf_ppm, Ca_xrf_pct)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | Paired scatter plots | `ggplot2` | Visual comparison |
| 2 | Deming regression | `deming` | Proportional bias |
| 3 | Bland-Altman analysis | `BlandAltmanLeh` | Mean difference, LOA |
| 4 | RMSE by concentration range | Custom | Table 5 |
| 5 | Detection limit analysis | Custom | Threshold identification |
| 6 | Recommendations | - | Field screening guidelines |

#### Code Template
```r
library(BlandAltmanLeh)
library(deming)

# Bland-Altman for Pb
ba_Pb <- bland.altman.stats(df_ssq4$Pb_ppm, df_ssq4$Pb_xrf_ppm)
# Mean difference, upper/lower limits of agreement

# Deming regression (accounts for error in both variables)
dem_Pb <- deming(Pb_ppm ~ Pb_xrf_ppm, data = df_ssq4)
# Slope, intercept, confidence intervals

# RMSE by concentration range
df_ssq4 %>%
  mutate(Pb_range = cut(Pb_ppm, breaks = c(0, 100, 500, 1000, Inf),
                        labels = c("<100", "100-500", "500-1000", ">1000"))) %>%
  group_by(Pb_range) %>%
  summarise(
    n = n(),
    RMSE = sqrt(mean((Pb_ppm - Pb_xrf_ppm)^2)),
    RMSE_pct = RMSE / mean(Pb_ppm) * 100,
    Bias = mean(Pb_xrf_ppm - Pb_ppm)
  )
```

#### Success Criteria
- [x] Deming regression slope 0.8-1.2 for elements >100 ppm
- [x] RMSE <20% for high-concentration samples
- [x] Clear threshold identified where XRF becomes unreliable

---

### 3.8 SSQ-5: Burn Severity vs Metal Contamination

#### Hypothesis
> H8: Higher dNBR correlates with metal enrichment due to more complete structure destruction

#### Required Data
```r
df_ssq5 <- df_analysis %>%
  filter(!is.na(dNBR)) %>%
  select(Base_ID, Lat, Lon,
         dNBR, NBR_prefire, NBR_postfire, Charash_fraction,
         Sum_Metals_ppm, Total_Toxics_ppm, Pb_ppm, Zn_ppm,
         N_exceedances, Metal_Load_Class)
```

#### Analysis Protocol

| Step | Method | R Package | Output |
|------|--------|-----------|--------|
| 1 | dNBR extraction at points | `terra` | dNBR values |
| 2 | Scatter plot: dNBR vs metals | `ggplot2` | Visual relationship |
| 3 | Spearman correlation | `stats` | ρ and p-value |
| 4 | ANOVA by burn severity class | `stats` | Categorical comparison |
| 5 | Mixed consideration of structure density | Custom | Confounding assessment |

#### Code Template
```r
# Categorize burn severity
df_ssq5 <- df_ssq5 %>%
  mutate(Burn_severity = case_when(
    dNBR < 0.1 ~ "Unburned",
    dNBR < 0.27 ~ "Low",
    dNBR < 0.44 ~ "Moderate-Low",
    dNBR < 0.66 ~ "Moderate-High",
    TRUE ~ "High"
  ))

# Correlation
cor.test(df_ssq5$dNBR, log(df_ssq5$Total_Toxics_ppm), method = "spearman")

# ANOVA
aov_metals <- aov(log(Total_Toxics_ppm) ~ Burn_severity, data = df_ssq5)
TukeyHSD(aov_metals)
```

#### Important Consideration
dNBR in WUI settings reflects both:
1. Vegetation burn severity (spectral change)
2. Structure destruction (different spectral signature)

May need to interpret carefully or use structure-specific indices.

---

## 4. DATA QUALITY CONTROL

### 4.1 QC Checklist

| Check | Method | Threshold | Action if Failed |
|-------|--------|-----------|------------------|
| Missing data | `is.na()` | <10% per variable | Impute or exclude |
| Duplicate IDs | `duplicated()` | 0 | Resolve manually |
| Coordinate validity | Range check | 34.1-34.3°N, 118.0-118.3°W | Flag for review |
| ICP-MS totals | Sum check | 80-120% of reported | Flag for review |
| XRF closure | Sum oxides | 95-105% | Normalize or flag |
| Spectral range | Min/max reflectance | 0-1 (ASD) | Rescale or flag |
| FTIR baseline | Absorbance range | 0-2 typical | Baseline correct |
| Outliers | IQR method | >3× IQR | Investigate, retain if real |

### 4.2 Data Transformation Requirements

| Variable Type | Transformation | Rationale |
|---------------|----------------|-----------|
| Metal concentrations | log10 | Right-skewed, span orders of magnitude |
| XRF major oxides | None or CLR | Compositional data, closure |
| ASD reflectance | Continuum removal, 1st derivative | Feature enhancement |
| FTIR absorbance | Baseline correction, normalization | Comparability |
| Coordinates | UTM Zone 11N | Distance calculations |

### 4.3 Coordinate Reference Systems

| Dataset | Native CRS | Transform To |
|---------|------------|--------------|
| Sample GPS | WGS84 (EPSG:4326) | Keep for mapping |
| AVIRIS | UTM Zone 11N (EPSG:32611) | Match for extraction |
| Output maps | WGS84 | Publication standard |

---

## 5. OUTPUT DELIVERABLES

### 5.1 Data Products

| File | Format | Contents |
|------|--------|----------|
| `df_master.csv` | CSV | Harmonized geochemistry |
| `df_asd_features.csv` | CSV | Extracted ASD features |
| `df_ftir_features.csv` | CSV | Extracted FTIR features |
| `df_aviris_extracted.csv` | CSV | AVIRIS point extractions |
| `df_analysis_tier1.csv` | CSV | Complete cases for analysis |
| `model_plsr_Pb.rds` | RDS | Fitted PLSR model for Pb |
| `model_rf_metals.rds` | RDS | Random Forest model |

### 5.2 Analysis Scripts

| Script | Purpose |
|--------|---------|
| `01_data_harmonization.R` | Join all datasets, QC |
| `02_spectral_preprocessing.R` | ASD/FTIR feature extraction |
| `03_geochemical_analysis.R` | PSQ-1 statistics and maps |
| `04_spectral_prediction.R` | PSQ-2 PLSR/RF models |
| `05_mineral_associations.R` | PSQ-3 FTIR analysis |
| `06_aviris_validation.R` | SSQ-1 and SSQ-5 |
| `07_clustering_endmembers.R` | SSQ-2 classification |
| `08_method_comparison.R` | SSQ-3 and SSQ-4 |
| `09_generate_figures.R` | All publication figures |

---

## 6. SUMMARY: HYPOTHESIS → DATA → ANALYSIS MAPPING

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         HYPOTHESIS TESTING FLOWCHART                         │
└─────────────────────────────────────────────────────────────────────────────┘

PSQ-1: Metal contamination levels
│
├── DATA: df_master [ICP-MS + GPS]
├── ANALYSIS: Descriptive stats, exceedance %, spatial clustering
└── OUTPUT: Table 2-3, Fig 2-3

PSQ-2: Spectral prediction of metals
│
├── DATA: df_analysis [ASD + ICP-MS] (TIER 1, n≈30)
├── ANALYSIS: PLSR, Random Forest, cross-validation
└── OUTPUT: Table 4, Fig 4-5

PSQ-3: Mineralogical metal hosting
│
├── DATA: df_analysis [ATR-FTIR + ICP-MS] (TIER 1, n≈30)
├── ANALYSIS: Correlation, partial correlation, multiple regression
└── OUTPUT: Fig 6-7

SSQ-1: AVIRIS charash validation
│
├── DATA: df_analysis [AVIRIS + ICP-MS]
├── ANALYSIS: Point extraction, correlation, regression
└── OUTPUT: Fig 8

SSQ-2: Spectral endmembers
│
├── DATA: df_analysis [ASD full spectra + ICP-MS]
├── ANALYSIS: PCA, k-means, LDA
└── OUTPUT: Fig 4 (endmember spectra)

SSQ-3: Field vs lab spectroscopy
│
├── DATA: df_analysis [ASD + ATR-FTIR]
├── ANALYSIS: Variance partitioning, complementarity
└── OUTPUT: Discussion section

SSQ-4: XRF vs ICP-MS
│
├── DATA: df_master [paired XRF + ICP-MS]
├── ANALYSIS: Bland-Altman, Deming regression, RMSE
└── OUTPUT: Table 5, Fig 9

SSQ-5: Burn severity relationship
│
├── DATA: df_analysis [AVIRIS dNBR + ICP-MS]
├── ANALYSIS: Correlation, ANOVA by severity class
└── OUTPUT: Fig 8 (combined with SSQ-1)

┌─────────────────────────────────────────────────────────────────────────────┐
│                              KEY SAMPLE COUNTS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  TIER 1 (complete data):     ~30 samples  → Primary analyses                │
│  TIER 2 (partial data):      ~10 samples  → Geochemistry only               │
│  Controls (soil):              3 samples  → Background reference            │
│  Total:                       ~43 samples                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

*Document created: December 3, 2025*
*Version: 1.0*
