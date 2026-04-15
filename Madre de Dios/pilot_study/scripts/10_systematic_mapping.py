"""
Systematic Mapping and Results Tracking
Generates organized maps for each data product and processing step

This script creates:
1. Individual maps for each data product
2. Variable-by-variable comparison figures
3. Results tracking CSV with statistics
4. Processing chain documentation

Author: Isaac
Date: 2024
"""

import os
import sys
import json
import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, GEOTIFF_DIR, FIGURE_DIR, GEDI_DIR,
    CICRA_BBOX, SAMPLING_LOCATIONS
)

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import LinearSegmentedColormap
import rasterio
from rasterio.transform import rowcol

# Results directory
RESULTS_DIR = os.path.join(Path(__file__).parent.parent, "results")

# Tracking data
RESULTS_TRACKING = []


def get_cicra_sites():
    """Get CICRA sampling sites (exclude Puerto Maldonado)."""
    return [loc for loc in SAMPLING_LOCATIONS if 'PM' not in loc.name]


def compute_statistics(data, name):
    """Compute statistics for a raster and add to tracking."""
    valid = data[~np.isnan(data)]
    stats = {
        'variable': name,
        'min': float(np.min(valid)),
        'max': float(np.max(valid)),
        'mean': float(np.mean(valid)),
        'std': float(np.std(valid)),
        'median': float(np.median(valid)),
        'p5': float(np.percentile(valid, 5)),
        'p95': float(np.percentile(valid, 95)),
        'n_valid': int(len(valid)),
        'n_total': int(data.size),
        'pct_valid': float(100 * len(valid) / data.size),
        'timestamp': datetime.now().isoformat()
    }
    RESULTS_TRACKING.append(stats)
    return stats


def create_standard_map(data, extent, title, output_path, cmap='viridis',
                        vmin=None, vmax=None, units='', sites=None,
                        add_colorbar=True, add_scalebar=True):
    """Create a standardized map figure."""
    fig, ax = plt.subplots(figsize=(10, 8))

    # Handle vmin/vmax
    if vmin is None:
        vmin = np.nanpercentile(data, 2)
    if vmax is None:
        vmax = np.nanpercentile(data, 98)

    # Plot raster
    im = ax.imshow(data, extent=extent, cmap=cmap, vmin=vmin, vmax=vmax, aspect='auto')

    # Add sampling sites
    if sites:
        for site in sites:
            ax.plot(site.longitude, site.latitude, 'k^', markersize=10,
                   markeredgecolor='white', markeredgewidth=1.5)
            ax.annotate(site.name.replace('_', ' ').replace('CICRA', '').replace('LOS AMIGOS', ''),
                       (site.longitude, site.latitude), fontsize=7,
                       xytext=(5, 5), textcoords='offset points',
                       bbox=dict(boxstyle='round,pad=0.2', facecolor='white', alpha=0.7))

    # Colorbar
    if add_colorbar:
        cbar = plt.colorbar(im, ax=ax, shrink=0.8, pad=0.02)
        cbar.set_label(units, fontsize=10)

    # Scale bar (approximate)
    if add_scalebar:
        scale_lon = extent[0] + 0.01
        scale_lat = extent[2] + 0.005
        scale_length = 0.01  # ~1.1 km at this latitude
        ax.plot([scale_lon, scale_lon + scale_length], [scale_lat, scale_lat],
                'k-', linewidth=3)
        ax.text(scale_lon + scale_length/2, scale_lat + 0.002, '1 km',
                ha='center', fontsize=8)

    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    ax.set_title(title, fontsize=12, fontweight='bold')

    # Add statistics box
    stats = compute_statistics(data, title)
    stats_text = f"Min: {stats['min']:.1f}\nMax: {stats['max']:.1f}\nMean: {stats['mean']:.1f}\nStd: {stats['std']:.1f}"
    ax.text(0.02, 0.98, stats_text, transform=ax.transAxes, fontsize=8,
            verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()

    print(f"  Saved: {os.path.basename(output_path)}")
    return stats


def process_dem_products():
    """Generate maps for each DEM product."""
    print("\n" + "="*60)
    print("01. DEM PRODUCTS")
    print("="*60)

    sites = get_cicra_sites()
    dem_dir = os.path.join(RESULTS_DIR, "01_DEM")

    dem_files = {
        'NASADEM': os.path.join(DEM_DIR, 'nasadem_cicra_30m.tif'),
        'Copernicus': os.path.join(DEM_DIR, 'copernicus_cicra_30m.tif')
    }

    dem_data = {}

    for name, path in dem_files.items():
        if os.path.exists(path):
            print(f"\nProcessing {name}...")
            with rasterio.open(path) as src:
                data = src.read(1).astype(np.float32)
                data = np.where(data == src.nodata, np.nan, data)
                extent = [src.bounds.left, src.bounds.right, src.bounds.bottom, src.bounds.top]
                dem_data[name] = {'data': data, 'extent': extent}

            # Create individual map
            output_path = os.path.join(dem_dir, name, f"{name}_elevation.png")
            create_standard_map(
                data, extent,
                f"{name} Digital Elevation Model (30m)",
                output_path, cmap='terrain',
                units='Elevation (m)', sites=sites
            )

            # Create hillshade
            from scipy import ndimage
            dz_dx = ndimage.sobel(data, axis=1)
            dz_dy = ndimage.sobel(data, axis=0)
            slope = np.arctan(np.sqrt(dz_dx**2 + dz_dy**2))
            aspect = np.arctan2(-dz_dy, dz_dx)
            azimuth = np.radians(315)
            altitude = np.radians(45)
            hillshade = np.sin(altitude) * np.cos(slope) + \
                       np.cos(altitude) * np.sin(slope) * np.cos(azimuth - aspect)

            output_path = os.path.join(dem_dir, name, f"{name}_hillshade.png")
            create_standard_map(
                hillshade, extent,
                f"{name} Hillshade",
                output_path, cmap='gray', vmin=0, vmax=1,
                units='Illumination', sites=sites
            )

    # Create comparison if both exist
    if len(dem_data) == 2:
        print("\nGenerating DEM comparison...")
        nasa = dem_data['NASADEM']['data']
        cop = dem_data['Copernicus']['data']
        diff = nasa - cop

        output_path = os.path.join(dem_dir, "comparison", "DEM_difference.png")
        create_standard_map(
            diff, dem_data['NASADEM']['extent'],
            "DEM Difference (NASADEM - Copernicus)",
            output_path, cmap='RdBu_r', vmin=-15, vmax=15,
            units='Elevation Difference (m)', sites=sites
        )

        # Correlation plot
        fig, ax = plt.subplots(figsize=(8, 8))
        valid = ~(np.isnan(nasa) | np.isnan(cop))
        ax.scatter(cop[valid].flatten()[::10], nasa[valid].flatten()[::10],
                  alpha=0.3, s=1, c='blue')
        ax.plot([200, 310], [200, 310], 'r--', linewidth=2, label='1:1 line')

        # Regression
        from numpy.polynomial import polynomial as P
        coef = np.polyfit(cop[valid].flatten(), nasa[valid].flatten(), 1)
        ax.plot([200, 310], [coef[1] + coef[0]*200, coef[1] + coef[0]*310],
               'g-', linewidth=2, label=f'Fit: y={coef[0]:.3f}x+{coef[1]:.2f}')

        corr = np.corrcoef(cop[valid].flatten(), nasa[valid].flatten())[0,1]
        rmse = np.sqrt(np.mean((nasa[valid] - cop[valid])**2))

        ax.set_xlabel('Copernicus Elevation (m)')
        ax.set_ylabel('NASADEM Elevation (m)')
        ax.set_title(f'DEM Cross-Validation\nr = {corr:.4f}, RMSE = {rmse:.2f} m')
        ax.legend()
        ax.grid(True, alpha=0.3)
        ax.set_aspect('equal')

        output_path = os.path.join(dem_dir, "comparison", "DEM_correlation.png")
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        plt.close()
        print(f"  Saved: DEM_correlation.png")

    return dem_data


def process_terrain_variables(dem_data):
    """Generate maps for each terrain derivative."""
    print("\n" + "="*60)
    print("02. TERRAIN DERIVATIVES")
    print("="*60)

    sites = get_cicra_sites()
    terrain_dir = os.path.join(RESULTS_DIR, "02_terrain")

    # Use NASADEM as primary
    if 'NASADEM' not in dem_data:
        print("No DEM data available")
        return {}

    dem = dem_data['NASADEM']['data']
    extent = dem_data['NASADEM']['extent']
    cell_size = 30  # meters

    terrain_vars = {}

    from scipy import ndimage
    from scipy.ndimage import uniform_filter, maximum_filter, minimum_filter

    # 1. SLOPE
    print("\nComputing slope...")
    dz_dx = ndimage.sobel(dem, axis=1) / (8 * cell_size)
    dz_dy = ndimage.sobel(dem, axis=0) / (8 * cell_size)
    slope = np.degrees(np.arctan(np.sqrt(dz_dx**2 + dz_dy**2)))
    terrain_vars['slope'] = slope

    create_standard_map(
        slope, extent,
        "Slope (degrees)",
        os.path.join(terrain_dir, "slope", "slope.png"),
        cmap='YlOrRd', vmin=0, vmax=30,
        units='Slope (°)', sites=sites
    )

    # Slope classification
    slope_class = np.zeros_like(slope)
    slope_class[slope < 5] = 1    # Flat
    slope_class[(slope >= 5) & (slope < 15)] = 2  # Moderate
    slope_class[(slope >= 15) & (slope < 25)] = 3  # Steep
    slope_class[slope >= 25] = 4  # Very steep

    fig, ax = plt.subplots(figsize=(10, 8))
    cmap = plt.cm.colors.ListedColormap(['#2ecc71', '#f1c40f', '#e67e22', '#e74c3c'])
    im = ax.imshow(slope_class, extent=extent, cmap=cmap, vmin=0.5, vmax=4.5, aspect='auto')
    for site in sites:
        ax.plot(site.longitude, site.latitude, 'k^', markersize=10,
               markeredgecolor='white', markeredgewidth=1.5)
    patches = [mpatches.Patch(color='#2ecc71', label='Flat (<5°)'),
               mpatches.Patch(color='#f1c40f', label='Moderate (5-15°)'),
               mpatches.Patch(color='#e67e22', label='Steep (15-25°)'),
               mpatches.Patch(color='#e74c3c', label='Very steep (>25°)')]
    ax.legend(handles=patches, loc='upper right')
    ax.set_title('Slope Classification', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    plt.savefig(os.path.join(terrain_dir, "slope", "slope_classified.png"),
                dpi=150, bbox_inches='tight')
    plt.close()
    print("  Saved: slope_classified.png")

    # 2. TPI (multiple scales)
    print("\nComputing TPI at multiple scales...")
    scales = [3, 5, 7, 10, 15]
    tpi_results = {}

    for radius in scales:
        y, x = np.ogrid[-radius:radius+1, -radius:radius+1]
        kernel = (x**2 + y**2 <= radius**2).astype(float)
        kernel[radius, radius] = 0
        kernel = kernel / kernel.sum()

        mean_elev = ndimage.convolve(dem, kernel, mode='nearest')
        tpi = dem - mean_elev
        tpi_results[f'TPI_{radius}'] = tpi

        create_standard_map(
            tpi, extent,
            f"Topographic Position Index (r={radius} cells, ~{radius*30}m)",
            os.path.join(terrain_dir, "TPI", f"TPI_r{radius}.png"),
            cmap='RdBu_r', vmin=-10, vmax=10,
            units='TPI (m)', sites=sites
        )

    # TPI standard deviation across scales
    tpi_stack = np.array(list(tpi_results.values()))
    tpi_std = np.std(tpi_stack, axis=0)
    terrain_vars['TPI_std'] = tpi_std

    create_standard_map(
        tpi_std, extent,
        "Multi-scale TPI Variance",
        os.path.join(terrain_dir, "TPI", "TPI_multiscale_std.png"),
        cmap='magma', vmin=0, vmax=8,
        units='Std Dev (m)', sites=sites
    )

    # 3. CURVATURE
    print("\nComputing curvature...")
    # Profile curvature (in direction of slope)
    profile_curv = -ndimage.sobel(ndimage.sobel(dem, axis=0), axis=0) / (cell_size**2)
    terrain_vars['profile_curv'] = profile_curv

    create_standard_map(
        profile_curv, extent,
        "Profile Curvature",
        os.path.join(terrain_dir, "curvature", "profile_curvature.png"),
        cmap='RdBu_r', vmin=-0.01, vmax=0.01,
        units='Curvature (1/m)', sites=sites
    )

    # Plan curvature (across slope)
    plan_curv = -ndimage.sobel(ndimage.sobel(dem, axis=1), axis=1) / (cell_size**2)
    terrain_vars['plan_curv'] = plan_curv

    create_standard_map(
        plan_curv, extent,
        "Plan Curvature",
        os.path.join(terrain_dir, "curvature", "plan_curvature.png"),
        cmap='RdBu_r', vmin=-0.01, vmax=0.01,
        units='Curvature (1/m)', sites=sites
    )

    # 4. EDGE DETECTION
    print("\nComputing edge detection...")
    # Sobel edge magnitude
    edge_mag = np.sqrt(dz_dx**2 + dz_dy**2)
    terrain_vars['edge_magnitude'] = edge_mag

    create_standard_map(
        edge_mag, extent,
        "Edge Magnitude (Sobel)",
        os.path.join(terrain_dir, "edges", "edge_sobel.png"),
        cmap='hot', vmin=0, vmax=0.5,
        units='Gradient', sites=sites
    )

    # Directional edges
    directions = {
        'N-S': np.array([[1, 0, -1], [2, 0, -2], [1, 0, -1]]),
        'E-W': np.array([[1, 2, 1], [0, 0, 0], [-1, -2, -1]]),
        'NE-SW': np.array([[0, 1, 2], [-1, 0, 1], [-2, -1, 0]]),
        'NW-SE': np.array([[2, 1, 0], [1, 0, -1], [0, -1, -2]])
    }

    for name, kernel in directions.items():
        edge = np.abs(ndimage.convolve(dem, kernel / (8 * cell_size)))
        create_standard_map(
            edge, extent,
            f"Edge Detection ({name})",
            os.path.join(terrain_dir, "edges", f"edge_{name.replace('-','_')}.png"),
            cmap='hot', vmin=0, vmax=0.3,
            units='Edge strength', sites=sites
        )

    # 5. ROUGHNESS
    print("\nComputing terrain roughness...")
    # Local standard deviation
    mean_local = uniform_filter(dem, size=5)
    mean_sq = uniform_filter(dem**2, size=5)
    roughness = np.sqrt(np.maximum(mean_sq - mean_local**2, 0))
    terrain_vars['roughness'] = roughness

    create_standard_map(
        roughness, extent,
        "Terrain Roughness (local std dev)",
        os.path.join(terrain_dir, "roughness", "roughness_std.png"),
        cmap='viridis', vmin=0, vmax=10,
        units='Roughness (m)', sites=sites
    )

    # Terrain relief (max - min in window)
    max_local = maximum_filter(dem, size=5)
    min_local = minimum_filter(dem, size=5)
    relief = max_local - min_local
    terrain_vars['relief'] = relief

    create_standard_map(
        relief, extent,
        "Local Relief (max-min in 5x5 window)",
        os.path.join(terrain_dir, "roughness", "local_relief.png"),
        cmap='plasma', vmin=0, vmax=30,
        units='Relief (m)', sites=sites
    )

    return terrain_vars


def process_scarp_detection(dem_data, terrain_vars):
    """Generate maps for scarp detection methods."""
    print("\n" + "="*60)
    print("03. SCARP DETECTION")
    print("="*60)

    sites = get_cicra_sites()
    scarp_dir = os.path.join(RESULTS_DIR, "03_scarp_detection")
    extent = dem_data['NASADEM']['extent']

    # Basic slope threshold
    print("\nBasic slope threshold method...")
    slope = terrain_vars['slope']
    scarp_basic = (slope > 15).astype(float)

    create_standard_map(
        scarp_basic, extent,
        "Basic Scarp Detection (slope > 15°)",
        os.path.join(scarp_dir, "basic", "scarp_slope_threshold.png"),
        cmap='Reds', vmin=0, vmax=1,
        units='Detection', sites=sites
    )

    # Multiple thresholds
    for thresh in [10, 15, 20, 25]:
        scarp = (slope > thresh).astype(float)
        pct = 100 * np.sum(scarp) / scarp.size

        fig, ax = plt.subplots(figsize=(10, 8))
        ax.imshow(scarp, extent=extent, cmap='Reds', vmin=0, vmax=1, aspect='auto')
        for site in sites:
            ax.plot(site.longitude, site.latitude, 'b^', markersize=10)
        ax.set_title(f'Slope > {thresh}° ({pct:.1f}% of area)', fontweight='bold')
        ax.set_xlabel('Longitude')
        ax.set_ylabel('Latitude')
        plt.savefig(os.path.join(scarp_dir, "basic", f"scarp_threshold_{thresh}deg.png"),
                   dpi=150, bbox_inches='tight')
        plt.close()

    # Enhanced multi-scale
    print("\nEnhanced multi-scale method...")
    from scipy import ndimage

    def normalize(arr):
        vmin = np.nanpercentile(arr, 2)
        vmax = np.nanpercentile(arr, 98)
        return np.clip((arr - vmin) / (vmax - vmin + 1e-10), 0, 1)

    slope_norm = normalize(slope)
    tpi_grad = np.abs(ndimage.sobel(terrain_vars.get('TPI_std', slope)))
    tpi_norm = normalize(tpi_grad)
    edge_norm = normalize(terrain_vars['edge_magnitude'])
    rough_norm = normalize(terrain_vars['relief'])

    # Weighted composite
    weights = {'slope': 0.35, 'tpi': 0.25, 'edge': 0.25, 'rough': 0.15}

    composite = (weights['slope'] * slope_norm +
                weights['tpi'] * tpi_norm +
                weights['edge'] * edge_norm +
                weights['rough'] * rough_norm)

    create_standard_map(
        composite, extent,
        "Enhanced Scarp Probability (weighted composite)",
        os.path.join(scarp_dir, "enhanced", "scarp_probability.png"),
        cmap='hot_r', vmin=0, vmax=1,
        units='Probability', sites=sites
    )

    # Component breakdown
    components = {
        'slope': (slope_norm, weights['slope']),
        'tpi_gradient': (tpi_norm, weights['tpi']),
        'edge_magnitude': (edge_norm, weights['edge']),
        'terrain_relief': (rough_norm, weights['rough'])
    }

    fig, axes = plt.subplots(2, 2, figsize=(14, 12))
    for ax, (name, (data, weight)) in zip(axes.flat, components.items()):
        im = ax.imshow(data, extent=extent, cmap='YlOrRd', vmin=0, vmax=1, aspect='auto')
        for site in sites:
            ax.plot(site.longitude, site.latitude, 'k^', markersize=8)
        ax.set_title(f'{name.replace("_", " ").title()} (weight={weight})')
        ax.set_xlabel('Longitude')
        ax.set_ylabel('Latitude')
        plt.colorbar(im, ax=ax, shrink=0.6)

    plt.tight_layout()
    plt.savefig(os.path.join(scarp_dir, "enhanced", "component_breakdown.png"),
               dpi=150, bbox_inches='tight')
    plt.close()
    print("  Saved: component_breakdown.png")

    # Composite classification
    print("\nGenerating classification maps...")

    fig, ax = plt.subplots(figsize=(10, 8))

    # Three-class classification
    classification = np.zeros_like(composite)
    classification[composite < 0.4] = 1  # Low
    classification[(composite >= 0.4) & (composite < 0.6)] = 2  # Medium
    classification[composite >= 0.6] = 3  # High

    cmap = plt.cm.colors.ListedColormap(['#2ecc71', '#f39c12', '#e74c3c'])
    im = ax.imshow(classification, extent=extent, cmap=cmap, vmin=0.5, vmax=3.5, aspect='auto')

    for site in sites:
        ax.plot(site.longitude, site.latitude, 'k^', markersize=12,
               markeredgecolor='white', markeredgewidth=2)

    patches = [mpatches.Patch(color='#2ecc71', label='Low probability (<0.4)'),
               mpatches.Patch(color='#f39c12', label='Medium probability (0.4-0.6)'),
               mpatches.Patch(color='#e74c3c', label='High probability (>0.6)')]
    ax.legend(handles=patches, loc='upper right', fontsize=9)

    low_pct = 100 * np.sum(classification == 1) / classification.size
    med_pct = 100 * np.sum(classification == 2) / classification.size
    high_pct = 100 * np.sum(classification == 3) / classification.size

    ax.set_title(f'Scarp Probability Classification\nHigh: {high_pct:.1f}%, Medium: {med_pct:.1f}%, Low: {low_pct:.1f}%',
                fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    plt.savefig(os.path.join(scarp_dir, "composite", "scarp_classification.png"),
               dpi=150, bbox_inches='tight')
    plt.close()
    print("  Saved: scarp_classification.png")

    return composite


def process_gedi_data():
    """Generate maps for GEDI validation data."""
    print("\n" + "="*60)
    print("04. GEDI VALIDATION")
    print("="*60)

    gedi_results_dir = os.path.join(RESULTS_DIR, "04_GEDI")

    # Load synthetic GEDI data
    gedi_csv = os.path.join(GEDI_DIR, "synthetic_gedi_footprints.csv")
    site_csv = os.path.join(GEDI_DIR, "site_transects.csv")

    if not os.path.exists(gedi_csv):
        print("No GEDI data found")
        return

    gedi_df = pd.read_csv(gedi_csv)
    site_df = pd.read_csv(site_csv)

    # Footprint map
    print("\nGenerating footprint maps...")

    fig, ax = plt.subplots(figsize=(10, 8))
    scatter = ax.scatter(gedi_df['longitude'], gedi_df['latitude'],
                        c=gedi_df['elev_lowestmode'], cmap='terrain',
                        s=5, alpha=0.6)
    plt.colorbar(scatter, ax=ax, label='Ground Elevation (m)', shrink=0.8)

    sites = get_cicra_sites()
    for site in sites:
        ax.plot(site.longitude, site.latitude, 'r^', markersize=12,
               markeredgecolor='white', markeredgewidth=2)

    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    ax.set_title('GEDI Footprint Ground Elevations', fontweight='bold')

    plt.savefig(os.path.join(gedi_results_dir, "footprints", "gedi_elevation.png"),
               dpi=150, bbox_inches='tight')
    plt.close()
    print("  Saved: gedi_elevation.png")

    # By transect
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))

    for i, (ax, tid) in enumerate(zip(axes.flat, range(4))):
        transect_data = gedi_df[gedi_df['transect_id'] == tid]
        ax.scatter(transect_data['latitude'], transect_data['elev_lowestmode'],
                  c=transect_data['rh100'], cmap='Greens', s=10, alpha=0.7)
        ax.set_xlabel('Latitude')
        ax.set_ylabel('Ground Elevation (m)')
        ax.set_title(f'Transect {tid+1} (n={len(transect_data)})')
        ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(os.path.join(gedi_results_dir, "transects", "transect_profiles.png"),
               dpi=150, bbox_inches='tight')
    plt.close()
    print("  Saved: transect_profiles.png")

    # Site transects
    fig, axes = plt.subplots(3, 1, figsize=(12, 10), sharex=False)
    colors = ['#e41a1c', '#377eb8', '#4daf4a']

    for i, site_name in enumerate(site_df['site'].unique()):
        ax = axes[i]
        site_data = site_df[site_df['site'] == site_name].sort_values('distance_m')

        ax.fill_between(site_data['distance_m'], site_data['elev_dem'].min() - 5,
                       site_data['elev_dem'], alpha=0.3, color=colors[i])
        ax.plot(site_data['distance_m'], site_data['elev_dem'],
               color=colors[i], linewidth=2)

        ax.axvline(0, color='black', linestyle='--', alpha=0.5, label='Sampling site')

        elev_range = site_data['elev_dem'].max() - site_data['elev_dem'].min()
        ax.set_ylabel('Elevation (m)')
        ax.set_title(f'{site_name.replace("_", " ")} - Relief: {elev_range:.0f} m')
        ax.grid(True, alpha=0.3)
        ax.legend(loc='upper right')

    axes[-1].set_xlabel('Distance from sampling site (m)')
    plt.tight_layout()
    plt.savefig(os.path.join(gedi_results_dir, "validation", "site_elevation_profiles.png"),
               dpi=150, bbox_inches='tight')
    plt.close()
    print("  Saved: site_elevation_profiles.png")


def save_results_tracking():
    """Save results tracking to CSV."""
    print("\n" + "="*60)
    print("SAVING RESULTS TRACKING")
    print("="*60)

    if RESULTS_TRACKING:
        df = pd.DataFrame(RESULTS_TRACKING)
        output_path = os.path.join(RESULTS_DIR, "results_tracking.csv")
        df.to_csv(output_path, index=False)
        print(f"Saved: {output_path}")
        print(f"  {len(df)} variables tracked")

        # Summary
        print("\nVariable Summary:")
        print(df[['variable', 'min', 'max', 'mean', 'std']].to_string(index=False))


def main():
    print("="*60)
    print("SYSTEMATIC MAPPING AND RESULTS TRACKING")
    print("="*60)
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"Results directory: {RESULTS_DIR}")

    # Process each data product
    dem_data = process_dem_products()

    if dem_data:
        terrain_vars = process_terrain_variables(dem_data)

        if terrain_vars:
            process_scarp_detection(dem_data, terrain_vars)

    process_gedi_data()

    # Save tracking
    save_results_tracking()

    print("\n" + "="*60)
    print("SYSTEMATIC MAPPING COMPLETE")
    print("="*60)

    # Count outputs
    png_count = sum(len(files) for _, _, files in os.walk(RESULTS_DIR) if files)
    print(f"\nTotal figures generated: {png_count}")


if __name__ == "__main__":
    main()
