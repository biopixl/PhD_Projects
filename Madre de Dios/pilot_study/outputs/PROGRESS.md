# Processing Progress & Variable Status
## CICRA Flood-Buried Forest Carbon Pilot Study

**Auto-updated:** 2026-04-15
**Pipeline Version:** 1.0

---

## Quick Status Overview

```
╔══════════════════════════════════════════════════════════════════╗
║  DATA ACQUISITION                                                 ║
╠══════════════════════════════════════════════════════════════════╣
║  [████████████████████] DEM Products         100% Complete       ║
║  [████████░░░░░░░░░░░░] GEDI L4A              40% Downloading    ║
║  [████░░░░░░░░░░░░░░░░] EMIT L2A              20% Downloading    ║
║  [░░░░░░░░░░░░░░░░░░░░] Sentinel-2             0% Pending        ║
╠══════════════════════════════════════════════════════════════════╣
║  PROCESSING                                                       ║
╠══════════════════════════════════════════════════════════════════╣
║  [████████████████████] Terrain Derivatives  100% Complete       ║
║  [████████████████████] Scarp Detection      100% Complete       ║
║  [░░░░░░░░░░░░░░░░░░░░] GEDI Processing        0% Waiting        ║
║  [░░░░░░░░░░░░░░░░░░░░] Spectral Analysis      0% Waiting        ║
╠══════════════════════════════════════════════════════════════════╣
║  VISUALIZATION                                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  [████████████████░░░░] Publication Figures   80% Complete       ║
║  [████████░░░░░░░░░░░░] Tracking Maps         40% Partial        ║
║  [░░░░░░░░░░░░░░░░░░░░] Comparison Maps        0% Pending        ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Variable Processing Status

### 1. Elevation Data (DEM)

| Variable | Source | Resolution | Status | GeoTIFF | Map |
|:---------|:-------|:-----------|:------:|:-------:|:---:|
| Elevation | NASADEM | 30m | ✅ | ✅ | ⬜ |
| Elevation | Copernicus | 30m | ✅ | ✅ | ⬜ |
| Elevation | SRTM v3 | 30m | ✅ | ⬜ | ⬜ |

### 2. Terrain Derivatives (from Copernicus DEM)

| Variable | Units | Range | Status | GeoTIFF | Map |
|:---------|:------|:------|:------:|:-------:|:---:|
| Slope | degrees | 0-35° | ✅ | ✅ | ✅ |
| Aspect | degrees | 0-360° | ✅ | ✅ | ⬜ |
| Hillshade | 0-255 | - | ✅ | ✅ | ⬜ |
| Profile Curvature | 1/m | ±0.05 | ✅ | ✅ | ⬜ |
| Plan Curvature | 1/m | ±0.05 | ✅ | ✅ | ⬜ |
| TRI | index | 0-10 | ✅ | ✅ | ⬜ |
| Landform Class | categorical | 1-8 | ✅ | ✅ | ⬜ |

### 3. Topographic Position Index (Multi-scale)

| Scale | Radius | Purpose | Status | GeoTIFF | Map |
|:------|:-------|:--------|:------:|:-------:|:---:|
| Fine | 90m (3 cells) | Local features | ✅ | ✅ | ⬜ |
| Medium | 150m (5 cells) | Terrace edges | ✅ | ✅ | ⬜ |
| Coarse | 300m (10 cells) | Terrace surfaces | ✅ | ✅ | ⬜ |
| Broad | 450m (15 cells) | Regional context | ✅ | ✅ | ⬜ |
| Multi-scale composite | Combined | Feature detection | ✅ | ✅ | ⬜ |
| TPI Variance | All scales | Scale selection | ✅ | ✅ | ⬜ |

### 4. Enhanced Terrain Analysis

| Variable | Method | Status | GeoTIFF | Map |
|:---------|:-------|:------:|:-------:|:---:|
| Enhanced Slope | Multi-direction | ✅ | ✅ | ⬜ |
| Edge Magnitude | Sobel filter | ✅ | ✅ | ⬜ |
| Terrain Range | Local relief | ✅ | ✅ | ⬜ |
| Multi-dir Hillshade | 4-direction | ✅ | ✅ | ⬜ |

### 5. Scarp Detection Products

| Product | Threshold | Coverage | Status | GeoTIFF | Map |
|:--------|:----------|:---------|:------:|:-------:|:---:|
| Basic Probability | 0-1 | Full AOI | ✅ | ✅ | ✅ |
| Enhanced Probability | 0-1 | Full AOI | ✅ | ✅ | ✅ |
| High Confidence | >0.6 | 8.1% | ✅ | Derived | ✅ |
| Medium Confidence | 0.4-0.6 | 13.2% | ✅ | Derived | ✅ |
| Scarp Centerlines | Vector | - | ⬜ | - | ⬜ |
| Terrace Polygons | Vector | - | ⬜ | - | ⬜ |

### 6. GEDI Lidar Products

| Product | Version | Orbits | Status | Processed | Map |
|:--------|:--------|:-------|:------:|:---------:|:---:|
| L4A AGB Density | V2.1 | 44 files | 🔄 | ⬜ | ⬜ |
| L2A Canopy Height | V2 | - | ⬜ | ⬜ | ⬜ |
| Footprint Coverage | - | - | ⬜ | ⬜ | ⬜ |
| AGB per Terrace Level | - | - | ⬜ | ⬜ | ⬜ |

### 7. EMIT Hyperspectral Products

| Product | Bands | Status | Processed | Map |
|:--------|:------|:------:|:---------:|:---:|
| L2A Reflectance | 285 | 🔄 | ⬜ | ⬜ |
| Quality Masks | - | 🔄 | ⬜ | ⬜ |
| Cellulose Index | 2100nm | ⬜ | ⬜ | ⬜ |
| Lignin Index | 2270nm | ⬜ | ⬜ | ⬜ |
| Clay Index | 2200nm | ⬜ | ⬜ | ⬜ |
| Site Spectra | All | ⬜ | ⬜ | ⬜ |

### 8. Sentinel-2 Spectral Indices

| Index | Formula | Purpose | Status | GeoTIFF | Map |
|:------|:--------|:--------|:------:|:-------:|:---:|
| NDVI | (NIR-R)/(NIR+R) | Vegetation | ⬜ | ⬜ | ⬜ |
| NDWI | (G-NIR)/(G+NIR) | Moisture | ⬜ | ⬜ | ⬜ |
| NBR | (NIR-SWIR)/(NIR+SWIR) | Bare soil | ⬜ | ⬜ | ⬜ |
| SOCI | (R-B)/(R+B) | Organic carbon | ⬜ | ⬜ | ⬜ |
| BSI | Complex | Bare soil | ⬜ | ⬜ | ⬜ |

---

## Validation Status

### Ground Truth Sites

| Site | Profile | Terrain | GEDI | EMIT | Spectral | Field |
|:-----|:-------:|:-------:|:----:|:----:|:--------:|:-----:|
| COLUMNA_1_CICRA | ✅ | ✅ | ⬜ | ⬜ | ⬜ | 📅 |
| COLUMNA_4_CICRA | ✅ | ✅ | ⬜ | ⬜ | ⬜ | 📅 |
| COLUMNA_5_LOS_AMIGOS | ✅ | ✅ | ⬜ | ⬜ | ⬜ | 📅 |
| TOBA_PATRICE_PM | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📅 |
| TRONCOS_PM | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 📅 |

### Cross-Validation Comparisons

| Comparison | Purpose | Status | Figure |
|:-----------|:--------|:------:|:------:|
| NASADEM vs Copernicus | DEM accuracy | ✅ | ✅ |
| Basic vs Enhanced Scarp | Method comparison | ⬜ | ⬜ |
| Terrain vs GEDI | Height validation | ⬜ | ⬜ |
| Scarp prob vs EMIT | Spectral validation | ⬜ | ⬜ |
| Scarp prob vs NDVI | Vegetation correlation | ⬜ | ⬜ |

---

## Map Output Inventory

### maps/dem/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_DEM_nasadem.png` | ⬜ | |
| `Map_DEM_copernicus.png` | ⬜ | |
| `Map_DEM_srtm.png` | ⬜ | |

### maps/terrain/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_terrain_slope.png` | ⬜ | |
| `Map_terrain_aspect.png` | ⬜ | |
| `Map_terrain_tpi.png` | ⬜ | |
| `Map_terrain_hillshade.png` | ⬜ | |
| `Map_terrain_landform.png` | ⬜ | |
| `Map_terrain_curvature.png` | ⬜ | |

### maps/scarp/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_scarp_probability.png` | ⬜ | |
| `Map_scarp_probability_enhanced.png` | ⬜ | |
| `Map_scarp_classification.png` | ⬜ | |

### maps/gedi/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_GEDI_footprints.png` | ⬜ | Waiting for download |
| `Map_GEDI_AGB.png` | ⬜ | |
| `Map_GEDI_canopy_height.png` | ⬜ | |

### maps/emit/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_EMIT_true_color.png` | ⬜ | Waiting for download |
| `Map_EMIT_cellulose.png` | ⬜ | |
| `Map_EMIT_lignin.png` | ⬜ | |

### maps/sentinel/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_S2_NDVI.png` | ⬜ | Waiting for download |
| `Map_S2_NDWI.png` | ⬜ | |
| `Map_S2_NBR.png` | ⬜ | |

### maps/comparison/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_DEM_comparison.png` | ⬜ | |
| `Map_scarp_method_comparison.png` | ⬜ | |
| `Map_multiproduct_overlay.png` | ⬜ | |

### maps/validation/
| File | Generated | Notes |
|:-----|:---------:|:------|
| `Map_sampling_locations.png` | ⬜ | |
| `Map_transect_profiles.png` | ⬜ | |

---

## Status Legend

| Symbol | Meaning |
|:------:|:--------|
| ✅ | Complete |
| 🔄 | In Progress |
| ⬜ | Pending |
| ❌ | Failed/Error |
| 📅 | Planned |

---

## Recent Activity

| Date | Action | Details |
|:-----|:-------|:--------|
| 2026-04-15 | Data download | GEDI L4A batch download started |
| 2026-04-15 | Data download | EMIT L2A download started |
| 2026-04-15 | Reorganization | Created tracking system |
| 2026-04-14 | Processing | Enhanced terrain analysis complete |
| 2026-04-14 | Processing | Scarp detection complete |
| 2026-04-14 | Visualization | Publication figures generated |

---

## Next Actions

1. **Monitor downloads** - GEDI and EMIT data acquisition in progress
2. **Generate tracking maps** - Run `python scripts/11_generate_tracking_maps.py`
3. **Process GEDI data** - Once download completes
4. **Process EMIT data** - Once download completes
5. **Acquire Sentinel-2** - Via Google Earth Engine

---

*Run `python scripts/11_generate_tracking_maps.py` to regenerate maps and update this file*
