"""
Synthetic GEDI Validation Dataset
Creates simulated GEDI footprints for testing the analysis pipeline

This script generates GEDI-like point data by:
1. Sampling from the DEM at regular intervals
2. Adding noise consistent with GEDI accuracy (~1m vertical)
3. Creating transects across terrace edges

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, GEDI_DIR, GEOTIFF_DIR, CICRA_BBOX, 
    SAMPLING_LOCATIONS
)

try:
    import rasterio
    from rasterio.transform import rowcol
except ImportError:
    rasterio = None


def create_gedi_transects(dem_path, output_dir, n_transects=10, footprint_spacing=25):
    """
    Create synthetic GEDI-like transects across the study area.
    
    Parameters:
    -----------
    dem_path : str
        Path to DEM GeoTIFF
    output_dir : str
        Output directory for GEDI-like data
    n_transects : int
        Number of transects (simulating GEDI orbit tracks)
    footprint_spacing : float
        Spacing between footprints in meters (~25m for GEDI)
    """
    print("=" * 60)
    print("CREATING SYNTHETIC GEDI VALIDATION DATA")
    print("=" * 60)
    
    with rasterio.open(dem_path) as src:
        dem = src.read(1).astype(np.float32)
        transform = src.transform
        nodata = src.nodata
        bounds = src.bounds
        
        # Replace nodata with NaN
        dem = np.where(dem == nodata, np.nan, dem)
        
        cell_size_deg = abs(transform[0])
        cell_size_m = cell_size_deg * 111000 * np.cos(np.radians(-12.57))
    
    print(f"DEM: {dem.shape}, cell size: {cell_size_m:.1f}m")
    print(f"Bounds: {bounds}")
    
    # Create transect lines across the study area
    # GEDI tracks are roughly N-S oriented at this latitude
    transects = []
    
    lon_range = bounds.right - bounds.left
    lat_range = bounds.top - bounds.bottom
    
    for i in range(n_transects):
        # Randomize transect longitude slightly
        base_lon = bounds.left + (i + 0.5) * lon_range / n_transects
        lon_offset = np.random.uniform(-0.005, 0.005)
        
        # Create footprints along N-S transect
        lat_step = footprint_spacing / 111000  # Convert m to degrees
        lats = np.arange(bounds.bottom, bounds.top, lat_step)
        
        for lat in lats:
            # Add slight E-W wobble (GEDI tracks aren't perfectly N-S)
            lon = base_lon + lon_offset + np.random.uniform(-0.001, 0.001)
            
            # Get DEM elevation at this point
            try:
                row, col = rowcol(transform, lon, lat)
                if 0 <= row < dem.shape[0] and 0 <= col < dem.shape[1]:
                    elev_dem = dem[row, col]
                    
                    if not np.isnan(elev_dem):
                        # Add GEDI-like noise (~1m vertical accuracy)
                        elev_gedi = elev_dem + np.random.normal(0, 1.0)
                        
                        # Simulate canopy height (based on terrain position)
                        # Higher TPI (terraces) typically have taller forests
                        canopy_h = np.random.uniform(20, 35)  # Typical Amazon values
                        
                        # Quality flag (1 = good)
                        quality = 1 if np.random.random() > 0.1 else 0
                        
                        transects.append({
                            'transect_id': int(i),
                            'longitude': float(round(lon, 6)),
                            'latitude': float(round(lat, 6)),
                            'elev_lowestmode': float(round(elev_gedi, 2)),
                            'elev_dem': float(round(float(elev_dem), 2)),
                            'rh100': float(round(canopy_h, 2)),
                            'quality_flag': int(quality),
                            'beam': f'BEAM0{(i % 8) + 1}'
                        })
            except:
                continue
    
    print(f"Generated {len(transects)} synthetic GEDI footprints")
    
    # Save as GeoJSON
    geojson = {
        "type": "FeatureCollection",
        "properties": {
            "description": "Synthetic GEDI L2A footprints for pipeline testing",
            "source": "Generated from NASADEM",
            "note": "Replace with real GEDI data when available"
        },
        "features": []
    }
    
    for pt in transects:
        feature = {
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [pt['longitude'], pt['latitude']]
            },
            "properties": {
                "transect_id": pt['transect_id'],
                "elev_lowestmode": pt['elev_lowestmode'],
                "elev_dem": pt['elev_dem'],
                "rh100": pt['rh100'],
                "quality_flag": pt['quality_flag'],
                "beam": pt['beam']
            }
        }
        geojson["features"].append(feature)
    
    output_path = os.path.join(output_dir, "synthetic_gedi_footprints.geojson")
    with open(output_path, 'w') as f:
        json.dump(geojson, f, indent=2)
    
    print(f"Saved: {output_path}")
    
    # Also save as CSV for easy analysis
    csv_path = os.path.join(output_dir, "synthetic_gedi_footprints.csv")
    with open(csv_path, 'w') as f:
        headers = list(transects[0].keys())
        f.write(','.join(headers) + '\n')
        for pt in transects:
            f.write(','.join(str(pt[h]) for h in headers) + '\n')
    
    print(f"Saved: {csv_path}")
    
    # Create transects through sampling locations
    print("\nCreating focused transects through sampling locations...")
    
    cicra_sites = [loc for loc in SAMPLING_LOCATIONS if 'PM' not in loc.name]
    
    site_transects = []
    for site in cicra_sites:
        # Create E-W transect through each site
        lon_start = site.longitude - 0.02
        lon_end = site.longitude + 0.02
        lon_step = footprint_spacing / (111000 * np.cos(np.radians(site.latitude)))
        
        for lon in np.arange(lon_start, lon_end, lon_step):
            try:
                row, col = rowcol(transform, lon, site.latitude)
                if 0 <= row < dem.shape[0] and 0 <= col < dem.shape[1]:
                    elev_dem = dem[row, col]
                    if not np.isnan(elev_dem):
                        site_transects.append({
                            'site': site.name,
                            'longitude': float(round(lon, 6)),
                            'latitude': float(round(site.latitude, 6)),
                            'elev_dem': float(round(float(elev_dem), 2)),
                            'distance_m': float(round((lon - site.longitude) * 111000 * np.cos(np.radians(site.latitude)), 1))
                        })
            except:
                continue
    
    site_csv_path = os.path.join(output_dir, "site_transects.csv")
    with open(site_csv_path, 'w') as f:
        headers = list(site_transects[0].keys())
        f.write(','.join(headers) + '\n')
        for pt in site_transects:
            f.write(','.join(str(pt[h]) for h in headers) + '\n')
    
    print(f"Saved: {site_csv_path}")
    print(f"  - {len(site_transects)} points across {len(cicra_sites)} sites")
    
    return transects, site_transects


def main():
    import glob
    
    # Find DEM
    dem_files = glob.glob(os.path.join(DEM_DIR, "nasadem*.tif"))
    if not dem_files:
        dem_files = glob.glob(os.path.join(DEM_DIR, "*.tif"))
    
    if not dem_files:
        print("ERROR: No DEM files found")
        return
    
    dem_path = dem_files[0]
    print(f"Using DEM: {dem_path}")
    
    os.makedirs(GEDI_DIR, exist_ok=True)
    
    transects, site_transects = create_gedi_transects(
        dem_path, 
        GEDI_DIR,
        n_transects=10,
        footprint_spacing=25
    )
    
    print("\n" + "=" * 60)
    print("SYNTHETIC GEDI DATA CREATED")
    print("=" * 60)
    print("\nNOTE: This is simulated data for testing the analysis pipeline.")
    print("Replace with real GEDI L2A data when available.")
    print("\nTo download real GEDI data manually:")
    print("1. Go to: https://search.earthdata.nasa.gov/")
    print("2. Search for 'GEDI L2A'")
    print("3. Draw polygon around CICRA area")
    print("4. Download HDF5 files")
    print("5. Use h5py to extract: elev_lowestmode, rh100, quality_flag")


if __name__ == "__main__":
    main()
