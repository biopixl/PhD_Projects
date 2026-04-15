"""
Terrace Scarp Detection Algorithm for CICRA Study
Madre de Dios, Peru

This script identifies linear scarp features that mark boundaries
between terra firme (upland terraces) and active floodplains.

These scarps are key targets for locating flood-buried forest deposits,
as they represent erosional exposures of terrace stratigraphy.

Algorithm:
1. Multi-scale TPI analysis
2. Slope-curvature edge detection
3. Morphological filtering for linear features
4. Aspect-based orientation analysis
5. Vectorization and attribute extraction

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple, Optional

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    GEOTIFF_DIR, OUTPUT_DIR, VECTOR_DIR,
    SLOPE_PARAMS, TPI_PARAMS, SCARP_PARAMS,
    SAMPLING_LOCATIONS, VIZ_PARAMS
)

try:
    import rasterio
    from rasterio.features import shapes
except ImportError:
    rasterio = None

try:
    from scipy import ndimage
    from scipy.ndimage import label, binary_dilation, binary_erosion
    from scipy.ndimage import distance_transform_edt
    from skimage.morphology import skeletonize, remove_small_objects
    from skimage.measure import regionprops, label as sk_label
except ImportError:
    ndimage = None


# =============================================================================
# SCARP DETECTION CLASSES
# =============================================================================

@dataclass
class ScarpFeature:
    """Detected scarp feature with attributes."""
    id: int
    length_m: float
    mean_height_m: float
    mean_slope_deg: float
    orientation_deg: float  # Dominant orientation (0=N-S, 90=E-W)
    centroid: Tuple[float, float]  # (lon, lat)
    geometry: object  # Shapely geometry or coordinate array
    confidence: float  # Detection confidence (0-1)


# =============================================================================
# MULTI-SCALE TPI ANALYSIS
# =============================================================================

def compute_multiscale_tpi(dem: np.ndarray, scales: List[int] = [5, 10, 20, 50]) -> np.ndarray:
    """
    Compute TPI at multiple scales and combine.

    Terrace scarps show characteristic TPI signatures:
    - Positive TPI on terrace surface
    - Strong gradient across scarp
    - Negative TPI on floodplain

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model
    scales : list
        List of radii (in cells) for TPI computation

    Returns:
    --------
    np.ndarray : Multi-scale TPI composite
    """
    tpi_stack = []

    for radius in scales:
        # Create circular kernel
        y, x = np.ogrid[-radius:radius+1, -radius:radius+1]
        kernel = (x**2 + y**2 <= radius**2).astype(float)
        kernel = kernel / kernel.sum()

        # Mean elevation in neighborhood
        mean_elev = ndimage.convolve(dem, kernel, mode='nearest')

        # TPI at this scale
        tpi = dem - mean_elev
        tpi_stack.append(tpi)

    # Combine scales (variance indicates scale-dependent features)
    tpi_stack = np.array(tpi_stack)
    tpi_mean = np.mean(tpi_stack, axis=0)
    tpi_std = np.std(tpi_stack, axis=0)

    # Features consistent across scales have low variance
    # Features varying with scale (like scarps) have high variance
    return tpi_mean, tpi_std


def compute_tpi_gradient(tpi: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """
    Compute TPI gradient magnitude and direction.

    Strong TPI gradients indicate terrace edges.

    Returns:
    --------
    tuple : (gradient_magnitude, gradient_direction)
    """
    # Gradient using Sobel filter
    grad_x = ndimage.sobel(tpi, axis=1)
    grad_y = ndimage.sobel(tpi, axis=0)

    magnitude = np.sqrt(grad_x**2 + grad_y**2)
    direction = np.degrees(np.arctan2(grad_y, grad_x))

    return magnitude, direction


# =============================================================================
# EDGE DETECTION ALGORITHMS
# =============================================================================

def detect_edges_canny(slope: np.ndarray, low_thresh: float = 10,
                       high_thresh: float = 20) -> np.ndarray:
    """
    Canny-like edge detection on slope raster.

    Parameters:
    -----------
    slope : np.ndarray
        Slope in degrees
    low_thresh : float
        Low threshold for hysteresis
    high_thresh : float
        High threshold for hysteresis

    Returns:
    --------
    np.ndarray : Binary edge mask
    """
    from scipy.ndimage import gaussian_filter

    # Smooth input
    smoothed = gaussian_filter(slope, sigma=1)

    # Gradient magnitude
    grad_x = ndimage.sobel(smoothed, axis=1)
    grad_y = ndimage.sobel(smoothed, axis=0)
    magnitude = np.sqrt(grad_x**2 + grad_y**2)
    direction = np.arctan2(grad_y, grad_x)

    # Non-maximum suppression
    nms = np.zeros_like(magnitude)
    angle = np.degrees(direction) % 180

    for i in range(1, magnitude.shape[0] - 1):
        for j in range(1, magnitude.shape[1] - 1):
            # Determine neighbors based on gradient direction
            if (0 <= angle[i,j] < 22.5) or (157.5 <= angle[i,j] <= 180):
                neighbors = [magnitude[i, j-1], magnitude[i, j+1]]
            elif 22.5 <= angle[i,j] < 67.5:
                neighbors = [magnitude[i-1, j+1], magnitude[i+1, j-1]]
            elif 67.5 <= angle[i,j] < 112.5:
                neighbors = [magnitude[i-1, j], magnitude[i+1, j]]
            else:
                neighbors = [magnitude[i-1, j-1], magnitude[i+1, j+1]]

            if magnitude[i,j] >= max(neighbors):
                nms[i,j] = magnitude[i,j]

    # Double threshold with hysteresis
    strong = nms >= high_thresh
    weak = (nms >= low_thresh) & (nms < high_thresh)

    # Connect weak edges to strong edges
    edges = strong.copy()
    edges = binary_dilation(edges, iterations=2)
    edges = edges & (strong | weak)

    return edges


def detect_scarp_edges(slope: np.ndarray, profile_curv: np.ndarray,
                       tpi: np.ndarray) -> np.ndarray:
    """
    Combine multiple criteria for scarp edge detection.

    Parameters:
    -----------
    slope : np.ndarray
        Slope in degrees
    profile_curv : np.ndarray
        Profile curvature
    tpi : np.ndarray
        Topographic Position Index

    Returns:
    --------
    np.ndarray : Scarp probability (0-1)
    """
    # Criteria 1: High slope
    slope_score = np.clip(slope / SLOPE_PARAMS["scarp_high_degrees"], 0, 1)

    # Criteria 2: High profile curvature (scarp edges are convex/concave)
    curv_abs = np.abs(profile_curv)
    curv_score = np.clip(curv_abs / 0.05, 0, 1)

    # Criteria 3: TPI gradient (transition from terrace to floodplain)
    tpi_grad, _ = compute_tpi_gradient(tpi)
    tpi_score = np.clip(tpi_grad / 5.0, 0, 1)

    # Combine with weights
    combined = (slope_score * 0.5 +
                curv_score * 0.25 +
                tpi_score * 0.25)

    return combined


# =============================================================================
# MORPHOLOGICAL PROCESSING
# =============================================================================

def extract_linear_features(binary: np.ndarray, min_length_px: int = 10,
                            max_width_px: int = 5) -> np.ndarray:
    """
    Extract linear features from binary raster.

    Uses morphological operations to identify elongated features.

    Parameters:
    -----------
    binary : np.ndarray
        Binary edge mask
    min_length_px : int
        Minimum feature length in pixels
    max_width_px : int
        Maximum feature width in pixels

    Returns:
    --------
    np.ndarray : Binary mask of linear features
    """
    # Clean noise
    cleaned = binary_erosion(binary, iterations=1)
    cleaned = binary_dilation(cleaned, iterations=1)

    # Remove small objects
    cleaned = remove_small_objects(cleaned, min_size=min_length_px)

    # Skeletonize to get centerlines
    skeleton = skeletonize(cleaned)

    # Dilate skeleton slightly for visualization
    result = binary_dilation(skeleton, iterations=1)

    return result


def compute_feature_orientation(binary: np.ndarray, aspect: np.ndarray) -> np.ndarray:
    """
    Compute dominant orientation of linear features.

    Scarps perpendicular to river flow are most likely terrace edges.

    Parameters:
    -----------
    binary : np.ndarray
        Binary scarp mask
    aspect : np.ndarray
        Aspect (slope direction) in degrees

    Returns:
    --------
    np.ndarray : Orientation raster (degrees from north)
    """
    # Label connected components
    labeled, num_features = label(binary)

    orientation = np.zeros_like(binary, dtype=float)

    for i in range(1, num_features + 1):
        component = labeled == i

        # Get aspect values within component
        component_aspect = aspect[component]

        # Compute mean orientation (handling circular mean)
        sin_sum = np.sum(np.sin(np.radians(component_aspect)))
        cos_sum = np.sum(np.cos(np.radians(component_aspect)))
        mean_orient = np.degrees(np.arctan2(sin_sum, cos_sum)) % 180

        orientation[component] = mean_orient

    return orientation


# =============================================================================
# SCARP HEIGHT ESTIMATION
# =============================================================================

def estimate_scarp_height(dem: np.ndarray, scarp_mask: np.ndarray,
                          search_distance_px: int = 10) -> np.ndarray:
    """
    Estimate scarp height by comparing elevations above and below.

    Parameters:
    -----------
    dem : np.ndarray
        Digital elevation model
    scarp_mask : np.ndarray
        Binary scarp mask
    search_distance_px : int
        Distance to search for min/max elevation

    Returns:
    --------
    np.ndarray : Estimated scarp height at each scarp pixel
    """
    height = np.zeros_like(dem)

    # Get scarp pixels
    scarp_y, scarp_x = np.where(scarp_mask)

    for y, x in zip(scarp_y, scarp_x):
        # Define search window
        y_min = max(0, y - search_distance_px)
        y_max = min(dem.shape[0], y + search_distance_px + 1)
        x_min = max(0, x - search_distance_px)
        x_max = min(dem.shape[1], x + search_distance_px + 1)

        window = dem[y_min:y_max, x_min:x_max]

        if window.size > 0:
            # Height is difference between max and min in window
            window_valid = window[~np.isnan(window)]
            if len(window_valid) > 0:
                height[y, x] = np.max(window_valid) - np.min(window_valid)

    return height


# =============================================================================
# FEATURE VECTORIZATION
# =============================================================================

def vectorize_scarps(scarp_mask: np.ndarray, dem: np.ndarray,
                     slope: np.ndarray, transform, crs,
                     min_height: float = 2.0) -> List[ScarpFeature]:
    """
    Convert raster scarps to vector features with attributes.

    Parameters:
    -----------
    scarp_mask : np.ndarray
        Binary scarp mask
    dem : np.ndarray
        DEM for height calculation
    slope : np.ndarray
        Slope for attribute calculation
    transform : Affine
        Rasterio transform
    crs : CRS
        Coordinate reference system
    min_height : float
        Minimum scarp height to include

    Returns:
    --------
    list : List of ScarpFeature objects
    """
    from scipy.ndimage import label as scipy_label
    import json

    features = []

    # Estimate heights
    heights = estimate_scarp_height(dem, scarp_mask)

    # Label connected components
    labeled, num_features = scipy_label(scarp_mask)

    # Get cell size from transform
    cell_size = abs(transform[0])

    for i in range(1, num_features + 1):
        component = labeled == i

        # Skip small or low features
        component_heights = heights[component]
        mean_height = np.mean(component_heights)

        if mean_height < min_height:
            continue

        # Calculate attributes
        num_pixels = np.sum(component)
        length_m = num_pixels * cell_size  # Approximate length

        component_slopes = slope[component]
        mean_slope = np.mean(component_slopes)

        # Centroid in pixel coordinates
        y_coords, x_coords = np.where(component)
        centroid_y = np.mean(y_coords)
        centroid_x = np.mean(x_coords)

        # Convert to geographic coordinates
        lon = transform[2] + centroid_x * transform[0]
        lat = transform[5] + centroid_y * transform[4]

        # Estimate orientation from elongation
        if len(x_coords) > 2:
            # PCA for orientation
            coords = np.column_stack([x_coords, y_coords])
            cov = np.cov(coords.T)
            eigenvalues, eigenvectors = np.linalg.eig(cov)
            main_axis = eigenvectors[:, np.argmax(eigenvalues)]
            orientation = np.degrees(np.arctan2(main_axis[1], main_axis[0])) % 180
        else:
            orientation = 0

        # Confidence based on height and slope
        confidence = min(1.0, (mean_height / 5.0) * (mean_slope / 20.0))

        feature = ScarpFeature(
            id=i,
            length_m=length_m,
            mean_height_m=mean_height,
            mean_slope_deg=mean_slope,
            orientation_deg=orientation,
            centroid=(lon, lat),
            geometry=np.column_stack([x_coords, y_coords]),
            confidence=confidence
        )

        features.append(feature)

    return features


def save_scarps_geojson(features: List[ScarpFeature], output_path: str,
                        transform, crs) -> str:
    """
    Save scarp features to GeoJSON file.

    Parameters:
    -----------
    features : list
        List of ScarpFeature objects
    output_path : str
        Output file path
    transform : Affine
        Rasterio transform
    crs : CRS
        Coordinate reference system

    Returns:
    --------
    str : Path to output file
    """
    import json

    geojson = {
        "type": "FeatureCollection",
        "crs": {"type": "name", "properties": {"name": str(crs)}},
        "features": []
    }

    for scarp in features:
        # Convert pixel coordinates to geographic
        coords = []
        for px, py in scarp.geometry:
            lon = transform[2] + px * transform[0]
            lat = transform[5] + py * transform[4]
            coords.append([lon, lat])

        feature = {
            "type": "Feature",
            "properties": {
                "id": scarp.id,
                "length_m": round(scarp.length_m, 1),
                "height_m": round(scarp.mean_height_m, 2),
                "slope_deg": round(scarp.mean_slope_deg, 1),
                "orientation_deg": round(scarp.orientation_deg, 1),
                "confidence": round(scarp.confidence, 3)
            },
            "geometry": {
                "type": "MultiPoint",
                "coordinates": coords
            }
        }
        geojson["features"].append(feature)

    with open(output_path, 'w') as f:
        json.dump(geojson, f, indent=2)

    print(f"Saved {len(features)} scarp features to: {output_path}")
    return output_path


# =============================================================================
# MAIN DETECTION PIPELINE
# =============================================================================

def detect_scarps_full(dem_path: str, slope_path: str = None,
                       profile_curv_path: str = None,
                       tpi_path: str = None,
                       output_prefix: str = "cicra") -> dict:
    """
    Full scarp detection pipeline.

    Parameters:
    -----------
    dem_path : str
        Path to DEM GeoTIFF
    slope_path : str
        Path to slope GeoTIFF (optional, will compute if not provided)
    profile_curv_path : str
        Path to profile curvature GeoTIFF
    tpi_path : str
        Path to TPI GeoTIFF
    output_prefix : str
        Prefix for output files

    Returns:
    --------
    dict : Paths to outputs and feature list
    """
    if rasterio is None or ndimage is None:
        print("Required packages not installed.")
        return None

    print("=" * 60)
    print("SCARP DETECTION PIPELINE")
    print("=" * 60)

    # Read DEM
    print("\nLoading DEM...")
    with rasterio.open(dem_path) as src:
        dem = src.read(1).astype(np.float32)
        profile = src.profile.copy()
        transform = src.transform
        crs = src.crs
        cell_size = abs(transform[0])

    nodata = profile.get('nodata', -9999)
    mask = (dem == nodata) | np.isnan(dem)
    dem = np.where(mask, np.nan, dem)

    # Load or compute derivatives
    if slope_path and os.path.exists(slope_path):
        print("Loading slope...")
        with rasterio.open(slope_path) as src:
            slope = src.read(1)
    else:
        print("Computing slope...")
        from terrain_analysis import compute_slope
        slope = compute_slope(dem, cell_size)

    if tpi_path and os.path.exists(tpi_path):
        print("Loading TPI...")
        with rasterio.open(tpi_path) as src:
            tpi = src.read(1)
    else:
        print("Computing TPI...")
        tpi, tpi_std = compute_multiscale_tpi(dem)

    if profile_curv_path and os.path.exists(profile_curv_path):
        print("Loading profile curvature...")
        with rasterio.open(profile_curv_path) as src:
            profile_curv = src.read(1)
    else:
        print("Computing profile curvature...")
        from terrain_analysis import compute_curvature
        profile_curv, _, _ = compute_curvature(dem, cell_size)

    # Detect scarp edges
    print("\nDetecting scarp edges...")
    scarp_prob = detect_scarp_edges(slope, profile_curv, tpi)

    # Threshold and extract linear features
    print("Extracting linear features...")
    threshold = 0.4
    binary = scarp_prob >= threshold
    linear = extract_linear_features(binary,
                                     min_length_px=int(SCARP_PARAMS["min_length_m"] / cell_size))

    # Vectorize features
    print("Vectorizing features...")
    features = vectorize_scarps(linear, dem, slope, transform, crs,
                                min_height=SCARP_PARAMS["min_height_m"])

    print(f"\nDetected {len(features)} scarp features")

    # Save outputs
    print("\nSaving outputs...")
    outputs = {}

    # Save probability raster
    prob_path = os.path.join(GEOTIFF_DIR, f"{output_prefix}_scarp_probability.tif")
    out_profile = profile.copy()
    out_profile.update(dtype='float32', count=1, compress='lzw')
    with rasterio.open(prob_path, 'w', **out_profile) as dst:
        dst.write(np.where(mask, nodata, scarp_prob).astype(np.float32), 1)
    outputs['probability'] = prob_path
    print(f"  Saved: {prob_path}")

    # Save binary mask
    mask_path = os.path.join(GEOTIFF_DIR, f"{output_prefix}_scarp_mask.tif")
    out_profile.update(dtype='uint8')
    with rasterio.open(mask_path, 'w', **out_profile) as dst:
        dst.write(linear.astype(np.uint8), 1)
    outputs['mask'] = mask_path
    print(f"  Saved: {mask_path}")

    # Save GeoJSON
    geojson_path = os.path.join(VECTOR_DIR, f"{output_prefix}_scarps.geojson")
    save_scarps_geojson(features, geojson_path, transform, crs)
    outputs['geojson'] = geojson_path

    # Print feature summary
    print("\n" + "=" * 60)
    print("SCARP FEATURE SUMMARY")
    print("=" * 60)

    if features:
        heights = [f.mean_height_m for f in features]
        lengths = [f.length_m for f in features]
        slopes = [f.mean_slope_deg for f in features]

        print(f"Total features: {len(features)}")
        print(f"Height range: {min(heights):.1f} - {max(heights):.1f} m")
        print(f"Length range: {min(lengths):.0f} - {max(lengths):.0f} m")
        print(f"Slope range: {min(slopes):.1f} - {max(slopes):.1f} deg")

        # Identify features near sampling locations
        print("\nScarps near sampling locations:")
        for loc in SAMPLING_LOCATIONS:
            nearby = [f for f in features
                      if abs(f.centroid[0] - loc.longitude) < 0.01
                      and abs(f.centroid[1] - loc.latitude) < 0.01]
            if nearby:
                print(f"  {loc.name}: {len(nearby)} nearby scarp(s)")

    outputs['features'] = features
    return outputs


# =============================================================================
# MAIN
# =============================================================================

def main():
    """Main entry point."""
    import glob

    print("CICRA Scarp Detection")
    print("=" * 60)

    # Find DEM files
    dem_files = glob.glob(os.path.join(GEOTIFF_DIR, "*hillshade*.tif"))

    if not dem_files:
        # Try DEM directory
        dem_files = glob.glob(os.path.join(GEOTIFF_DIR.replace('geotiffs', 'dem'), "*.tif"))

    if not dem_files:
        print(f"\nNo DEM files found.")
        print("Please run 01_download_dem.py and 02_terrain_analysis.py first.")
        return

    # Use first DEM found
    dem_path = dem_files[0].replace('hillshade', 'dem') if 'hillshade' in dem_files[0] else dem_files[0]

    # Look for derivative files
    prefix = os.path.splitext(os.path.basename(dem_path))[0].replace('_dem', '')
    slope_path = os.path.join(GEOTIFF_DIR, f"{prefix}_slope.tif")
    tpi_path = os.path.join(GEOTIFF_DIR, f"{prefix}_tpi.tif")
    curv_path = os.path.join(GEOTIFF_DIR, f"{prefix}_profile_curvature.tif")

    # Run detection
    outputs = detect_scarps_full(
        dem_path,
        slope_path=slope_path if os.path.exists(slope_path) else None,
        tpi_path=tpi_path if os.path.exists(tpi_path) else None,
        profile_curv_path=curv_path if os.path.exists(curv_path) else None,
        output_prefix=prefix
    )

    if outputs:
        print("\nDetection complete!")


if __name__ == "__main__":
    main()
