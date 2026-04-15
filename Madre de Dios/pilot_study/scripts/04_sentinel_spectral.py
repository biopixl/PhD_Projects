"""
Sentinel-2 Spectral Analysis for CICRA Study
Madre de Dios, Peru

This script accesses Sentinel-2 imagery for spectral analysis of:
1. Exposed terrace surfaces and scarps
2. Organic matter indicators
3. Vegetation and moisture patterns

Data Sources:
- Microsoft Planetary Computer (free, cloud-optimized)
- Google Earth Engine (requires account)
- AWS Sentinel-2 COGs (free)

Spectral Indices:
- SOCI: Soil Organic Carbon Index
- NDVI: Normalized Difference Vegetation Index
- NDWI: Normalized Difference Water Index
- BSI: Bare Soil Index

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
from pathlib import Path
from datetime import datetime
from typing import List, Tuple, Optional

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    SENTINEL_DIR, GEOTIFF_DIR, FIGURE_DIR,
    CICRA_BBOX, EXTENDED_BBOX, SAMPLING_LOCATIONS,
    SENTINEL_PARAMS, SPECTRAL_INDICES
)

try:
    import rasterio
    from rasterio.merge import merge
    from rasterio.mask import mask
except ImportError:
    rasterio = None

try:
    import requests
except ImportError:
    requests = None


# =============================================================================
# PLANETARY COMPUTER ACCESS (Free, no authentication required for browsing)
# =============================================================================

PLANETARY_COMPUTER_API = "https://planetarycomputer.microsoft.com/api/stac/v1"

def search_sentinel2_planetary(bbox: dict, start_date: str, end_date: str,
                                cloud_cover_max: int = 20) -> List[dict]:
    """
    Search for Sentinel-2 scenes via Microsoft Planetary Computer STAC API.

    Parameters:
    -----------
    bbox : dict
        Bounding box with keys: west, east, south, north
    start_date : str
        Start date (YYYY-MM-DD)
    end_date : str
        End date (YYYY-MM-DD)
    cloud_cover_max : int
        Maximum cloud cover percentage

    Returns:
    --------
    list : List of scene metadata dictionaries
    """
    search_url = f"{PLANETARY_COMPUTER_API}/search"

    # STAC search query
    query = {
        "collections": ["sentinel-2-l2a"],
        "bbox": [bbox["west"], bbox["south"], bbox["east"], bbox["north"]],
        "datetime": f"{start_date}/{end_date}",
        "query": {
            "eo:cloud_cover": {"lt": cloud_cover_max}
        },
        "limit": 100
    }

    print(f"Searching Planetary Computer for Sentinel-2 scenes...")
    print(f"  Bbox: {bbox}")
    print(f"  Date range: {start_date} to {end_date}")
    print(f"  Max cloud cover: {cloud_cover_max}%")

    try:
        response = requests.post(search_url, json=query, timeout=60)
        response.raise_for_status()

        results = response.json()
        features = results.get("features", [])

        print(f"  Found {len(features)} scenes")

        return features

    except Exception as e:
        print(f"Error searching Planetary Computer: {e}")
        return []


def get_scene_bands_url(scene: dict, bands: List[str]) -> dict:
    """
    Get URLs for specific bands from a scene.

    Parameters:
    -----------
    scene : dict
        STAC scene feature
    bands : list
        List of band names (e.g., ['B04', 'B03', 'B02'])

    Returns:
    --------
    dict : Band name to URL mapping
    """
    assets = scene.get("assets", {})
    urls = {}

    # Planetary Computer band naming
    band_mapping = {
        "B02": "B02",  # Blue
        "B03": "B03",  # Green
        "B04": "B04",  # Red
        "B08": "B08",  # NIR
        "B11": "B11",  # SWIR1
        "B12": "B12",  # SWIR2
    }

    for band in bands:
        band_key = band_mapping.get(band, band)
        if band_key in assets:
            urls[band] = assets[band_key].get("href")

    return urls


# =============================================================================
# AWS SENTINEL-2 COG ACCESS (Free, public)
# =============================================================================

AWS_SENTINEL_BASE = "https://sentinel-cogs.s3.us-west-2.amazonaws.com"

def construct_sentinel_aws_url(tile: str, date: str, band: str) -> str:
    """
    Construct URL for Sentinel-2 COG on AWS.

    Parameters:
    -----------
    tile : str
        MGRS tile ID (e.g., '19LDF')
    date : str
        Date in YYYY/MM/DD format
    band : str
        Band name (e.g., 'B04')

    Returns:
    --------
    str : COG URL
    """
    # URL format: /sentinel-s2-l2a-cogs/{utm_zone}/{lat_band}/{grid_square}/{year}/{month}/{S2A_or_S2B}/{date}/{band}.tif
    utm_zone = tile[:2]
    lat_band = tile[2]
    grid_square = tile[3:]
    year, month, day = date.split('/')

    return f"{AWS_SENTINEL_BASE}/sentinel-s2-l2a-cogs/{utm_zone}/{lat_band}/{grid_square}/{year}/{month}/{band}.tif"


# =============================================================================
# SPECTRAL INDICES CALCULATION
# =============================================================================

def compute_ndvi(nir: np.ndarray, red: np.ndarray) -> np.ndarray:
    """
    Compute Normalized Difference Vegetation Index.

    NDVI = (NIR - Red) / (NIR + Red)

    Parameters:
    -----------
    nir : np.ndarray
        NIR band (B08)
    red : np.ndarray
        Red band (B04)

    Returns:
    --------
    np.ndarray : NDVI values (-1 to 1)
    """
    with np.errstate(divide='ignore', invalid='ignore'):
        ndvi = (nir.astype(float) - red.astype(float)) / (nir + red)
        ndvi = np.where(np.isfinite(ndvi), ndvi, 0)
    return ndvi


def compute_ndwi(green: np.ndarray, nir: np.ndarray) -> np.ndarray:
    """
    Compute Normalized Difference Water Index.

    NDWI = (Green - NIR) / (Green + NIR)

    Higher values indicate water/moisture.

    Parameters:
    -----------
    green : np.ndarray
        Green band (B03)
    nir : np.ndarray
        NIR band (B08)

    Returns:
    --------
    np.ndarray : NDWI values (-1 to 1)
    """
    with np.errstate(divide='ignore', invalid='ignore'):
        ndwi = (green.astype(float) - nir.astype(float)) / (green + nir)
        ndwi = np.where(np.isfinite(ndwi), ndwi, 0)
    return ndwi


def compute_soci(red: np.ndarray, blue: np.ndarray) -> np.ndarray:
    """
    Compute Soil Organic Carbon Index (visible bands only).

    SOCI = (Red - Blue) / (Red + Blue)

    Higher values may indicate higher organic carbon in exposed soils.

    Parameters:
    -----------
    red : np.ndarray
        Red band (B04)
    blue : np.ndarray
        Blue band (B02)

    Returns:
    --------
    np.ndarray : SOCI values (-1 to 1)
    """
    with np.errstate(divide='ignore', invalid='ignore'):
        soci = (red.astype(float) - blue.astype(float)) / (red + blue)
        soci = np.where(np.isfinite(soci), soci, 0)
    return soci


def compute_bsi(red: np.ndarray, blue: np.ndarray,
                nir: np.ndarray, swir1: np.ndarray) -> np.ndarray:
    """
    Compute Bare Soil Index.

    BSI = ((SWIR1 + Red) - (NIR + Blue)) / ((SWIR1 + Red) + (NIR + Blue))

    Higher values indicate bare soil/exposed surfaces.

    Parameters:
    -----------
    red : np.ndarray
        Red band (B04)
    blue : np.ndarray
        Blue band (B02)
    nir : np.ndarray
        NIR band (B08)
    swir1 : np.ndarray
        SWIR1 band (B11)

    Returns:
    --------
    np.ndarray : BSI values (-1 to 1)
    """
    with np.errstate(divide='ignore', invalid='ignore'):
        numerator = (swir1.astype(float) + red.astype(float)) - (nir + blue)
        denominator = (swir1 + red) + (nir + blue)
        bsi = numerator / denominator
        bsi = np.where(np.isfinite(bsi), bsi, 0)
    return bsi


def compute_nbr(nir: np.ndarray, swir2: np.ndarray) -> np.ndarray:
    """
    Compute Normalized Burn Ratio.

    NBR = (NIR - SWIR2) / (NIR + SWIR2)

    Lower values indicate recently burned or bare areas.

    Parameters:
    -----------
    nir : np.ndarray
        NIR band (B08)
    swir2 : np.ndarray
        SWIR2 band (B12)

    Returns:
    --------
    np.ndarray : NBR values (-1 to 1)
    """
    with np.errstate(divide='ignore', invalid='ignore'):
        nbr = (nir.astype(float) - swir2.astype(float)) / (nir + swir2)
        nbr = np.where(np.isfinite(nbr), nbr, 0)
    return nbr


# =============================================================================
# IMAGE DOWNLOAD AND PROCESSING
# =============================================================================

def download_band(url: str, output_path: str, bbox: dict = None) -> str:
    """
    Download a band from COG using GDAL virtual file system.

    Parameters:
    -----------
    url : str
        COG URL
    output_path : str
        Output file path
    bbox : dict
        Optional bounding box to clip

    Returns:
    --------
    str : Path to downloaded file
    """
    if os.path.exists(output_path):
        print(f"  File exists: {output_path}")
        return output_path

    print(f"  Downloading: {os.path.basename(output_path)}")

    try:
        # Use GDAL to read COG with virtual file system
        vsicurl_url = f"/vsicurl/{url}"

        with rasterio.open(vsicurl_url) as src:
            if bbox:
                # Clip to bounding box
                from rasterio.windows import from_bounds

                window = from_bounds(
                    bbox["west"], bbox["south"],
                    bbox["east"], bbox["north"],
                    src.transform
                )

                data = src.read(1, window=window)
                transform = src.window_transform(window)
            else:
                data = src.read(1)
                transform = src.transform

            # Write output
            profile = src.profile.copy()
            profile.update(
                driver='GTiff',
                height=data.shape[0],
                width=data.shape[1],
                transform=transform,
                compress='lzw'
            )

            with rasterio.open(output_path, 'w', **profile) as dst:
                dst.write(data, 1)

        print(f"    Saved: {output_path}")
        return output_path

    except Exception as e:
        print(f"    Error downloading: {e}")
        return None


def process_sentinel_scene(scene: dict, output_dir: str,
                           bbox: dict = None) -> dict:
    """
    Download and process a Sentinel-2 scene.

    Parameters:
    -----------
    scene : dict
        STAC scene metadata
    output_dir : str
        Output directory
    bbox : dict
        Optional bounding box to clip

    Returns:
    --------
    dict : Paths to processed outputs
    """
    scene_id = scene.get("id", "unknown")
    scene_date = scene.get("properties", {}).get("datetime", "")[:10]

    print(f"\nProcessing scene: {scene_id}")
    print(f"  Date: {scene_date}")

    # Create scene output directory
    scene_dir = os.path.join(output_dir, scene_id)
    os.makedirs(scene_dir, exist_ok=True)

    # Get band URLs
    bands_needed = ["B02", "B03", "B04", "B08", "B11", "B12"]
    band_urls = get_scene_bands_url(scene, bands_needed)

    # Download bands
    band_data = {}
    band_paths = {}

    for band, url in band_urls.items():
        if url:
            output_path = os.path.join(scene_dir, f"{band}.tif")
            result = download_band(url, output_path, bbox)
            if result:
                band_paths[band] = result
                # Read data for index calculation
                with rasterio.open(result) as src:
                    band_data[band] = src.read(1)
                    if 'profile' not in band_data:
                        band_data['profile'] = src.profile.copy()
                        band_data['transform'] = src.transform

    # Compute spectral indices
    outputs = {"bands": band_paths}

    if all(b in band_data for b in ["B04", "B08"]):
        print("  Computing NDVI...")
        ndvi = compute_ndvi(band_data["B08"], band_data["B04"])
        ndvi_path = os.path.join(scene_dir, "NDVI.tif")
        save_index(ndvi, ndvi_path, band_data['profile'])
        outputs['ndvi'] = ndvi_path

    if all(b in band_data for b in ["B03", "B08"]):
        print("  Computing NDWI...")
        ndwi = compute_ndwi(band_data["B03"], band_data["B08"])
        ndwi_path = os.path.join(scene_dir, "NDWI.tif")
        save_index(ndwi, ndwi_path, band_data['profile'])
        outputs['ndwi'] = ndwi_path

    if all(b in band_data for b in ["B02", "B04"]):
        print("  Computing SOCI...")
        soci = compute_soci(band_data["B04"], band_data["B02"])
        soci_path = os.path.join(scene_dir, "SOCI.tif")
        save_index(soci, soci_path, band_data['profile'])
        outputs['soci'] = soci_path

    if all(b in band_data for b in ["B02", "B04", "B08", "B11"]):
        print("  Computing BSI...")
        bsi = compute_bsi(band_data["B04"], band_data["B02"],
                          band_data["B08"], band_data["B11"])
        bsi_path = os.path.join(scene_dir, "BSI.tif")
        save_index(bsi, bsi_path, band_data['profile'])
        outputs['bsi'] = bsi_path

    if all(b in band_data for b in ["B08", "B12"]):
        print("  Computing NBR...")
        nbr = compute_nbr(band_data["B08"], band_data["B12"])
        nbr_path = os.path.join(scene_dir, "NBR.tif")
        save_index(nbr, nbr_path, band_data['profile'])
        outputs['nbr'] = nbr_path

    return outputs


def save_index(data: np.ndarray, output_path: str, profile: dict):
    """Save spectral index to GeoTIFF."""
    out_profile = profile.copy()
    out_profile.update(dtype='float32', count=1, compress='lzw')

    with rasterio.open(output_path, 'w', **out_profile) as dst:
        dst.write(data.astype(np.float32), 1)


# =============================================================================
# ALTERNATIVE: GOOGLE EARTH ENGINE (requires authentication)
# =============================================================================

def gee_code_snippet() -> str:
    """
    Return Google Earth Engine code snippet for Sentinel-2 analysis.

    This can be copied to the GEE Code Editor.
    """
    code = """
// CICRA Study Area - Sentinel-2 Analysis
// Copy this to Google Earth Engine Code Editor

// Define study area
var cicra_bbox = ee.Geometry.Rectangle([-70.20, -12.67, -70.00, -12.47]);

// Sampling locations
var sampling_points = ee.FeatureCollection([
  ee.Feature(ee.Geometry.Point([-70.10493, -12.56527]), {name: 'COLUMNA_1'}),
  ee.Feature(ee.Geometry.Point([-70.10185, -12.56905]), {name: 'COLUMNA_4'}),
  ee.Feature(ee.Geometry.Point([-70.09063, -12.55722]), {name: 'COLUMNA_5'})
]);

// Load Sentinel-2 collection
var s2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(cicra_bbox)
  .filterDate('2023-01-01', '2023-12-31')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20));

print('Available scenes:', s2.size());

// Compute median composite
var composite = s2.median().clip(cicra_bbox);

// Compute spectral indices
var ndvi = composite.normalizedDifference(['B8', 'B4']).rename('NDVI');
var ndwi = composite.normalizedDifference(['B3', 'B8']).rename('NDWI');
var soci = composite.normalizedDifference(['B4', 'B2']).rename('SOCI');

// Bare Soil Index
var bsi = composite.expression(
  '((SWIR + RED) - (NIR + BLUE)) / ((SWIR + RED) + (NIR + BLUE))',
  {
    'SWIR': composite.select('B11'),
    'RED': composite.select('B4'),
    'NIR': composite.select('B8'),
    'BLUE': composite.select('B2')
  }
).rename('BSI');

// Add indices as bands
var indices = composite.addBands([ndvi, ndwi, soci, bsi]);

// Visualization
Map.centerObject(cicra_bbox, 12);
Map.addLayer(composite, {bands: ['B4', 'B3', 'B2'], min: 0, max: 3000}, 'True Color');
Map.addLayer(ndvi, {min: 0, max: 1, palette: ['brown', 'yellow', 'green']}, 'NDVI');
Map.addLayer(bsi, {min: -0.5, max: 0.5, palette: ['blue', 'white', 'brown']}, 'BSI');
Map.addLayer(sampling_points, {color: 'red'}, 'Sampling Points');

// Export to Drive
Export.image.toDrive({
  image: indices,
  description: 'CICRA_Sentinel2_Indices',
  folder: 'CICRA_Study',
  region: cicra_bbox,
  scale: 10,
  maxPixels: 1e13
});
"""
    return code


# =============================================================================
# MAIN
# =============================================================================

def main():
    """Main entry point."""
    print("=" * 60)
    print("CICRA SENTINEL-2 SPECTRAL ANALYSIS")
    print("=" * 60)

    # Search for available scenes
    scenes = search_sentinel2_planetary(
        CICRA_BBOX,
        SENTINEL_PARAMS["start_date"],
        SENTINEL_PARAMS["end_date"],
        SENTINEL_PARAMS["cloud_cover_max"]
    )

    if scenes:
        print(f"\nFound {len(scenes)} low-cloud scenes")

        # Sort by cloud cover
        scenes_sorted = sorted(scenes,
                               key=lambda x: x.get("properties", {}).get("eo:cloud_cover", 100))

        print("\nTop 5 scenes by cloud cover:")
        for scene in scenes_sorted[:5]:
            props = scene.get("properties", {})
            scene_id = scene.get("id", "unknown")
            cloud = props.get("eo:cloud_cover", "N/A")
            date = props.get("datetime", "")[:10]
            print(f"  {date} - {cloud:.1f}% cloud - {scene_id}")

        # Process best scene
        if scenes_sorted:
            print("\n" + "=" * 60)
            print("PROCESSING BEST SCENE")
            print("=" * 60)

            outputs = process_sentinel_scene(scenes_sorted[0], SENTINEL_DIR, CICRA_BBOX)

            if outputs:
                print("\nOutputs created:")
                for key, path in outputs.items():
                    if isinstance(path, str):
                        print(f"  {key}: {path}")

    else:
        print("\nNo scenes found via API. Alternative options:")

    # Print GEE code
    print("\n" + "=" * 60)
    print("GOOGLE EARTH ENGINE CODE")
    print("=" * 60)
    print("\nFor more flexible analysis, use Google Earth Engine:")
    print("https://code.earthengine.google.com/")
    print("\nCopy the following code to the Code Editor:\n")
    print("-" * 40)
    print(gee_code_snippet())
    print("-" * 40)

    # Print manual download options
    print("\n" + "=" * 60)
    print("MANUAL DOWNLOAD OPTIONS")
    print("=" * 60)
    print("\n1. Copernicus Open Access Hub:")
    print("   https://scihub.copernicus.eu/")

    print("\n2. USGS EarthExplorer:")
    print("   https://earthexplorer.usgs.gov/")

    print("\n3. AWS Sentinel-2 COGs:")
    print("   https://registry.opendata.aws/sentinel-2-l2a-cogs/")

    print("\n" + "=" * 60)
    print("COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
