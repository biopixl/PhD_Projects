"""
NASA Earthdata Download Script for CICRA Study
Madre de Dios, Peru

This script accesses NASA Earthdata products via API:
1. NASADEM - Improved SRTM (30m)
2. GEDI L2A - Elevation and canopy height (25m footprints)
3. ICESat-2 ATL08 - Land/vegetation height
4. HLS - Harmonized Landsat Sentinel imagery

Requires NASA Earthdata account: https://urs.earthdata.nasa.gov/

Author: Isaac
Date: 2024
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime
from typing import List, Tuple

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, SENTINEL_DIR, CICRA_BBOX, EXTENDED_BBOX,
    SAMPLING_LOCATIONS, get_bbox_as_tuple
)

try:
    import requests
except ImportError:
    requests = None


# =============================================================================
# NASA EARTHDATA AUTHENTICATION
# =============================================================================

EARTHDATA_LOGIN = "https://urs.earthdata.nasa.gov"
CMR_SEARCH = "https://cmr.earthdata.nasa.gov/search"

def get_earthdata_token():
    """
    Get NASA Earthdata token from environment or .netrc file.

    Setup instructions:
    1. Create account at https://urs.earthdata.nasa.gov/
    2. Create ~/.netrc file with:
       machine urs.earthdata.nasa.gov login <username> password <password>
    3. Or set environment variables:
       EARTHDATA_USERNAME and EARTHDATA_PASSWORD
    """
    username = os.environ.get("EARTHDATA_USERNAME")
    password = os.environ.get("EARTHDATA_PASSWORD")

    if not username or not password:
        # Try .netrc
        netrc_path = os.path.expanduser("~/.netrc")
        if os.path.exists(netrc_path):
            print(f"Found .netrc at {netrc_path}")
            return None  # Will use .netrc automatically
        else:
            print("NASA Earthdata credentials not found.")
            print("Please set up authentication:")
            print("  1. Register at: https://urs.earthdata.nasa.gov/")
            print("  2. Create ~/.netrc with credentials")
            print("  3. Or set EARTHDATA_USERNAME and EARTHDATA_PASSWORD env vars")
            return None

    return (username, password)


# =============================================================================
# CMR (COMMON METADATA REPOSITORY) SEARCH
# =============================================================================

def search_cmr(collection: str, bbox: dict, temporal: str = None,
               max_results: int = 100) -> List[dict]:
    """
    Search NASA CMR for data granules.

    Parameters:
    -----------
    collection : str
        Collection short name or concept ID
    bbox : dict
        Bounding box with west, south, east, north
    temporal : str
        Temporal range (e.g., "2020-01-01,2023-12-31")
    max_results : int
        Maximum number of results

    Returns:
    --------
    list : List of granule metadata dictionaries
    """
    url = f"{CMR_SEARCH}/granules.json"

    params = {
        "short_name": collection,
        "bounding_box": f"{bbox['west']},{bbox['south']},{bbox['east']},{bbox['north']}",
        "page_size": min(max_results, 2000),
        "sort_key": "-start_date",
    }

    if temporal:
        params["temporal"] = temporal

    print(f"Searching CMR for {collection}...")
    print(f"  Bbox: {bbox}")

    try:
        response = requests.get(url, params=params, timeout=60)
        response.raise_for_status()

        data = response.json()
        entries = data.get("feed", {}).get("entry", [])

        print(f"  Found {len(entries)} granules")
        return entries

    except Exception as e:
        print(f"  Error: {e}")
        return []


def get_download_urls(granules: List[dict]) -> List[str]:
    """Extract download URLs from granule metadata."""
    urls = []
    for granule in granules:
        links = granule.get("links", [])
        for link in links:
            if link.get("rel") == "http://esipfed.org/ns/fedsearch/1.1/data#":
                urls.append(link.get("href"))
    return urls


# =============================================================================
# NASADEM (Improved SRTM 30m)
# =============================================================================

def search_nasadem(bbox: dict) -> List[dict]:
    """
    Search for NASADEM tiles covering the bounding box.

    NASADEM provides improved SRTM data at 30m resolution with:
    - Void filling from ASTER GDEM
    - ICESat GLAS ground control
    - PRISM stereo imagery
    """
    return search_cmr("NASADEM_HGT", bbox)


def get_nasadem_tile_url(lat: int, lon: int) -> str:
    """
    Construct direct URL for NASADEM tile.

    Tiles are named by their SW corner:
    - Latitude: N/S + 2 digits
    - Longitude: E/W + 3 digits
    """
    ns = "n" if lat >= 0 else "s"
    ew = "e" if lon >= 0 else "w"

    tile_name = f"NASADEM_HGT_{ns}{abs(lat):02d}{ew}{abs(lon):03d}"

    # Direct LP DAAC URL
    base_url = "https://e4ftl01.cr.usgs.gov/MEASURES/NASADEM_HGT.001/2000.02.11"
    return f"{base_url}/{tile_name}.zip"


# =============================================================================
# GEDI L2A (Elevation and Canopy Height)
# =============================================================================

def search_gedi_l2a(bbox: dict, temporal: str = "2019-04-18,2024-12-31") -> List[dict]:
    """
    Search for GEDI L2A data.

    GEDI provides:
    - Ground elevation (elev_lowestmode)
    - Canopy top height (rh100)
    - Relative height metrics (rh25, rh50, rh75, rh98)
    - 25m footprint resolution
    - Coverage: ±51.6° latitude

    Note: GEDI was in hibernation March 2023 - April 2024
    """
    return search_cmr("GEDI02_A", bbox, temporal)


# =============================================================================
# ICESat-2 ATL08 (Land and Vegetation Height)
# =============================================================================

def search_icesat2_atl08(bbox: dict, temporal: str = "2018-10-14,2024-12-31") -> List[dict]:
    """
    Search for ICESat-2 ATL08 data.

    ATL08 provides:
    - Terrain height
    - Canopy height
    - 100m along-track segments
    - Global coverage
    """
    return search_cmr("ATL08", bbox, temporal)


# =============================================================================
# HLS (Harmonized Landsat Sentinel)
# =============================================================================

def search_hls(bbox: dict, temporal: str = "2023-01-01,2023-12-31") -> List[dict]:
    """
    Search for Harmonized Landsat Sentinel data.

    HLS provides:
    - 30m resolution
    - Combined Landsat 8/9 and Sentinel-2
    - Consistent radiometry
    - 2-3 day revisit
    """
    # Search both L30 (Landsat) and S30 (Sentinel)
    l30 = search_cmr("HLSL30", bbox, temporal)
    s30 = search_cmr("HLSS30", bbox, temporal)
    return l30 + s30


# =============================================================================
# DOWNLOAD FUNCTIONS
# =============================================================================

def download_with_auth(url: str, output_path: str, auth: Tuple = None) -> bool:
    """
    Download file with NASA Earthdata authentication.

    Uses session-based auth with redirect handling.
    """
    if os.path.exists(output_path):
        print(f"  Already exists: {output_path}")
        return True

    print(f"  Downloading: {os.path.basename(output_path)}")

    try:
        with requests.Session() as session:
            # Set up authentication
            if auth:
                session.auth = auth

            # Follow redirects to get actual data
            response = session.get(url, allow_redirects=True, timeout=300)
            response.raise_for_status()

            # Write file
            with open(output_path, 'wb') as f:
                f.write(response.content)

            print(f"    Saved: {output_path}")
            return True

    except Exception as e:
        print(f"    Error: {e}")
        return False


# =============================================================================
# SUMMARY OF AVAILABLE DATA
# =============================================================================

def print_data_summary():
    """Print summary of available NASA Earthdata products."""
    print("""
================================================================================
NASA EARTHDATA PRODUCTS FOR CICRA STUDY
================================================================================

1. NASADEM (30m DEM)
   - Improved SRTM with void filling and ICESat control
   - Collection: NASADEM_HGT
   - Resolution: 1 arc-second (~30m)
   - Coverage: 60°N to 56°S
   - Access: https://www.earthdata.nasa.gov/data/catalog/lpcloud-nasadem-hgt-001

2. GEDI L2A (Lidar Elevation & Canopy)
   - Ground elevation and canopy height from ISS lidar
   - Collection: GEDI02_A
   - Footprint: 25m diameter
   - Coverage: ±51.6° latitude
   - Access: https://www.earthdata.nasa.gov/data/catalog/lpcloud-gedi02-a-002
   - Note: Gaps during hibernation (Mar 2023 - Apr 2024)

3. ICESat-2 ATL08 (Photon Elevation)
   - Terrain and canopy height from photon-counting lidar
   - Collection: ATL08
   - Segments: 100m along-track
   - Coverage: Global
   - Access: https://nsidc.org/data/atl08

4. HLS (Harmonized Landsat Sentinel)
   - Consistent multispectral imagery
   - Collections: HLSL30 (Landsat), HLSS30 (Sentinel-2)
   - Resolution: 30m
   - Revisit: 2-3 days
   - Access: https://www.earthdata.nasa.gov/data/catalog/lpcloud-hlsl30-002

5. ALOS PALSAR RTC (12.5m Radar)
   - Radiometrically terrain corrected SAR
   - Resolution: 12.5m (high-res) or 30m (low-res)
   - Access via ASF: https://search.asf.alaska.edu/
   - Note: RTC products show backscatter, not elevation

================================================================================
AUTHENTICATION SETUP
================================================================================

1. Create NASA Earthdata account:
   https://urs.earthdata.nasa.gov/

2. Create ~/.netrc file:
   machine urs.earthdata.nasa.gov login YOUR_USERNAME password YOUR_PASSWORD

3. Set permissions:
   chmod 600 ~/.netrc

4. For ASF data, also authorize the application:
   - Go to: https://urs.earthdata.nasa.gov/profile
   - Under "Applications", authorize "Alaska Satellite Facility"

================================================================================
""")


# =============================================================================
# MAIN
# =============================================================================

def main():
    """Search and optionally download NASA Earthdata products."""

    print_data_summary()

    print("=" * 70)
    print("SEARCHING NASA CMR FOR CICRA STUDY AREA")
    print("=" * 70)
    print(f"\nBounding box: {CICRA_BBOX}")

    # Check authentication
    auth = get_earthdata_token()

    # Search for available data
    print("\n" + "-" * 50)
    print("1. NASADEM (30m DEM)")
    print("-" * 50)
    nasadem = search_nasadem(CICRA_BBOX)
    if nasadem:
        for g in nasadem[:3]:
            print(f"  - {g.get('title', 'Unknown')}")

    print("\n" + "-" * 50)
    print("2. GEDI L2A (Lidar Elevation)")
    print("-" * 50)
    gedi = search_gedi_l2a(CICRA_BBOX, "2022-01-01,2024-12-31")
    if gedi:
        print(f"  Found {len(gedi)} GEDI orbits")
        for g in gedi[:5]:
            print(f"  - {g.get('title', 'Unknown')[:60]}...")

    print("\n" + "-" * 50)
    print("3. ICESat-2 ATL08 (Photon Lidar)")
    print("-" * 50)
    icesat = search_icesat2_atl08(CICRA_BBOX, "2022-01-01,2024-12-31")
    if icesat:
        print(f"  Found {len(icesat)} ICESat-2 tracks")
        for g in icesat[:5]:
            print(f"  - {g.get('title', 'Unknown')[:60]}...")

    print("\n" + "-" * 50)
    print("4. HLS (Landsat + Sentinel)")
    print("-" * 50)
    hls = search_hls(CICRA_BBOX, "2023-06-01,2023-09-30")  # Dry season
    if hls:
        print(f"  Found {len(hls)} HLS scenes")

    # Provide download commands
    print("\n" + "=" * 70)
    print("DOWNLOAD COMMANDS")
    print("=" * 70)

    print("\n# NASADEM tile for CICRA area:")
    nasadem_url = get_nasadem_tile_url(-13, -71)
    print(f"wget --user=YOUR_USERNAME --ask-password {nasadem_url}")
    print(f"# Or use curl with .netrc:")
    print(f"curl -n -L -o NASADEM_s13w071.zip {nasadem_url}")

    print("\n# For GEDI/ICESat-2, use earthaccess Python library:")
    print("""
import earthaccess

# Login (uses .netrc or prompts)
earthaccess.login()

# Search GEDI
results = earthaccess.search_data(
    short_name="GEDI02_A",
    bounding_box=(-70.14, -12.60, -70.06, -12.54),
    temporal=("2022-01-01", "2024-12-31")
)

# Download
earthaccess.download(results, "./data/gedi/")
""")

    print("\n" + "=" * 70)
    print("RECOMMENDATIONS FOR SCARP DETECTION")
    print("=" * 70)
    print("""
1. NASADEM: Better than Copernicus for void-filled areas
   - Download and compare with current Copernicus DEM

2. GEDI L2A: Extract ground elevation points along terrace edges
   - Filter for quality_flag == 1 (good shots)
   - Use elev_lowestmode for ground elevation
   - Compare with DEM to validate scarp heights

3. ICESat-2 ATL08: Linear transects across study area
   - Provides precise elevation profiles
   - Good for validating terrace heights

4. For 12.5m resolution, use ASF Vertex:
   https://search.asf.alaska.edu/
   Search: ALOS PALSAR, coordinates: -70.1, -12.57
""")

    print("\n" + "=" * 70)
    print("SEARCH COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    main()
