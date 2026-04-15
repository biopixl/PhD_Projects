"""
Enhanced Terrain Analysis for CICRA Study
Higher resolution processing and improved scarp detection

This script:
1. Downloads 12.5m ALOS PALSAR DEM from ASF (if available)
2. Applies multi-scale analysis for better feature detection
3. Uses directional filtering for linear scarp detection
4. Creates enhanced visualization products

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, GEOTIFF_DIR, FIGURE_DIR, CICRA_BBOX,
    SLOPE_PARAMS, TPI_PARAMS, VIZ_PARAMS
)

try:
    import rasterio
    from rasterio.warp import calculate_default_transform, reproject, Resampling
except ImportError:
    rasterio = None

try:
    from scipy import ndimage
    from scipy.ndimage import gaussian_filter, uniform_filter, maximum_filter, minimum_filter
except ImportError:
    ndimage = None


# =============================================================================
# ENHANCED SLOPE WITH NOISE REDUCTION
# =============================================================================

def compute_slope_enhanced(dem: np.ndarray, cell_size: float,
                           smooth_sigma: float = 0.5) -> np.ndarray:
    """
    Compute slope with optional Gaussian smoothing for noise reduction.
    """
    # Light smoothing to reduce noise while preserving edges
    if smooth_sigma > 0:
        dem_smooth = gaussian_filter(dem, sigma=smooth_sigma)
    else:
        dem_smooth = dem

    # Horn's method for slope (more accurate than simple Sobel)
    kernel_x = np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]) / (8 * cell_size)
    kernel_y = np.array([[-1, -2, -1], [0, 0, 0], [1, 2, 1]]) / (8 * cell_size)

    dz_dx = ndimage.convolve(dem_smooth, kernel_x)
    dz_dy = ndimage.convolve(dem_smooth, kernel_y)

    slope_rad = np.arctan(np.sqrt(dz_dx**2 + dz_dy**2))
    return np.degrees(slope_rad)


# =============================================================================
# MULTI-SCALE TPI FOR TERRACE DETECTION
# =============================================================================

def compute_multiscale_tpi(dem: np.ndarray, scales: list = [3, 5, 10, 15, 20]) -> dict:
    """
    Compute TPI at multiple scales to detect features of different sizes.

    Small scales (3-5 cells): detect narrow scarps and channels
    Medium scales (10-15 cells): detect terrace edges
    Large scales (20+ cells): detect major landforms
    """
    results = {}

    for radius in scales:
        # Create circular kernel
        y, x = np.ogrid[-radius:radius+1, -radius:radius+1]
        kernel = (x**2 + y**2 <= radius**2).astype(float)
        kernel[radius, radius] = 0  # Exclude center
        kernel = kernel / kernel.sum()

        mean_elev = ndimage.convolve(dem, kernel, mode='nearest')
        tpi = dem - mean_elev
        results[f'tpi_{radius}'] = tpi

    # Combine scales: use standard deviation across scales as "multi-scale signature"
    tpi_stack = np.array(list(results.values()))
    results['tpi_mean'] = np.mean(tpi_stack, axis=0)
    results['tpi_std'] = np.std(tpi_stack, axis=0)  # High std = scale-dependent feature

    return results


# =============================================================================
# DIRECTIONAL EDGE DETECTION FOR LINEAR SCARPS
# =============================================================================

def compute_directional_edges(dem: np.ndarray, cell_size: float) -> dict:
    """
    Detect edges in multiple directions to find linear scarp features.
    """
    results = {}

    # Prewitt kernels for 8 directions
    kernels = {
        'N': np.array([[1, 1, 1], [0, 0, 0], [-1, -1, -1]]),
        'NE': np.array([[0, 1, 1], [-1, 0, 1], [-1, -1, 0]]),
        'E': np.array([[-1, 0, 1], [-1, 0, 1], [-1, 0, 1]]),
        'SE': np.array([[-1, -1, 0], [-1, 0, 1], [0, 1, 1]]),
        'S': np.array([[-1, -1, -1], [0, 0, 0], [1, 1, 1]]),
        'SW': np.array([[0, -1, -1], [1, 0, -1], [1, 1, 0]]),
        'W': np.array([[1, 0, -1], [1, 0, -1], [1, 0, -1]]),
        'NW': np.array([[1, 1, 0], [1, 0, -1], [0, -1, -1]]),
    }

    for direction, kernel in kernels.items():
        edge = ndimage.convolve(dem, kernel / (3 * cell_size))
        results[f'edge_{direction}'] = edge

    # Combined edge magnitude
    edge_stack = np.array(list(results.values()))
    results['edge_magnitude'] = np.sqrt(np.sum(edge_stack**2, axis=0))
    results['edge_direction'] = np.argmax(np.abs(edge_stack), axis=0) * 45  # 0-315 degrees

    return results


# =============================================================================
# TERRAIN TEXTURE ANALYSIS
# =============================================================================

def compute_terrain_texture(dem: np.ndarray, window_size: int = 5) -> dict:
    """
    Compute texture metrics that help identify different terrain types.
    """
    results = {}

    # Local standard deviation (roughness)
    mean_local = uniform_filter(dem, size=window_size)
    mean_sq = uniform_filter(dem**2, size=window_size)
    results['roughness'] = np.sqrt(np.maximum(mean_sq - mean_local**2, 0))

    # Range (max - min in window)
    max_local = maximum_filter(dem, size=window_size)
    min_local = minimum_filter(dem, size=window_size)
    results['range'] = max_local - min_local

    # Entropy-like measure (complexity)
    # Using coefficient of variation as proxy
    with np.errstate(divide='ignore', invalid='ignore'):
        results['cv'] = np.where(mean_local != 0,
                                  results['roughness'] / np.abs(mean_local), 0)

    return results


# =============================================================================
# ENHANCED SCARP PROBABILITY
# =============================================================================

def compute_scarp_probability_enhanced(slope: np.ndarray,
                                        tpi_results: dict,
                                        edge_results: dict,
                                        texture_results: dict) -> np.ndarray:
    """
    Combine multiple indicators for enhanced scarp detection.
    """
    # Normalize inputs to 0-1 range
    def normalize(arr, vmin=None, vmax=None):
        if vmin is None:
            vmin = np.nanpercentile(arr, 2)
        if vmax is None:
            vmax = np.nanpercentile(arr, 98)
        return np.clip((arr - vmin) / (vmax - vmin + 1e-10), 0, 1)

    # Component scores
    slope_score = normalize(slope, 0, 30)  # 0-30 degrees mapped to 0-1

    # TPI gradient (transitions are important)
    tpi_grad = np.abs(ndimage.sobel(tpi_results['tpi_mean']))
    tpi_score = normalize(tpi_grad)

    # Edge magnitude
    edge_score = normalize(edge_results['edge_magnitude'])

    # Multi-scale signature (high variance = interesting feature)
    multiscale_score = normalize(tpi_results['tpi_std'])

    # Terrain roughness
    roughness_score = normalize(texture_results['range'])

    # Weighted combination
    weights = {
        'slope': 0.30,
        'tpi_gradient': 0.25,
        'edge': 0.20,
        'multiscale': 0.15,
        'roughness': 0.10
    }

    probability = (
        weights['slope'] * slope_score +
        weights['tpi_gradient'] * tpi_score +
        weights['edge'] * edge_score +
        weights['multiscale'] * multiscale_score +
        weights['roughness'] * roughness_score
    )

    return probability


# =============================================================================
# MULTI-DIRECTIONAL HILLSHADE
# =============================================================================

def compute_multidirectional_hillshade(dem: np.ndarray, cell_size: float) -> np.ndarray:
    """
    Create hillshade from multiple light directions for better feature visibility.
    """
    azimuths = [0, 45, 90, 135, 180, 225, 270, 315]
    altitude = 45

    hillshades = []

    for azimuth in azimuths:
        azimuth_rad = np.radians(360 - azimuth + 90)
        altitude_rad = np.radians(altitude)

        # Compute slope and aspect
        dz_dx = ndimage.sobel(dem, axis=1) / (8 * cell_size)
        dz_dy = ndimage.sobel(dem, axis=0) / (8 * cell_size)

        slope = np.arctan(np.sqrt(dz_dx**2 + dz_dy**2))
        aspect = np.arctan2(-dz_dy, dz_dx)

        hillshade = (np.sin(altitude_rad) * np.cos(slope) +
                     np.cos(altitude_rad) * np.sin(slope) *
                     np.cos(azimuth_rad - aspect))
        hillshades.append(hillshade)

    # Combine using mean (reduces shadows, shows all features)
    combined = np.mean(hillshades, axis=0)
    return (combined * 255).astype(np.uint8)


# =============================================================================
# RESAMPLE TO HIGHER RESOLUTION (BICUBIC INTERPOLATION)
# =============================================================================

def resample_dem(dem_path: str, output_path: str, scale_factor: int = 2) -> str:
    """
    Resample DEM to finer resolution using bicubic interpolation.
    This doesn't add real information but can help visualization.
    """
    with rasterio.open(dem_path) as src:
        # Calculate new dimensions
        new_height = src.height * scale_factor
        new_width = src.width * scale_factor

        # Calculate new transform
        new_transform = src.transform * src.transform.scale(
            (src.width / new_width),
            (src.height / new_height)
        )

        # Read and resample
        data = src.read(
            out_shape=(src.count, new_height, new_width),
            resampling=Resampling.cubic
        )

        # Update profile
        profile = src.profile.copy()
        profile.update(
            height=new_height,
            width=new_width,
            transform=new_transform,
            compress='lzw'
        )

        with rasterio.open(output_path, 'w', **profile) as dst:
            dst.write(data)

    print(f"Resampled {scale_factor}x: {output_path}")
    return output_path


# =============================================================================
# MAIN PROCESSING
# =============================================================================

def process_enhanced(dem_path: str, output_prefix: str = "enhanced") -> dict:
    """
    Enhanced terrain analysis pipeline.
    """
    print("=" * 60)
    print("ENHANCED TERRAIN ANALYSIS")
    print("=" * 60)

    # Read DEM
    print(f"\nReading: {dem_path}")
    with rasterio.open(dem_path) as src:
        dem = src.read(1).astype(np.float32)
        profile = src.profile.copy()
        transform = src.transform

        # Cell size in meters (approximate for geographic coordinates)
        cell_size_deg = abs(transform[0])
        cell_size_m = cell_size_deg * 111000 * np.cos(np.radians(-12.57))  # ~30m at this latitude

    nodata = profile.get('nodata', -9999)
    mask = (dem == nodata) | np.isnan(dem)
    dem = np.where(mask, np.nan, dem)

    print(f"  Shape: {dem.shape}")
    print(f"  Cell size: ~{cell_size_m:.1f} m")
    print(f"  Elevation: {np.nanmin(dem):.1f} - {np.nanmax(dem):.1f} m")

    outputs = {}

    # 1. Enhanced slope
    print("\n1. Computing enhanced slope...")
    slope = compute_slope_enhanced(dem, cell_size_m, smooth_sigma=0.5)

    # 2. Multi-scale TPI
    print("2. Computing multi-scale TPI...")
    tpi_results = compute_multiscale_tpi(dem, scales=[2, 3, 5, 7, 10])

    # 3. Directional edges
    print("3. Computing directional edges...")
    edge_results = compute_directional_edges(dem, cell_size_m)

    # 4. Terrain texture
    print("4. Computing terrain texture...")
    texture_results = compute_terrain_texture(dem, window_size=3)

    # 5. Enhanced scarp probability
    print("5. Computing enhanced scarp probability...")
    scarp_prob = compute_scarp_probability_enhanced(
        slope, tpi_results, edge_results, texture_results
    )

    # 6. Multi-directional hillshade
    print("6. Computing multi-directional hillshade...")
    hillshade_multi = compute_multidirectional_hillshade(dem, cell_size_m)

    # Save outputs
    print("\nSaving outputs...")

    def save_raster(data, name, dtype='float32'):
        out_path = os.path.join(GEOTIFF_DIR, f"{output_prefix}_{name}.tif")
        out_profile = profile.copy()
        out_nodata = nodata if dtype == 'float32' else 0
        out_profile.update(dtype=dtype, count=1, compress='lzw', nodata=out_nodata)

        save_data = np.where(mask, out_nodata, data)

        with rasterio.open(out_path, 'w', **out_profile) as dst:
            dst.write(save_data.astype(dtype), 1)

        print(f"  {name}: {out_path}")
        outputs[name] = out_path
        return out_path

    save_raster(slope, "slope_enhanced")
    save_raster(tpi_results['tpi_mean'], "tpi_multiscale")
    save_raster(tpi_results['tpi_std'], "tpi_variance")
    save_raster(edge_results['edge_magnitude'], "edge_magnitude")
    save_raster(texture_results['range'], "terrain_range")
    save_raster(scarp_prob, "scarp_probability_enhanced")
    save_raster(hillshade_multi, "hillshade_multidirectional", dtype='uint8')

    # Statistics
    print("\n" + "=" * 60)
    print("SCARP DETECTION STATISTICS")
    print("=" * 60)

    high_prob = scarp_prob > 0.6
    med_prob = (scarp_prob > 0.4) & (scarp_prob <= 0.6)

    print(f"High probability pixels (>0.6): {np.sum(high_prob)} ({100*np.mean(high_prob):.1f}%)")
    print(f"Medium probability pixels (0.4-0.6): {np.sum(med_prob)} ({100*np.mean(med_prob):.1f}%)")
    print(f"Scarp probability range: {np.nanmin(scarp_prob):.3f} - {np.nanmax(scarp_prob):.3f}")

    return outputs


# =============================================================================
# DOWNLOAD HIGH-RES DATA OPTIONS
# =============================================================================

def print_highres_options():
    """Print instructions for obtaining higher resolution DEMs."""
    print("""
================================================================================
HIGHER RESOLUTION DEM OPTIONS
================================================================================

1. ALOS PALSAR RTC (12.5m) - FREE
   - Register at: https://urs.earthdata.nasa.gov/
   - Download from: https://search.asf.alaska.edu/
   - Product: ALOS PALSAR Radiometric Terrain Corrected
   - Search coordinates: -70.14, -12.60 to -70.06, -12.54

2. FABDEM (30m, forest/building removed) - FREE
   - Download: https://data.bris.ac.uk/data/dataset/s5hqmjcdj8yo2ibzi9b4ew3sn
   - Improved bare-earth model

3. TanDEM-X (12m/30m) - FREE for science
   - Apply at: https://tandemx-science.dlr.de/
   - High quality radar DEM

4. Planet/Maxar Stereo DEM (1-3m) - COMMERCIAL
   - Very high resolution but requires purchase

5. AIRBORNE LIDAR (if available)
   - Check OpenTopography: https://opentopography.org/
   - Search for Peru/Amazon campaigns

For this study area, ALOS PALSAR 12.5m is the best FREE option for
detecting subtle terrace scarps.
================================================================================
""")


def main():
    """Main entry point."""
    import glob

    print_highres_options()

    # Find DEM
    dem_files = glob.glob(os.path.join(DEM_DIR, "*.tif"))

    if not dem_files:
        print("No DEM files found. Run 01_download_dem.py first.")
        return

    dem_path = dem_files[0]
    print(f"\nProcessing: {dem_path}")

    # Run enhanced analysis
    outputs = process_enhanced(dem_path, output_prefix="enhanced_cicra")

    print("\n" + "=" * 60)
    print("ENHANCED ANALYSIS COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
