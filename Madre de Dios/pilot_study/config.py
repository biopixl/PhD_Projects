"""
Configuration for CICRA Flood-Buried Forest Carbon Pilot Study
Madre de Dios, Peru

Study Area: CICRA (Centro de Investigación y Capacitación Río Los Amigos)
Located at confluence of Madre de Dios and Los Amigos rivers
"""

import os
from dataclasses import dataclass
from typing import Tuple, List, Dict

# Project paths
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
DEM_DIR = os.path.join(DATA_DIR, "dem")
SENTINEL_DIR = os.path.join(DATA_DIR, "sentinel")
GEDI_DIR = os.path.join(DATA_DIR, "gedi")
EMIT_DIR = os.path.join(DATA_DIR, "emit")
VECTOR_DIR = os.path.join(DATA_DIR, "vectors")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "outputs")
FIGURE_DIR = os.path.join(OUTPUT_DIR, "figures")
GEOTIFF_DIR = os.path.join(OUTPUT_DIR, "geotiffs")

# Create directories if they don't exist
for d in [DATA_DIR, DEM_DIR, SENTINEL_DIR, GEDI_DIR, EMIT_DIR, VECTOR_DIR, OUTPUT_DIR, FIGURE_DIR, GEOTIFF_DIR]:
    os.makedirs(d, exist_ok=True)

# =============================================================================
# STUDY AREA DEFINITION
# =============================================================================

@dataclass
class SamplingLocation:
    """Field sampling location from KMZ file"""
    name: str
    longitude: float
    latitude: float
    description: str = ""

# Key sampling locations extracted from PDRDF-Madre de Dios area-2024.kmz
SAMPLING_LOCATIONS = [
    SamplingLocation(
        name="COLUMNA_1_CICRA",
        longitude=-70.10493333,
        latitude=-12.56526667,
        description="Columna 1 at CICRA station"
    ),
    SamplingLocation(
        name="COLUMNA_4_CICRA",
        longitude=-70.10185487,
        latitude=-12.56904867,
        description="Columna 4 at CICRA station"
    ),
    SamplingLocation(
        name="COLUMNA_5_LOS_AMIGOS",
        longitude=-70.09063333,
        latitude=-12.55721667,
        description="Columna 5 near Los Amigos confluence"
    ),
    SamplingLocation(
        name="TOBA_PATRICE_PM",
        longitude=-69.20527778,
        latitude=-12.57111111,
        description="Toba Patrice locality near Puerto Maldonado"
    ),
    SamplingLocation(
        name="TRONCOS_PM",
        longitude=-69.19000000,
        latitude=-12.57861111,
        description="Troncos (fossil logs) near Puerto Maldonado"
    ),
]

# CICRA Station coordinates (primary study area)
CICRA_CENTER = (-70.100, -12.567)  # (lon, lat)

# Study area bounding box for CICRA region (primary area)
# Approximately 8 km x 6 km focused on sampling locations
CICRA_BBOX = {
    "west": -70.14,
    "east": -70.06,
    "south": -12.60,
    "north": -12.54,
}

# Extended study area including Puerto Maldonado sites
EXTENDED_BBOX = {
    "west": -70.20,
    "east": -69.10,
    "south": -12.70,
    "north": -12.45,
}

# =============================================================================
# DEM PARAMETERS
# =============================================================================

# SRTM 1-arc second (~30m) tiles covering study area
# Tiles follow SRTM naming convention: N/S latitude, E/W longitude of SW corner
SRTM_TILES = [
    "s13_w071_1arc_v3",  # Covers CICRA area
    "s13_w070_1arc_v3",  # Covers Puerto Maldonado area
]

# NASADEM (improved SRTM) - preferred if available
NASADEM_TILES = [
    "NASADEM_HGT_s13w071",
    "NASADEM_HGT_s13w070",
]

# Copernicus DEM 30m - best freely available global DEM
COPERNICUS_TILES = [
    "Copernicus_DSM_COG_10_S13_00_W071_00_DEM",
    "Copernicus_DSM_COG_10_S13_00_W070_00_DEM",
]

# DEM processing parameters
DEM_PARAMS = {
    "resolution_m": 30,  # Target resolution in meters
    "nodata_value": -9999,
    "vertical_units": "meters",
    "crs": "EPSG:32719",  # UTM Zone 19S for Madre de Dios
}

# =============================================================================
# TERRAIN ANALYSIS PARAMETERS
# =============================================================================

# Slope thresholds for scarp detection
SLOPE_PARAMS = {
    "scarp_min_degrees": 15,  # Minimum slope for potential scarp
    "scarp_high_degrees": 25,  # High-confidence scarp threshold
    "terrace_max_degrees": 5,  # Maximum slope for terrace surface
}

# Curvature parameters
CURVATURE_PARAMS = {
    "profile_threshold": 0.01,  # Profile curvature threshold for scarp edge
    "plan_threshold": 0.005,    # Plan curvature threshold
    "window_size": 3,           # Analysis window (cells)
}

# Topographic Position Index parameters
TPI_PARAMS = {
    "inner_radius": 0,    # Inner radius in cells
    "outer_radius": 10,   # Outer radius in cells (~300m at 30m resolution)
    "terrace_threshold": 2,  # TPI > this = elevated terrace
    "floodplain_threshold": -2,  # TPI < this = low floodplain
}

# Scarp extraction parameters
SCARP_PARAMS = {
    "min_height_m": 2.0,     # Minimum scarp height to detect
    "min_length_m": 50,      # Minimum scarp length
    "max_gap_m": 30,         # Maximum gap for connected scarp segments
    "elevation_band_m": 5,   # Elevation band for terrace correlation
}

# =============================================================================
# SPECTRAL ANALYSIS PARAMETERS (Sentinel-2)
# =============================================================================

SENTINEL_PARAMS = {
    "start_date": "2023-01-01",
    "end_date": "2023-12-31",
    "cloud_cover_max": 20,  # Maximum cloud cover percentage
    "bands": ["B02", "B03", "B04", "B08", "B11", "B12"],  # Blue, Green, Red, NIR, SWIR1, SWIR2
}

# Spectral indices for organic matter detection
SPECTRAL_INDICES = {
    "NDVI": "(B08 - B04) / (B08 + B04)",
    "NDWI": "(B03 - B08) / (B03 + B08)",  # Water/moisture
    "NBR": "(B08 - B12) / (B08 + B12)",   # Burn ratio / bare soil
    "SOCI": "(B04 - B02) / (B04 + B02)",  # Soil Organic Carbon Index (visible only)
    "BSI": "((B11 + B04) - (B08 + B02)) / ((B11 + B04) + (B08 + B02))",  # Bare Soil Index
}

# =============================================================================
# CARBON ESTIMATION PARAMETERS
# =============================================================================

CARBON_PARAMS = {
    # Wood density ranges (kg/m³)
    "wood_density_fresh": 792.9,      # Fresh hardwood (Cranmer et al.)
    "wood_density_subfossil_min": 400,
    "wood_density_subfossil_max": 700,
    "wood_density_subfossil_mean": 550,

    # Carbon fraction
    "carbon_fraction": 0.47,          # Typical wood carbon content

    # Preservation factors (fraction retained)
    "preservation_100yr": 0.97,       # >97% retained for 100 years
    "preservation_1000yr": 0.50,      # 50-90% for 1000 years
    "preservation_min": 0.50,
    "preservation_max": 0.90,

    # Reference values from Cranmer et al. (2024)
    "volume_per_30m_m3": 21.41,       # Average slash wall volume
    "biomass_per_30m_t": 16.97,       # Average dry biomass
    "merchantable_fraction": 0.6653,   # Fraction of large stems (>15.24 cm)
}

# =============================================================================
# VISUALIZATION PARAMETERS
# =============================================================================

VIZ_PARAMS = {
    "figure_dpi": 300,
    "colormap_dem": "terrain",
    "colormap_slope": "YlOrRd",
    "colormap_tpi": "RdBu_r",
    "scarp_color": "red",
    "terrace_color": "green",
    "floodplain_color": "blue",
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def get_bbox_as_tuple(bbox_dict: Dict) -> Tuple[float, float, float, float]:
    """Convert bbox dict to (west, south, east, north) tuple"""
    return (bbox_dict["west"], bbox_dict["south"],
            bbox_dict["east"], bbox_dict["north"])

def get_sampling_coords() -> List[Tuple[float, float]]:
    """Get list of (lon, lat) tuples for all sampling locations"""
    return [(loc.longitude, loc.latitude) for loc in SAMPLING_LOCATIONS]

def print_study_info():
    """Print study area information"""
    print("=" * 60)
    print("CICRA FLOOD-BURIED FOREST CARBON PILOT STUDY")
    print("=" * 60)
    print(f"\nPrimary Study Area: CICRA Station")
    print(f"  Center: {CICRA_CENTER[0]:.4f}°W, {abs(CICRA_CENTER[1]):.4f}°S")
    print(f"  Bounding Box: {CICRA_BBOX}")
    print(f"\nSampling Locations ({len(SAMPLING_LOCATIONS)}):")
    for loc in SAMPLING_LOCATIONS:
        print(f"  - {loc.name}: ({loc.longitude:.4f}, {loc.latitude:.4f})")
    print("=" * 60)

# =============================================================================
# DATA PRODUCT TRACKING
# =============================================================================

@dataclass
class DataProduct:
    """Track status of a data product"""
    name: str
    category: str  # dem, terrain, scarp, gedi, emit, sentinel
    source: str
    status: str  # pending, downloading, processing, complete, error
    geotiff: str = ""
    map_file: str = ""
    notes: str = ""

# Define all tracked data products
DATA_PRODUCTS = {
    # DEMs
    "nasadem": DataProduct("NASADEM", "dem", "NASA EarthData", "complete",
                          "data/dem/nasadem_cicra_30m.tif"),
    "copernicus": DataProduct("Copernicus DEM", "dem", "AWS/ESA", "complete",
                             "data/dem/copernicus_cicra_30m.tif"),
    "srtm": DataProduct("SRTM v3", "dem", "USGS", "complete",
                       "data/dem/s13w071.hgt"),

    # Terrain derivatives
    "slope": DataProduct("Slope", "terrain", "Derived", "complete",
                        "outputs/geotiffs/copernicus_cicra_30m_slope.tif"),
    "aspect": DataProduct("Aspect", "terrain", "Derived", "complete",
                         "outputs/geotiffs/copernicus_cicra_30m_aspect.tif"),
    "tpi": DataProduct("TPI Multi-scale", "terrain", "Derived", "complete",
                      "outputs/geotiffs/copernicus_cicra_30m_tpi.tif"),
    "hillshade": DataProduct("Hillshade", "terrain", "Derived", "complete",
                            "outputs/geotiffs/copernicus_cicra_30m_hillshade.tif"),
    "curvature": DataProduct("Curvature", "terrain", "Derived", "complete",
                            "outputs/geotiffs/copernicus_cicra_30m_profile_curvature.tif"),
    "landform": DataProduct("Landform Class", "terrain", "Derived", "complete",
                           "outputs/geotiffs/copernicus_cicra_30m_landform.tif"),

    # Scarp detection
    "scarp_basic": DataProduct("Scarp Probability (Basic)", "scarp", "Derived", "complete",
                              "outputs/geotiffs/copernicus_cicra_30m_scarp_probability.tif"),
    "scarp_enhanced": DataProduct("Scarp Probability (Enhanced)", "scarp", "Derived", "complete",
                                 "outputs/geotiffs/enhanced_cicra_scarp_probability_enhanced.tif"),

    # Spaceborne lidar
    "gedi_l4a": DataProduct("GEDI L4A AGB", "gedi", "NASA LP DAAC", "downloading",
                           notes="44 files, 2019-2022 orbits"),
    "gedi_l2a": DataProduct("GEDI L2A RH", "gedi", "NASA LP DAAC", "pending"),

    # Hyperspectral
    "emit_l2a": DataProduct("EMIT L2A Reflectance", "emit", "NASA LP DAAC", "downloading"),
    "emit_mask": DataProduct("EMIT Quality Masks", "emit", "NASA LP DAAC", "downloading"),

    # Multispectral
    "sentinel2": DataProduct("Sentinel-2 L2A", "sentinel", "Copernicus/GEE", "pending"),
    "hls": DataProduct("HLS L30/S30", "sentinel", "NASA", "pending"),

    # Enhanced resolution products (from Decadal Survey alignment)
    "fabdem": DataProduct("FABDEM (canopy-removed)", "dem", "Fathom/OpenTopography", "pending",
                         notes="30m, forest canopy bias removed - PRIORITY"),
    "planet_nicfi": DataProduct("Planet NICFI", "optical", "Planet/NICFI", "pending",
                               notes="4.77m tropical forest - FREE"),
    "alos2_mosaic": DataProduct("ALOS-2 PALSAR Mosaic", "sar", "JAXA/GEE", "pending",
                               notes="25m L-band SAR, forest/non-forest"),

    # Future missions (monitoring)
    "nisar": DataProduct("NISAR L+S-band", "sar", "NASA/ISRO", "pending",
                        notes="Launch July 2025, 12m resolution"),
    "biomass": DataProduct("ESA BIOMASS P-band", "sar", "ESA", "pending",
                          notes="Launched April 2025, data 2026"),
    "sbg": DataProduct("NASA SBG Hyperspectral", "hyperspectral", "NASA", "pending",
                      notes="Launch 2027, 30m VSWIR"),
}

# Map output directory structure
MAP_CATEGORIES = {
    "dem": "Digital Elevation Models",
    "terrain": "Terrain Derivatives",
    "scarp": "Scarp Detection",
    "gedi": "GEDI Lidar Products",
    "emit": "EMIT Hyperspectral",
    "sentinel": "Sentinel-2 Spectral",
    "validation": "Validation Maps",
    "comparison": "Product Comparisons",
}

def get_products_by_status(status: str) -> List[DataProduct]:
    """Get all products with a given status"""
    return [p for p in DATA_PRODUCTS.values() if p.status == status]

def get_products_by_category(category: str) -> List[DataProduct]:
    """Get all products in a category"""
    return [p for p in DATA_PRODUCTS.values() if p.category == category]

def print_tracking_summary():
    """Print summary of data product status"""
    print("\n" + "=" * 60)
    print("DATA PRODUCT TRACKING SUMMARY")
    print("=" * 60)

    for status in ["complete", "downloading", "processing", "pending", "error"]:
        products = get_products_by_status(status)
        if products:
            print(f"\n{status.upper()} ({len(products)}):")
            for p in products:
                print(f"  - {p.name} ({p.category})")

    print("=" * 60)

if __name__ == "__main__":
    print_study_info()
    print_tracking_summary()
