"""
GEDI L2A Download Script for CICRA Study
Downloads canopy-penetrating lidar data for terrace validation

Author: Isaac
Date: 2024
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import CICRA_BBOX, GEDI_DIR

# Ensure GEDI directory exists
os.makedirs(GEDI_DIR, exist_ok=True)

# CMR Search URL
CMR_URL = "https://cmr.earthdata.nasa.gov/search/granules.json"

def search_gedi_granules(bbox, start_date="2022-01-01", end_date="2024-12-31"):
    """Search for GEDI L2A granules covering the study area."""
    import requests
    
    params = {
        "short_name": "GEDI02_A",
        "version": "002",
        "bounding_box": f"{bbox['west']},{bbox['south']},{bbox['east']},{bbox['north']}",
        "temporal": f"{start_date},{end_date}",
        "page_size": 100,
        "sort_key": "-start_date"
    }
    
    print(f"Searching GEDI L2A granules for CICRA area...")
    print(f"  Bbox: {bbox}")
    print(f"  Temporal: {start_date} to {end_date}")
    
    response = requests.get(CMR_URL, params=params, timeout=60)
    response.raise_for_status()
    
    data = response.json()
    entries = data.get("feed", {}).get("entry", [])
    
    print(f"  Found {len(entries)} GEDI granules")
    
    return entries

def get_download_urls(granules):
    """Extract download URLs from granule metadata."""
    urls = []
    for g in granules:
        links = g.get("links", [])
        for link in links:
            href = link.get("href", "")
            if href.endswith(".h5") and "lpdaac" in href.lower():
                urls.append({
                    "url": href,
                    "title": g.get("title", "Unknown"),
                    "time_start": g.get("time_start", ""),
                    "size": g.get("granule_size", "Unknown")
                })
                break
    return urls

def download_with_netrc(url, output_path):
    """Download file using curl with .netrc authentication."""
    if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
        print(f"  Already exists: {os.path.basename(output_path)}")
        return True
    
    print(f"  Downloading: {os.path.basename(output_path)}")
    
    # Use curl with .netrc for authentication
    cmd = [
        "curl", "-n", "-L", "-c", "/tmp/cookies.txt", "-b", "/tmp/cookies.txt",
        "--retry", "3", "--retry-delay", "5",
        "-o", output_path,
        url
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        
        if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
            size_mb = os.path.getsize(output_path) / (1024 * 1024)
            print(f"    Success: {size_mb:.1f} MB")
            return True
        else:
            print(f"    Failed: File too small or missing")
            if os.path.exists(output_path):
                with open(output_path, 'r') as f:
                    content = f.read(500)
                    if "error" in content.lower() or "html" in content.lower():
                        print(f"    Error response: {content[:200]}")
                os.remove(output_path)
            return False
            
    except Exception as e:
        print(f"    Error: {e}")
        return False

def main():
    print("=" * 60)
    print("GEDI L2A DOWNLOAD FOR CICRA STUDY")
    print("=" * 60)
    
    # Check for .netrc
    netrc_path = os.path.expanduser("~/.netrc")
    if not os.path.exists(netrc_path):
        print("\nERROR: ~/.netrc not found!")
        print("Create it with:")
        print("  machine urs.earthdata.nasa.gov login YOUR_USERNAME password YOUR_PASSWORD")
        print("  chmod 600 ~/.netrc")
        return
    
    # Search for granules
    granules = search_gedi_granules(CICRA_BBOX)
    
    if not granules:
        print("No GEDI granules found!")
        return
    
    # Get download URLs
    urls = get_download_urls(granules)
    
    print(f"\nFound {len(urls)} downloadable GEDI files:")
    for i, u in enumerate(urls[:10]):
        print(f"  {i+1}. {u['title'][:60]}...")
        print(f"      Date: {u['time_start'][:10]}, Size: {u['size']} MB")
    
    # Download first few files (GEDI files are large, ~200-400MB each)
    print(f"\nDownloading first 3 files to: {GEDI_DIR}")
    
    success = 0
    for i, u in enumerate(urls[:3]):
        filename = os.path.basename(u['url'])
        output_path = os.path.join(GEDI_DIR, filename)
        
        if download_with_netrc(u['url'], output_path):
            success += 1
    
    print(f"\nDownloaded {success}/{min(3, len(urls))} files")
    
    # List downloaded files
    print("\nGEDI files in directory:")
    for f in os.listdir(GEDI_DIR):
        fpath = os.path.join(GEDI_DIR, f)
        if os.path.isfile(fpath):
            size_mb = os.path.getsize(fpath) / (1024 * 1024)
            print(f"  {f}: {size_mb:.1f} MB")

if __name__ == "__main__":
    main()
