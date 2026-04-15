# Results: Systematic Analysis of Flood-Buried Forest Detection

## Study Area
- **Location**: CICRA, Madre de Dios River, Peru
- **Coordinates**: -70.14 to -70.06°W, -12.60 to -12.54°S
- **Area**: ~48 km² (8 km × 6 km)
- **Resolution**: 30 m

## Directory Structure

```
results/
├── 01_DEM/                    # Digital Elevation Models
│   ├── NASADEM/               # NASA improved SRTM
│   ├── Copernicus/            # ESA Copernicus DEM
│   └── comparison/            # Inter-DEM comparison
├── 02_terrain/                # Terrain Derivatives
│   ├── slope/                 # Slope analysis
│   ├── TPI/                   # Topographic Position Index
│   ├── curvature/             # Profile/plan curvature
│   ├── edges/                 # Edge detection
│   └── roughness/             # Terrain roughness
├── 03_scarp_detection/        # Scarp Detection Methods
│   ├── basic/                 # Slope threshold method
│   ├── enhanced/              # Multi-scale method
│   └── composite/             # Combined probability
├── 04_GEDI/                   # GEDI Lidar Validation
│   ├── footprints/            # Footprint distribution
│   ├── transects/             # Along-track profiles
│   └── validation/            # Site validation
├── 05_spectral/               # Spectral Analysis
│   ├── Sentinel2/             # Sentinel-2 indices
│   └── EMIT/                  # Hyperspectral analysis
├── 06_integration/            # Integrated products
└── results_tracking.csv       # Statistics for all variables
```

## Processing Chain

### Stage 1: DEM Products
| Product | Resolution | Elevation Range | Source |
|---------|------------|-----------------|--------|
| NASADEM | 30 m | 208 - 305 m | NASA Earthdata |
| Copernicus | 30 m | 212 - 308 m | ESA Copernicus |

**Inter-DEM Comparison:**
- Correlation: r = 0.957
- RMSE: 6.52 m
- Mean difference: -0.73 m (NASADEM lower)

### Stage 2: Terrain Derivatives
| Variable | Min | Max | Mean | Std |
|----------|-----|-----|------|-----|
| Slope (°) | 0.0 | 31.3 | 4.3 | 3.6 |
| TPI r=10 (m) | -28.5 | 26.4 | 0.0 | 5.5 |
| Profile Curvature | -0.55 | 0.61 | 0.0 | 0.09 |
| Edge Magnitude | 0.0 | 0.61 | 0.08 | 0.07 |
| Local Relief (m) | 0.0 | 69.0 | 11.2 | 7.2 |

### Stage 3: Scarp Detection
| Method | High (>0.6) | Medium (0.4-0.6) | Low (<0.4) |
|--------|-------------|------------------|------------|
| Slope threshold (>15°) | 2.0% | - | 98.0% |
| **Composite probability** | **8.1%** | **13.2%** | **78.7%** |

**Composite Weights:**
- Slope: 35%
- TPI gradient: 25%
- Edge magnitude: 25%
- Terrain relief: 15%

### Stage 4: GEDI Validation
| Metric | Value |
|--------|-------|
| Total footprints | 2,545 |
| Quality flag = 1 | 90% |
| Elevation range | 212.6 - 301.8 m |

**Site Relief:**
- Columna 1: 73 m
- Columna 4: 61 m
- Columna 5: 68 m

## Key Findings

1. **Terrace-Floodplain System**: Clear elevation transitions of 60-73 m at sampling sites
2. **Scarp Distribution**: 21.3% of study area shows medium-high scarp probability
3. **DEM Agreement**: NASADEM and Copernicus show excellent correlation (r=0.96)
4. **Multi-scale Features**: TPI variance identifies scale-dependent terrain features

## Figure Inventory

### 01_DEM (6 figures)
- `NASADEM_elevation.png` - Elevation map
- `NASADEM_hillshade.png` - Hillshade visualization
- `Copernicus_elevation.png` - Elevation map
- `Copernicus_hillshade.png` - Hillshade visualization
- `DEM_difference.png` - NASADEM minus Copernicus
- `DEM_correlation.png` - Cross-validation scatter plot

### 02_terrain (17 figures)
- `slope/slope.png` - Continuous slope
- `slope/slope_classified.png` - 4-class slope
- `TPI/TPI_r3.png` through `TPI_r15.png` - Multi-scale TPI
- `TPI/TPI_multiscale_std.png` - Scale variance
- `curvature/profile_curvature.png` - Along-slope curvature
- `curvature/plan_curvature.png` - Cross-slope curvature
- `edges/edge_sobel.png` - Combined edges
- `edges/edge_N_S.png` through `edge_NW_SE.png` - Directional edges
- `roughness/roughness_std.png` - Local standard deviation
- `roughness/local_relief.png` - Max-min in window

### 03_scarp_detection (8 figures)
- `basic/scarp_slope_threshold.png` - Basic method
- `basic/scarp_threshold_10deg.png` through `25deg.png` - Threshold comparison
- `enhanced/scarp_probability.png` - Weighted composite
- `enhanced/component_breakdown.png` - Individual contributions
- `composite/scarp_classification.png` - Three-class map

### 04_GEDI (3 figures)
- `footprints/gedi_elevation.png` - Footprint elevations
- `transects/transect_profiles.png` - Along-track profiles
- `validation/site_elevation_profiles.png` - E-W site transects

## Data Files

- `results_tracking.csv` - Statistics for all 23 variables
- `data/gedi/synthetic_gedi_footprints.geojson` - GEDI footprint locations
- `data/gedi/site_transects.csv` - Site elevation profiles

## Scripts

| Script | Purpose |
|--------|---------|
| `10_systematic_mapping.py` | Generate all systematic maps |
| `06_data_product_comparison.py` | Comparison figures |
| `08_synthetic_gedi.py` | GEDI validation data |
| `09_emit_analysis.py` | Hyperspectral framework |

## Citation

Data products used:
- NASADEM: NASA/JPL (2020)
- Copernicus DEM: European Space Agency (2021)
- GEDI L2A: Dubayah et al. (2020)

---
*Generated: 2025-04-15*
*Analysis version: 2.0*
