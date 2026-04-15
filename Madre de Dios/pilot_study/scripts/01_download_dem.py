"""
Download DEM Data for CICRA Flood-Buried Forest Study
Madre de Dios, Peru

This script downloads freely available DEM products:
1. SRTM 30m (via OpenTopography or USGS EarthExplorer)
2. Copernicus DEM 30m (via AWS or Copernicus)
3. NASADEM (improved SRTM)

Author: Isaac
Date: 2024
"""

import os
import sys
import requests
import zipfile
import numpy as np
from pathlib import Path

# Add parent directory to path for config import
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, CICRA_BBOX, EXTENDED_BBOX,
    get_bbox_as_tuple, SAMPLING_LOCATIONS
)

# =============================================================================
# OPENTOPOGRAPHY API (Free tier available)
# =============================================================================

OPENTOPOGRAPHY_API = "https://portal.opentopography.org/API/globaldem"

def download_srtm_opentopography(bbox: dict, output_name: str = "srtm_cicra.tif",
                                  dem_type: str = "SRTMGL1") -> str:
    """
    Download SRTM data via OpenTopography API.

    Parameters:
    -----------
    bbox : dict
        Bounding box with keys: west, east, south, north
    output_name : str
        Output filename
    dem_type : str
        DEM product: SRTMGL1 (30m), SRTMGL3 (90m), COP30 (Copernicus 30m)

    Returns:
    --------
    str : Path to downloaded file

    Note: Requires free API key from OpenTopography
    """
    output_path = os.path.join(DEM_DIR, output_name)

    # Check if file already exists
    if os.path.exists(output_path):
        print(f"File already exists: {output_path}")
        return output_path

    # API parameters
    params = {
        "demtype": dem_type,
        "south": bbox["south"],
        "north": bbox["north"],
        "west": bbox["west"],
        "east": bbox["east"],
        "outputFormat": "GTiff",
    }

    # Add API key if available (set as environment variable)
    api_key = os.environ.get("OPENTOPOGRAPHY_API_KEY")
    if api_key:
        params["API_Key"] = api_key
    else:
        print("Warning: No OPENTOPOGRAPHY_API_KEY set. Using demo mode (limited).")
        print("Get free API key at: https://opentopography.org/")

    print(f"Downloading {dem_type} for bbox: {bbox}")
    print(f"Request URL: {OPENTOPOGRAPHY_API}")

    try:
        response = requests.get(OPENTOPOGRAPHY_API, params=params, timeout=300)
        response.raise_for_status()

        with open(output_path, 'wb') as f:
            f.write(response.content)

        print(f"Downloaded successfully: {output_path}")
        return output_path

    except requests.exceptions.RequestException as e:
        print(f"Error downloading DEM: {e}")
        return None


# =============================================================================
# NASA EARTHDATA (SRTM/NASADEM) - Requires free registration
# =============================================================================

def get_srtm_tile_names(bbox: dict) -> list:
    """
    Get SRTM tile names for a bounding box.
    SRTM tiles are 1x1 degree, named by SW corner.
    """
    tiles = []

    # Calculate tile boundaries
    west = int(np.floor(bbox["west"]))
    east = int(np.ceil(bbox["east"]))
    south = int(np.floor(bbox["south"]))
    north = int(np.ceil(bbox["north"]))

    for lat in range(south, north):
        for lon in range(west, east):
            # SRTM naming convention
            ns = "N" if lat >= 0 else "S"
            ew = "E" if lon >= 0 else "W"
            tile_name = f"{ns}{abs(lat):02d}{ew}{abs(lon):03d}"
            tiles.append(tile_name)

    return tiles


def download_nasadem_earthdata(tile_name: str, output_dir: str = None) -> str:
    """
    Download NASADEM HGT tile from NASA EarthData.

    Requires .netrc file with NASA EarthData credentials:
    machine urs.earthdata.nasa.gov login <user> password <pass>

    Register free at: https://urs.earthdata.nasa.gov/
    """
    if output_dir is None:
        output_dir = DEM_DIR

    base_url = "https://e4ftl01.cr.usgs.gov/MEASURES/NASADEM_HGT.001/2000.02.11"
    filename = f"NASADEM_HGT_{tile_name}.zip"
    url = f"{base_url}/{filename}"

    output_path = os.path.join(output_dir, filename)
    hgt_path = os.path.join(output_dir, f"{tile_name}.hgt")

    if os.path.exists(hgt_path):
        print(f"Tile already exists: {hgt_path}")
        return hgt_path

    print(f"Downloading NASADEM tile: {tile_name}")
    print(f"URL: {url}")
    print("Note: Requires NASA EarthData credentials in ~/.netrc")

    try:
        # Use session for authentication
        with requests.Session() as session:
            response = session.get(url, timeout=300)
            response.raise_for_status()

            with open(output_path, 'wb') as f:
                f.write(response.content)

            # Extract HGT file
            with zipfile.ZipFile(output_path, 'r') as zip_ref:
                zip_ref.extractall(output_dir)

            # Clean up zip
            os.remove(output_path)

            print(f"Downloaded and extracted: {hgt_path}")
            return hgt_path

    except Exception as e:
        print(f"Error downloading NASADEM: {e}")
        print("Try manual download from: https://search.earthdata.nasa.gov/")
        return None


# =============================================================================
# AWS COPERNICUS DEM (Public, no authentication required)
# =============================================================================

def download_copernicus_aws(bbox: dict, output_name: str = "copernicus_cicra.tif") -> str:
    """
    Download Copernicus DEM 30m from AWS public bucket.

    The Copernicus DEM is organized in 1x1 degree tiles on AWS:
    s3://copernicus-dem-30m/

    Note: Uses HTTP range requests, no AWS credentials needed.
    """
    output_path = os.path.join(DEM_DIR, output_name)

    if os.path.exists(output_path):
        print(f"File already exists: {output_path}")
        return output_path

    # Get required tiles
    tiles = get_copernicus_tile_names(bbox)

    print(f"Required Copernicus tiles: {tiles}")
    print("Note: For full download, use GDAL with /vsicurl/ or aws cli")
    print("Example GDAL command:")

    # Generate GDAL command
    for tile in tiles:
        url = get_copernicus_url(tile)
        print(f"  gdal_translate /vsicurl/{url} {tile}.tif")

    return None


def get_copernicus_tile_names(bbox: dict) -> list:
    """Get Copernicus DEM tile names for bounding box."""
    tiles = []

    west = int(np.floor(bbox["west"]))
    east = int(np.ceil(bbox["east"]))
    south = int(np.floor(bbox["south"]))
    north = int(np.ceil(bbox["north"]))

    for lat in range(south, north):
        for lon in range(west, east):
            # Copernicus naming convention
            ns = "N" if lat >= 0 else "S"
            ew = "E" if lon >= 0 else "W"
            tile = f"Copernicus_DSM_COG_10_{ns}{abs(lat):02d}_00_{ew}{abs(lon):03d}_00_DEM"
            tiles.append(tile)

    return tiles


def get_copernicus_url(tile_name: str) -> str:
    """Get AWS URL for Copernicus DEM tile."""
    return f"https://copernicus-dem-30m.s3.amazonaws.com/{tile_name}/{tile_name}.tif"


# =============================================================================
# ALTERNATIVE: ELEVATION API (Small areas only)
# =============================================================================

def get_elevation_profile(coords: list, source: str = "srtm30m") -> list:
    """
    Get elevation values for a list of coordinates using Open-Elevation API.
    Useful for quick checks, but rate-limited for large requests.

    Parameters:
    -----------
    coords : list of (lat, lon) tuples
    source : str
        Elevation source (srtm30m, etc.)
    """
    url = "https://api.open-elevation.com/api/v1/lookup"

    # Format locations
    locations = [{"latitude": lat, "longitude": lon} for lat, lon in coords]

    try:
        response = requests.post(url, json={"locations": locations}, timeout=60)
        response.raise_for_status()

        results = response.json()["results"]
        return [(r["elevation"]) for r in results]

    except Exception as e:
        print(f"Error querying elevation API: {e}")
        return None


# =============================================================================
# MAIN EXECUTION
# =============================================================================

def main():
    """Main download routine."""
    print("=" * 60)
    print("CICRA FLOOD-BURIED FOREST STUDY - DEM DATA ACQUISITION")
    print("=" * 60)

    # Print study area info
    print(f"\nPrimary Study Area (CICRA):")
    print(f"  Bounding Box: {CICRA_BBOX}")

    print(f"\nExtended Study Area (including Puerto Maldonado):")
    print(f"  Bounding Box: {EXTENDED_BBOX}")

    # List required tiles
    print(f"\nRequired SRTM tiles for CICRA area:")
    cicra_tiles = get_srtm_tile_names(CICRA_BBOX)
    for tile in cicra_tiles:
        print(f"  - {tile}")

    print(f"\nRequired tiles for extended area:")
    extended_tiles = get_srtm_tile_names(EXTENDED_BBOX)
    for tile in extended_tiles:
        print(f"  - {tile}")

    # Download options
    print("\n" + "=" * 60)
    print("DOWNLOAD OPTIONS")
    print("=" * 60)

    print("\nOption 1: OpenTopography API (Recommended)")
    print("  - Free API key at: https://opentopography.org/")
    print("  - Supports SRTM 30m, SRTM 90m, Copernicus 30m")
    print("  - Set OPENTOPOGRAPHY_API_KEY environment variable")

    print("\nOption 2: NASA EarthData (NASADEM)")
    print("  - Free registration at: https://urs.earthdata.nasa.gov/")
    print("  - Higher quality than original SRTM")
    print("  - Requires .netrc credentials")

    print("\nOption 3: AWS Copernicus (No authentication)")
    print("  - Direct HTTP access via GDAL /vsicurl/")
    print("  - Best freely available global DEM")

    print("\nOption 4: Manual Download")
    print("  - USGS EarthExplorer: https://earthexplorer.usgs.gov/")
    print("  - Copernicus Space: https://spacedata.copernicus.eu/")

    # Attempt OpenTopography download for CICRA area
    print("\n" + "=" * 60)
    print("ATTEMPTING DOWNLOADS")
    print("=" * 60)

    # Try Copernicus 30m via OpenTopography (best quality)
    result = download_srtm_opentopography(
        CICRA_BBOX,
        output_name="copernicus_cicra_30m.tif",
        dem_type="COP30"
    )

    if result:
        print(f"\nSuccess! Downloaded: {result}")
    else:
        print("\nOpenTopography download requires API key.")
        print("Generating GDAL commands for manual download...")

        # Generate GDAL commands
        print("\n--- GDAL Commands for Copernicus DEM ---")
        tiles = get_copernicus_tile_names(CICRA_BBOX)
        for tile in tiles:
            url = get_copernicus_url(tile)
            out = os.path.join(DEM_DIR, f"{tile}.tif")
            print(f'gdal_translate "/vsicurl/{url}" "{out}"')

        print("\n--- Merge tiles with GDAL ---")
        merged = os.path.join(DEM_DIR, "copernicus_merged.tif")
        print(f'gdal_merge.py -o "{merged}" {DEM_DIR}/*.tif')

    # Quick elevation check for sampling locations
    print("\n" + "=" * 60)
    print("SAMPLING LOCATION ELEVATIONS (via API)")
    print("=" * 60)

    coords = [(loc.latitude, loc.longitude) for loc in SAMPLING_LOCATIONS]
    elevations = get_elevation_profile(coords)

    if elevations:
        for loc, elev in zip(SAMPLING_LOCATIONS, elevations):
            print(f"  {loc.name}: {elev} m")
    else:
        print("  Could not retrieve elevations via API")

    print("\n" + "=" * 60)
    print("DOWNLOAD COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
