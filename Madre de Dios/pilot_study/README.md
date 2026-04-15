# CICRA Flood-Buried Forest Carbon Pilot Study

## Madre de Dios, Peru

### Overview

This pilot study uses open-source remote sensing data to detect and characterize flood-buried forest deposits at the CICRA research station (Centro de Investigación y Capacitación Río Los Amigos) along the Madre de Dios River in southeastern Peru.

**Research Questions:**
1. What is the magnitude and spatial extent of flooding events that buried extensive in situ forests?
2. Were there multiple, distinct flooding events linked to deglaciation?
3. How much carbon was sequestered through rapid burial of forest biomass?
4. Can remote sensing detect signatures of buried organic deposits along terrace scarps?

### Study Area

**Primary Study Site:** CICRA Station
- Center: 70.100°W, 12.567°S
- Bounding Box: 70.20°W to 70.00°W, 12.67°S to 12.47°S (~20 km × 20 km)

**Sampling Locations:**
| Site | Longitude | Latitude | Description |
|------|-----------|----------|-------------|
| COLUMNA_1_CICRA | -70.10493 | -12.56527 | Columna 1 at CICRA station |
| COLUMNA_4_CICRA | -70.10185 | -12.56905 | Columna 4 at CICRA station |
| COLUMNA_5_LOS_AMIGOS | -70.09063 | -12.55722 | Near Los Amigos confluence |
| TOBA_PATRICE_PM | -69.20528 | -12.57111 | Puerto Maldonado area |
| TRONCOS_PM | -69.19000 | -12.57861 | Fossil logs, Puerto Maldonado |

### Data Products

#### 1. Digital Elevation Models (30m resolution)

| Source | Product | Access |
|--------|---------|--------|
| **OpenTopography** | SRTM 30m, Copernicus 30m | [opentopography.org](https://opentopography.org) (free API key) |
| **NASA EarthData** | NASADEM (improved SRTM) | [earthdata.nasa.gov](https://urs.earthdata.nasa.gov) (free registration) |
| **AWS** | Copernicus DEM 30m | [registry.opendata.aws](https://registry.opendata.aws/copernicus-dem) (public) |

#### 2. Sentinel-2 Multispectral Imagery (10m resolution)

| Source | Access |
|--------|--------|
| **Microsoft Planetary Computer** | [planetarycomputer.microsoft.com](https://planetarycomputer.microsoft.com) (free) |
| **Google Earth Engine** | [earthengine.google.com](https://earthengine.google.com) (free for research) |
| **Copernicus Open Access Hub** | [scihub.copernicus.eu](https://scihub.copernicus.eu) (free registration) |

### Analysis Pipeline

```
01_download_dem.py          → Download/access DEM data
02_terrain_analysis.py      → Compute DTM derivatives (slope, TPI, curvature)
03_scarp_detection.py       → Detect terrace scarps
04_sentinel_spectral.py     → Spectral indices for organic matter
05_visualization.py         → Generate publication figures
```

### Terrain Derivatives

| Derivative | Description | Scarp Detection Use |
|------------|-------------|---------------------|
| **Slope** | Surface steepness (degrees) | Scarps have slopes >15° |
| **TPI** | Topographic Position Index | Terraces: TPI > 2m; Floodplains: TPI < -2m |
| **Profile Curvature** | Curvature in slope direction | Scarp edges are convex/concave |
| **Hillshade** | Shaded relief | Visualization of linear features |

### Spectral Indices

| Index | Formula | Application |
|-------|---------|-------------|
| **NDVI** | (NIR - Red) / (NIR + Red) | Vegetation density |
| **NDWI** | (Green - NIR) / (Green + NIR) | Moisture content |
| **SOCI** | (Red - Blue) / (Red + Blue) | Soil organic carbon indicator |
| **BSI** | ((SWIR + Red) - (NIR + Blue)) / ((SWIR + Red) + (NIR + Blue)) | Bare soil exposure |
| **NBR** | (NIR - SWIR2) / (NIR + SWIR2) | Recently exposed surfaces |

### Directory Structure

```
pilot_study/
├── config.py                 # Study area parameters and thresholds
├── README.md                 # This file
├── data/
│   ├── dem/                  # Digital elevation models
│   ├── sentinel/             # Sentinel-2 imagery
│   └── vectors/              # Vector data (sampling points, scarps)
├── scripts/
│   ├── 01_download_dem.py
│   ├── 02_terrain_analysis.py
│   ├── 03_scarp_detection.py
│   ├── 04_sentinel_spectral.py
│   └── 05_visualization.py
├── outputs/
│   ├── figures/              # Publication figures
│   └── geotiffs/             # Processed rasters
└── notebooks/                # Jupyter notebooks for exploration
```

### Quick Start

```bash
# 1. Install dependencies
pip install rasterio scipy scikit-image matplotlib requests numpy

# 2. Download DEM data
python scripts/01_download_dem.py

# 3. Compute terrain derivatives
python scripts/02_terrain_analysis.py

# 4. Detect scarps
python scripts/03_scarp_detection.py

# 5. Process Sentinel-2 imagery
python scripts/04_sentinel_spectral.py

# 6. Generate figures
python scripts/05_visualization.py
```

### Key Parameters (config.py)

```python
# Slope thresholds for scarp detection
SLOPE_PARAMS = {
    "scarp_min_degrees": 15,   # Minimum for potential scarp
    "scarp_high_degrees": 25,  # High-confidence scarp
    "terrace_max_degrees": 5,  # Maximum for terrace surface
}

# TPI classification
TPI_PARAMS = {
    "outer_radius": 10,        # ~300m neighborhood at 30m resolution
    "terrace_threshold": 2,    # TPI > 2 = elevated terrace
    "floodplain_threshold": -2,# TPI < -2 = low floodplain
}

# Scarp extraction
SCARP_PARAMS = {
    "min_height_m": 2.0,       # Minimum scarp height
    "min_length_m": 50,        # Minimum scarp length
}
```

### Carbon Estimation Parameters

Based on Cranmer et al. (2024) slash wall volume estimation:

| Parameter | Value | Source |
|-----------|-------|--------|
| Wood density (fresh) | 792.9 kg/m³ | Cranmer et al. 2024 |
| Wood density (subfossil) | 400-700 kg/m³ | Estimated range |
| Carbon fraction | 0.47 | Standard wood composition |
| Preservation (100 yr) | >97% | Luo et al. 2025 |
| Preservation (1000 yr) | 50-90% | Estimated range |

### Expected Outputs

1. **Scarp Map (GeoJSON)**: Vector features of detected terrace scarps with attributes:
   - Length, height, slope
   - Orientation (identifies river-perpendicular scarps)
   - Detection confidence

2. **Landform Classification (GeoTIFF)**: Raster classification of:
   - Floodplains (Class 2)
   - Terrace surfaces (Class 6)
   - Scarp zones (Class 3, 7)

3. **Spectral Index Maps**: Indicators of organic matter exposure along scarps

4. **Publication Figures**:
   - Study area overview
   - Terrain derivative panels
   - Scarp detection results
   - Spectral indices comparison

### References

- Asner, G. P., et al. (2013). High-fidelity national carbon mapping for resource management and REDD+. *Carbon Balance and Management*, 8:7.
- Cranmer, J. R., et al. (2024). Slash wall stem characteristics and volume estimation using terrestrial laser scanning. *Forest Ecology and Management*, 571:122211.
- Luo, Y., et al. (2025). Burial of woody debris in rivers supports carbon sequestration. *Nature Geoscience*.

### License

This pilot study code is provided for research purposes.

### Contact

CICRA Study Team
Madre de Dios, Peru
