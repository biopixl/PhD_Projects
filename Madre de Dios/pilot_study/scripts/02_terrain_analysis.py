"""
Terrain Analysis for CICRA Flood-Buried Forest Study
Madre de Dios, Peru

This script computes DTM derivatives for identifying:
1. Terrace scarps (terra firme / floodplain boundaries)
2. Paleochannel features
3. Flood deposit zones

DTM Derivatives computed:
- Slope
- Aspect
- Profile and Plan Curvature
- Topographic Position Index (TPI)
- Terrain Ruggedness Index (TRI)
- Hillshade

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, GEOTIFF_DIR, FIGURE_DIR,
    SLOPE_PARAMS, CURVATURE_PARAMS, TPI_PARAMS, SCARP_PARAMS,
    DEM_PARAMS, VIZ_PARAMS
)

# Check for required packages
try:
    import rasterio
    from rasterio.enums import Resampling
    from rasterio.warp import calculate_default_transform, reproject
except ImportError:
    print("rasterio not installed. Install with: pip install rasterio")
    rasterio = None

try:
    from scipy import ndimage
    from scipy.ndimage import generic_filter
except ImportError:
    print("scipy not installed. Install with: pip install scipy")
    ndimage = None


# =============================================================================
# SLOPE AND ASPECT
# =============================================================================

def compute_slope(dem: np.ndarray, cell_size: float = 30.0) -> np.ndarray:
    """
    Compute slope in degrees from DEM.

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model array
    cell_size : float
        Cell size in meters

    Returns:
    --------
    np.ndarray : Slope in degrees
    """
    # Compute gradients using Sobel filter (more robust than simple diff)
    dz_dx = ndimage.sobel(dem, axis=1) / (8 * cell_size)
    dz_dy = ndimage.sobel(dem, axis=0) / (8 * cell_size)

    # Slope in radians, then convert to degrees
    slope_rad = np.arctan(np.sqrt(dz_dx**2 + dz_dy**2))
    slope_deg = np.degrees(slope_rad)

    return slope_deg


def compute_aspect(dem: np.ndarray) -> np.ndarray:
    """
    Compute aspect (slope direction) in degrees from north.

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model array

    Returns:
    --------
    np.ndarray : Aspect in degrees (0-360, 0=North, 90=East)
    """
    # Compute gradients
    dz_dx = ndimage.sobel(dem, axis=1)
    dz_dy = ndimage.sobel(dem, axis=0)

    # Aspect in radians from east, convert to degrees from north
    aspect_rad = np.arctan2(-dz_dy, dz_dx)
    aspect_deg = np.degrees(aspect_rad)

    # Convert to 0-360 range, with 0 = North
    aspect_deg = 90 - aspect_deg
    aspect_deg = np.where(aspect_deg < 0, aspect_deg + 360, aspect_deg)
    aspect_deg = np.where(aspect_deg >= 360, aspect_deg - 360, aspect_deg)

    return aspect_deg


# =============================================================================
# CURVATURE
# =============================================================================

def compute_curvature(dem: np.ndarray, cell_size: float = 30.0) -> tuple:
    """
    Compute profile and plan curvature.

    Profile curvature: curvature in direction of maximum slope
    Plan curvature: curvature perpendicular to slope direction

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model array
    cell_size : float
        Cell size in meters

    Returns:
    --------
    tuple : (profile_curvature, plan_curvature, total_curvature)
    """
    # Second derivatives
    dz_dx = ndimage.sobel(dem, axis=1) / (8 * cell_size)
    dz_dy = ndimage.sobel(dem, axis=0) / (8 * cell_size)

    # Laplacian approximation for total curvature
    d2z_dx2 = ndimage.laplace(dem) / (cell_size**2)

    # Use 3x3 window for second derivatives
    kernel_xx = np.array([[1, -2, 1]]) / (cell_size**2)
    kernel_yy = np.array([[1], [-2], [1]]) / (cell_size**2)
    kernel_xy = np.array([[1, 0, -1], [0, 0, 0], [-1, 0, 1]]) / (4 * cell_size**2)

    d2z_dx2 = ndimage.convolve(dem, kernel_xx)
    d2z_dy2 = ndimage.convolve(dem, kernel_yy)
    d2z_dxdy = ndimage.convolve(dem, kernel_xy)

    # Gradient components
    p = dz_dx
    q = dz_dy

    # Profile curvature (curvature in slope direction)
    denom_prof = (p**2 + q**2) * np.sqrt((1 + p**2 + q**2)**3)
    denom_prof = np.where(denom_prof == 0, 1e-10, denom_prof)  # Avoid division by zero

    profile_curv = -(p**2 * d2z_dx2 + 2*p*q*d2z_dxdy + q**2 * d2z_dy2) / denom_prof

    # Plan curvature (curvature perpendicular to slope)
    denom_plan = (p**2 + q**2) * np.sqrt(1 + p**2 + q**2)
    denom_plan = np.where(denom_plan == 0, 1e-10, denom_plan)

    plan_curv = -(q**2 * d2z_dx2 - 2*p*q*d2z_dxdy + p**2 * d2z_dy2) / denom_plan

    # Total curvature (Laplacian)
    total_curv = d2z_dx2 + d2z_dy2

    return profile_curv, plan_curv, total_curv


# =============================================================================
# TOPOGRAPHIC POSITION INDEX (TPI)
# =============================================================================

def compute_tpi(dem: np.ndarray, inner_radius: int = 0, outer_radius: int = 10) -> np.ndarray:
    """
    Compute Topographic Position Index.

    TPI = elevation - mean elevation in annular neighborhood

    Positive TPI: ridges, terraces (elevated above surroundings)
    Negative TPI: valleys, channels (below surroundings)
    Near-zero TPI: flat areas or constant slopes

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model array
    inner_radius : int
        Inner radius of annulus in cells
    outer_radius : int
        Outer radius of annulus in cells

    Returns:
    --------
    np.ndarray : TPI values
    """
    # Create annular kernel
    y, x = np.ogrid[-outer_radius:outer_radius+1, -outer_radius:outer_radius+1]
    distance = np.sqrt(x**2 + y**2)

    kernel = ((distance >= inner_radius) & (distance <= outer_radius)).astype(float)
    kernel = kernel / kernel.sum()  # Normalize

    # Compute mean in neighborhood
    mean_elev = ndimage.convolve(dem, kernel, mode='nearest')

    # TPI = elevation - neighborhood mean
    tpi = dem - mean_elev

    return tpi


def classify_landform(tpi: np.ndarray, slope: np.ndarray,
                      tpi_threshold: float = 2.0,
                      slope_threshold: float = 5.0) -> np.ndarray:
    """
    Classify landforms based on TPI and slope.

    Classes:
    1 = Valley/Channel (low TPI, any slope)
    2 = Floodplain (low TPI, low slope)
    3 = Slope/Hillside (mid TPI, high slope)
    4 = Flat terrace surface (mid TPI, low slope)
    5 = Terrace scarp edge (mid TPI, high slope + high profile curvature)
    6 = Elevated terrace (high TPI, low slope)
    7 = Ridge (high TPI, high slope)

    Parameters:
    -----------
    tpi : np.ndarray
        Topographic Position Index
    slope : np.ndarray
        Slope in degrees
    tpi_threshold : float
        Threshold for high/low TPI classification
    slope_threshold : float
        Threshold for high/low slope classification

    Returns:
    --------
    np.ndarray : Landform classification (integer codes)
    """
    landform = np.zeros_like(tpi, dtype=np.int8)

    # Low TPI (valleys, channels, floodplains)
    low_tpi = tpi < -tpi_threshold
    landform = np.where(low_tpi & (slope < slope_threshold), 2, landform)  # Floodplain
    landform = np.where(low_tpi & (slope >= slope_threshold), 1, landform)  # Valley

    # Mid TPI (slopes and flat areas)
    mid_tpi = (tpi >= -tpi_threshold) & (tpi <= tpi_threshold)
    landform = np.where(mid_tpi & (slope < slope_threshold), 4, landform)  # Flat
    landform = np.where(mid_tpi & (slope >= slope_threshold), 3, landform)  # Slope

    # High TPI (terraces and ridges)
    high_tpi = tpi > tpi_threshold
    landform = np.where(high_tpi & (slope < slope_threshold), 6, landform)  # Terrace
    landform = np.where(high_tpi & (slope >= slope_threshold), 7, landform)  # Ridge

    return landform


# =============================================================================
# TERRAIN RUGGEDNESS INDEX (TRI)
# =============================================================================

def compute_tri(dem: np.ndarray, window_size: int = 3) -> np.ndarray:
    """
    Compute Terrain Ruggedness Index.

    TRI = sqrt(sum((z_i - z_center)^2) / n)

    Higher values indicate more rugged terrain.

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model array
    window_size : int
        Window size for analysis

    Returns:
    --------
    np.ndarray : TRI values
    """
    def tri_func(values):
        center = values[len(values) // 2]
        return np.sqrt(np.sum((values - center)**2) / (len(values) - 1))

    tri = generic_filter(dem, tri_func, size=window_size)

    return tri


# =============================================================================
# HILLSHADE
# =============================================================================

def compute_hillshade(dem: np.ndarray, cell_size: float = 30.0,
                      azimuth: float = 315, altitude: float = 45) -> np.ndarray:
    """
    Compute hillshade for visualization.

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model array
    cell_size : float
        Cell size in meters
    azimuth : float
        Light source azimuth in degrees (0=North, 90=East)
    altitude : float
        Light source altitude in degrees above horizon

    Returns:
    --------
    np.ndarray : Hillshade values (0-255)
    """
    # Convert angles to radians
    azimuth_rad = np.radians(360 - azimuth + 90)  # Convert to math convention
    altitude_rad = np.radians(altitude)

    # Compute slope and aspect
    slope = compute_slope(dem, cell_size)
    aspect = compute_aspect(dem)

    slope_rad = np.radians(slope)
    aspect_rad = np.radians(aspect)

    # Hillshade formula
    hillshade = (np.sin(altitude_rad) * np.cos(slope_rad) +
                 np.cos(altitude_rad) * np.sin(slope_rad) *
                 np.cos(azimuth_rad - aspect_rad))

    # Scale to 0-255
    hillshade = (hillshade * 255).astype(np.uint8)

    return hillshade


# =============================================================================
# SCARP DETECTION
# =============================================================================

def detect_scarps(slope: np.ndarray, profile_curv: np.ndarray,
                  min_slope: float = 15.0, min_curv: float = 0.01) -> np.ndarray:
    """
    Detect potential terrace scarps based on slope and curvature.

    Scarps are characterized by:
    - High slope values
    - High profile curvature (convex at top, concave at base)
    - Linear continuity

    Parameters:
    -----------
    slope : np.ndarray
        Slope in degrees
    profile_curv : np.ndarray
        Profile curvature
    min_slope : float
        Minimum slope threshold for scarp detection
    min_curv : float
        Minimum profile curvature for scarp edges

    Returns:
    --------
    np.ndarray : Scarp probability (0-1)
    """
    # Normalize inputs
    slope_norm = np.clip(slope / 45.0, 0, 1)  # 45 degrees = max expected
    curv_norm = np.clip(np.abs(profile_curv) / 0.1, 0, 1)

    # High slope areas
    high_slope = slope >= min_slope

    # High curvature (both convex and concave)
    high_curv = np.abs(profile_curv) >= min_curv

    # Combine: scarp probability
    scarp_prob = slope_norm * 0.7 + curv_norm * 0.3
    scarp_prob = np.where(high_slope & high_curv, scarp_prob, scarp_prob * 0.5)

    return scarp_prob


def extract_scarp_lines(scarp_prob: np.ndarray, threshold: float = 0.5,
                        min_length_px: int = 5) -> np.ndarray:
    """
    Extract linear scarp features from probability raster.

    Uses morphological operations and connected component analysis.

    Parameters:
    -----------
    scarp_prob : np.ndarray
        Scarp probability (0-1)
    threshold : float
        Threshold for binary classification
    min_length_px : int
        Minimum length in pixels for a valid scarp

    Returns:
    --------
    np.ndarray : Binary scarp mask
    """
    from scipy.ndimage import label, binary_dilation, binary_erosion

    # Threshold to binary
    binary = scarp_prob >= threshold

    # Morphological cleaning
    binary = binary_erosion(binary, iterations=1)
    binary = binary_dilation(binary, iterations=1)

    # Connected component analysis
    labeled, num_features = label(binary)

    # Remove small components
    cleaned = np.zeros_like(binary)
    for i in range(1, num_features + 1):
        component = labeled == i
        if np.sum(component) >= min_length_px:
            cleaned = cleaned | component

    return cleaned


# =============================================================================
# MAIN PROCESSING PIPELINE
# =============================================================================

def process_dem(dem_path: str, output_prefix: str = "cicra") -> dict:
    """
    Full terrain analysis pipeline.

    Parameters:
    -----------
    dem_path : str
        Path to input DEM GeoTIFF
    output_prefix : str
        Prefix for output files

    Returns:
    --------
    dict : Paths to all output files
    """
    if rasterio is None or ndimage is None:
        print("Required packages not installed. Please install rasterio and scipy.")
        return None

    print(f"Processing DEM: {dem_path}")

    # Read DEM
    with rasterio.open(dem_path) as src:
        dem = src.read(1).astype(np.float32)
        profile = src.profile.copy()
        transform = src.transform
        crs = src.crs

        # Get cell size
        cell_size = abs(transform[0])  # Assumes square pixels

    # Handle nodata
    nodata = profile.get('nodata', -9999)
    mask = dem == nodata
    dem = np.where(mask, np.nan, dem)

    print(f"  DEM shape: {dem.shape}")
    print(f"  Cell size: {cell_size:.2f} m")
    print(f"  Elevation range: {np.nanmin(dem):.1f} - {np.nanmax(dem):.1f} m")

    # Compute derivatives
    print("\nComputing terrain derivatives...")

    print("  - Slope")
    slope = compute_slope(dem, cell_size)

    print("  - Aspect")
    aspect = compute_aspect(dem)

    print("  - Curvature")
    profile_curv, plan_curv, total_curv = compute_curvature(dem, cell_size)

    print("  - TPI")
    tpi = compute_tpi(dem,
                      inner_radius=TPI_PARAMS["inner_radius"],
                      outer_radius=TPI_PARAMS["outer_radius"])

    print("  - TRI")
    tri = compute_tri(dem)

    print("  - Hillshade")
    hillshade = compute_hillshade(dem, cell_size)

    print("  - Landform classification")
    landform = classify_landform(tpi, slope,
                                  tpi_threshold=TPI_PARAMS["terrace_threshold"],
                                  slope_threshold=SLOPE_PARAMS["terrace_max_degrees"])

    print("  - Scarp detection")
    scarp_prob = detect_scarps(slope, profile_curv,
                               min_slope=SLOPE_PARAMS["scarp_min_degrees"],
                               min_curv=CURVATURE_PARAMS["profile_threshold"])

    # Save outputs
    print("\nSaving outputs...")
    outputs = {}

    def save_raster(data, name, dtype='float32'):
        out_path = os.path.join(GEOTIFF_DIR, f"{output_prefix}_{name}.tif")
        out_profile = profile.copy()
        out_profile.update(dtype=dtype, count=1, compress='lzw')

        # Handle NaN values
        if dtype == 'float32':
            data = np.where(mask, nodata, data)
        else:
            data = np.where(mask, 0, data)

        with rasterio.open(out_path, 'w', **out_profile) as dst:
            dst.write(data.astype(dtype), 1)

        print(f"  Saved: {out_path}")
        outputs[name] = out_path
        return out_path

    save_raster(slope, "slope")
    save_raster(aspect, "aspect")
    save_raster(profile_curv, "profile_curvature")
    save_raster(plan_curv, "plan_curvature")
    save_raster(tpi, "tpi")
    save_raster(tri, "tri")
    save_raster(hillshade, "hillshade", dtype='uint8')
    save_raster(landform, "landform", dtype='int8')
    save_raster(scarp_prob, "scarp_probability")

    print("\nTerrain analysis complete!")

    return outputs


# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

def main():
    """Main entry point."""
    import glob

    print("=" * 60)
    print("CICRA TERRAIN ANALYSIS")
    print("=" * 60)

    # Find DEM files
    dem_files = glob.glob(os.path.join(DEM_DIR, "*.tif"))

    if not dem_files:
        print(f"\nNo DEM files found in: {DEM_DIR}")
        print("Please run 01_download_dem.py first, or manually place DEM files in the data/dem directory.")
        print("\nExpected file format: GeoTIFF (.tif)")
        return

    print(f"\nFound {len(dem_files)} DEM file(s):")
    for f in dem_files:
        print(f"  - {os.path.basename(f)}")

    # Process each DEM
    for dem_path in dem_files:
        prefix = os.path.splitext(os.path.basename(dem_path))[0]
        outputs = process_dem(dem_path, output_prefix=prefix)

        if outputs:
            print(f"\nOutputs for {prefix}:")
            for name, path in outputs.items():
                print(f"  {name}: {path}")

    print("\n" + "=" * 60)
    print("ANALYSIS COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
