#!/usr/bin/env python3
"""
Generate systematic tracking maps for all data products and variables.
Creates organized output maps in the outputs/maps/ directory structure.

Each map includes:
- Consistent styling and extent
- Sampling location overlays
- Scale bar and north arrow indicators
- Status metadata in filename

Directory structure:
outputs/maps/
├── dem/           - DEM products and comparisons
├── terrain/       - Terrain derivatives (slope, aspect, TPI, etc.)
├── scarp/         - Scarp detection probability maps
├── gedi/          - GEDI lidar products
├── emit/          - EMIT hyperspectral products
├── sentinel/      - Sentinel-2 spectral indices
├── validation/    - Cross-validation maps
└── comparison/    - Product comparison maps
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Patch
import matplotlib.patheffects as pe

# Add parent directory for config
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import (
    PROJECT_ROOT, OUTPUT_DIR, GEOTIFF_DIR, FIGURE_DIR,
    SAMPLING_LOCATIONS, CICRA_BBOX, VIZ_PARAMS
)

try:
    import rasterio
    from rasterio.plot import show
    HAS_RASTERIO = True
except ImportError:
    HAS_RASTERIO = False
    print("Warning: rasterio not available, some functions limited")

# Output directories
MAP_DIR = os.path.join(OUTPUT_DIR, "maps")
MAP_SUBDIRS = ["dem", "terrain", "scarp", "gedi", "emit", "sentinel", "validation", "comparison"]

# Ensure directories exist
for subdir in MAP_SUBDIRS:
    os.makedirs(os.path.join(MAP_DIR, subdir), exist_ok=True)

# Tracking log
TRACKING_LOG = []


def log_map_generation(category, name, filepath, status="success", notes=""):
    """Log map generation for tracking"""
    entry = {
        "timestamp": datetime.now().isoformat(),
        "category": category,
        "name": name,
        "filepath": filepath,
        "status": status,
        "notes": notes
    }
    TRACKING_LOG.append(entry)
    return entry


def add_sampling_locations(ax, transform=None, marker_size=80):
    """Add sampling location markers to a map"""
    for loc in SAMPLING_LOCATIONS:
        # Check if within CICRA bbox
        if (CICRA_BBOX["west"] <= loc.longitude <= CICRA_BBOX["east"] and
            CICRA_BBOX["south"] <= loc.latitude <= CICRA_BBOX["north"]):
            ax.scatter(loc.longitude, loc.latitude,
                      c='yellow', s=marker_size, marker='*',
                      edgecolors='black', linewidths=0.5, zorder=10)
            ax.annotate(loc.name.split('_')[0],
                       (loc.longitude, loc.latitude),
                       xytext=(5, 5), textcoords='offset points',
                       fontsize=6, color='white',
                       path_effects=[pe.withStroke(linewidth=2, foreground='black')])


def add_map_elements(ax, title, add_colorbar=True, cbar_label=""):
    """Add standard map elements"""
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    ax.set_title(title, fontsize=10, fontweight='bold')

    # Add scale indicator (approximate)
    ax.text(0.02, 0.02, '~1 km', transform=ax.transAxes,
            fontsize=8, verticalalignment='bottom',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    # Add north arrow
    ax.annotate('N', xy=(0.95, 0.95), xycoords='axes fraction',
                fontsize=10, ha='center', va='center',
                bbox=dict(boxstyle='circle', facecolor='white', edgecolor='black'))
    ax.annotate('', xy=(0.95, 0.98), xycoords='axes fraction',
                xytext=(0.95, 0.92), textcoords='axes fraction',
                arrowprops=dict(arrowstyle='->', color='black', lw=1.5))


def generate_raster_map(raster_path, output_path, title, cmap='viridis',
                        vmin=None, vmax=None, category="terrain"):
    """Generate a map from a raster file"""
    if not HAS_RASTERIO:
        log_map_generation(category, title, output_path, "skipped", "rasterio not available")
        return False

    if not os.path.exists(raster_path):
        log_map_generation(category, title, output_path, "skipped", f"Input not found: {raster_path}")
        return False

    try:
        with rasterio.open(raster_path) as src:
            data = src.read(1)
            extent = [src.bounds.left, src.bounds.right,
                     src.bounds.bottom, src.bounds.top]

            # Handle nodata
            if src.nodata is not None:
                data = np.ma.masked_equal(data, src.nodata)

            # Create figure
            fig, ax = plt.subplots(figsize=(10, 8), dpi=VIZ_PARAMS.get('figure_dpi', 300))

            im = ax.imshow(data, extent=extent, cmap=cmap, vmin=vmin, vmax=vmax,
                          origin='upper', aspect='equal')

            add_sampling_locations(ax)
            add_map_elements(ax, title)

            # Colorbar
            cbar = plt.colorbar(im, ax=ax, shrink=0.7, pad=0.02)
            cbar.ax.tick_params(labelsize=8)

            plt.tight_layout()
            plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
            plt.close()

            log_map_generation(category, title, output_path, "success")
            print(f"  Generated: {os.path.basename(output_path)}")
            return True

    except Exception as e:
        log_map_generation(category, title, output_path, "error", str(e))
        print(f"  Error generating {title}: {e}")
        return False


def generate_dem_maps():
    """Generate all DEM-related maps"""
    print("\n=== Generating DEM Maps ===")

    dem_files = {
        "copernicus": os.path.join(PROJECT_ROOT, "data/dem/copernicus_cicra_30m.tif"),
        "nasadem": os.path.join(PROJECT_ROOT, "data/dem/nasadem_cicra_30m.tif"),
    }

    for name, path in dem_files.items():
        output = os.path.join(MAP_DIR, "dem", f"Map_DEM_{name}.png")
        generate_raster_map(path, output, f"DEM: {name.upper()}",
                           cmap='terrain', category="dem")


def generate_terrain_maps():
    """Generate all terrain derivative maps"""
    print("\n=== Generating Terrain Maps ===")

    terrain_products = {
        "slope": ("Slope (degrees)", "YlOrRd", 0, 35),
        "aspect": ("Aspect (degrees)", "hsv", 0, 360),
        "hillshade": ("Hillshade", "gray", 0, 255),
        "tpi": ("Topographic Position Index", "RdBu_r", -10, 10),
        "tri": ("Terrain Ruggedness Index", "YlOrBr", None, None),
        "profile_curvature": ("Profile Curvature", "RdBu_r", -0.05, 0.05),
        "plan_curvature": ("Plan Curvature", "RdBu_r", -0.05, 0.05),
        "landform": ("Landform Classification", "tab10", None, None),
    }

    for product, (title, cmap, vmin, vmax) in terrain_products.items():
        # Try both naming conventions
        for prefix in ["copernicus_cicra_30m_", "enhanced_cicra_"]:
            input_path = os.path.join(GEOTIFF_DIR, f"{prefix}{product}.tif")
            if os.path.exists(input_path):
                output = os.path.join(MAP_DIR, "terrain", f"Map_terrain_{product}.png")
                generate_raster_map(input_path, output, title, cmap, vmin, vmax, "terrain")
                break

    # Enhanced terrain products
    enhanced_products = {
        "slope_enhanced": ("Enhanced Slope", "YlOrRd", None, None),
        "tpi_multiscale": ("Multi-scale TPI", "RdBu_r", -5, 5),
        "tpi_variance": ("TPI Variance", "YlOrBr", None, None),
        "edge_magnitude": ("Edge Magnitude", "magma", None, None),
        "terrain_range": ("Terrain Range", "viridis", None, None),
        "hillshade_multidirectional": ("Multi-directional Hillshade", "gray", None, None),
    }

    for product, (title, cmap, vmin, vmax) in enhanced_products.items():
        input_path = os.path.join(GEOTIFF_DIR, f"enhanced_cicra_{product}.tif")
        if os.path.exists(input_path):
            output = os.path.join(MAP_DIR, "terrain", f"Map_terrain_{product}_enhanced.png")
            generate_raster_map(input_path, output, title, cmap, vmin, vmax, "terrain")


def generate_scarp_maps():
    """Generate scarp detection maps"""
    print("\n=== Generating Scarp Detection Maps ===")

    # Custom colormap for probability
    prob_colors = ['#2166ac', '#67a9cf', '#d1e5f0', '#fddbc7', '#ef8a62', '#b2182b']
    prob_cmap = LinearSegmentedColormap.from_list('scarp_prob', prob_colors)

    scarp_products = {
        "scarp_probability": ("Scarp Probability (Basic)", prob_cmap, 0, 1),
        "scarp_probability_enhanced": ("Scarp Probability (Enhanced)", prob_cmap, 0, 1),
    }

    for product, (title, cmap, vmin, vmax) in scarp_products.items():
        for prefix in ["copernicus_cicra_30m_", "enhanced_cicra_"]:
            input_path = os.path.join(GEOTIFF_DIR, f"{prefix}{product}.tif")
            if os.path.exists(input_path):
                output = os.path.join(MAP_DIR, "scarp", f"Map_{product}.png")
                generate_raster_map(input_path, output, title, cmap, vmin, vmax, "scarp")
                break


def generate_comparison_maps():
    """Generate data product comparison maps"""
    print("\n=== Generating Comparison Maps ===")

    if not HAS_RASTERIO:
        print("  Skipped: rasterio not available")
        return

    # DEM comparison
    cop_path = os.path.join(PROJECT_ROOT, "data/dem/copernicus_cicra_30m.tif")
    nasa_path = os.path.join(PROJECT_ROOT, "data/dem/nasadem_cicra_30m.tif")

    if os.path.exists(cop_path) and os.path.exists(nasa_path):
        try:
            with rasterio.open(cop_path) as cop, rasterio.open(nasa_path) as nasa:
                cop_data = cop.read(1)
                nasa_data = nasa.read(1)

                # Resample if needed (simple case: same extent)
                if cop_data.shape == nasa_data.shape:
                    diff = cop_data - nasa_data

                    fig, axes = plt.subplots(1, 3, figsize=(15, 5), dpi=300)

                    extent = [cop.bounds.left, cop.bounds.right,
                             cop.bounds.bottom, cop.bounds.top]

                    # Copernicus
                    im0 = axes[0].imshow(cop_data, extent=extent, cmap='terrain')
                    axes[0].set_title('Copernicus DEM')
                    plt.colorbar(im0, ax=axes[0], shrink=0.5)

                    # NASADEM
                    im1 = axes[1].imshow(nasa_data, extent=extent, cmap='terrain')
                    axes[1].set_title('NASADEM')
                    plt.colorbar(im1, ax=axes[1], shrink=0.5)

                    # Difference
                    im2 = axes[2].imshow(diff, extent=extent, cmap='RdBu_r',
                                        vmin=-5, vmax=5)
                    axes[2].set_title('Difference (Cop - NASA)')
                    plt.colorbar(im2, ax=axes[2], shrink=0.5, label='meters')

                    for ax in axes:
                        add_sampling_locations(ax)

                    plt.tight_layout()
                    output = os.path.join(MAP_DIR, "comparison", "Map_DEM_comparison.png")
                    plt.savefig(output, dpi=300, bbox_inches='tight', facecolor='white')
                    plt.close()

                    log_map_generation("comparison", "DEM Comparison", output)
                    print(f"  Generated: Map_DEM_comparison.png")

        except Exception as e:
            print(f"  Error in DEM comparison: {e}")


def generate_status_summary():
    """Generate a visual status summary of all data products"""
    print("\n=== Generating Status Summary ===")

    categories = {
        'DEM Products': ['NASADEM', 'Copernicus', 'SRTM'],
        'Terrain Derivatives': ['Slope', 'Aspect', 'TPI', 'Curvature', 'Hillshade', 'Landforms'],
        'Scarp Detection': ['Basic Probability', 'Enhanced Probability', 'Centerlines', 'Polygons'],
        'GEDI Products': ['L4A Download', 'Footprint Extract', 'Quality Filter', 'AGB Map'],
        'EMIT Products': ['L2A Download', 'Quality Mask', 'Spectral Extract', 'Index Maps'],
        'Sentinel-2': ['Scene Selection', 'NDVI', 'NDWI', 'NBR', 'SOCI', 'BSI'],
    }

    # Status data (would be read from tracking file in production)
    status = {
        'DEM Products': [2, 2, 1],  # 0=pending, 1=partial, 2=complete
        'Terrain Derivatives': [2, 2, 2, 2, 2, 2],
        'Scarp Detection': [2, 2, 0, 0],
        'GEDI Products': [1, 0, 0, 0],
        'EMIT Products': [1, 1, 0, 0],
        'Sentinel-2': [0, 0, 0, 0, 0, 0],
    }

    colors = {0: '#ff6b6b', 1: '#ffd93d', 2: '#6bcb77'}  # red, yellow, green

    fig, ax = plt.subplots(figsize=(12, 8), dpi=300)

    y_pos = 0
    for cat, items in categories.items():
        ax.text(-0.5, y_pos + len(items)/2, cat, fontsize=10, fontweight='bold',
               ha='right', va='center')

        for i, item in enumerate(items):
            stat = status[cat][i] if i < len(status[cat]) else 0
            color = colors[stat]
            ax.barh(y_pos, 1, color=color, edgecolor='black', linewidth=0.5)
            ax.text(0.5, y_pos, item, ha='center', va='center', fontsize=8)
            y_pos += 1
        y_pos += 0.5

    # Legend
    legend_elements = [
        Patch(facecolor='#6bcb77', edgecolor='black', label='Complete'),
        Patch(facecolor='#ffd93d', edgecolor='black', label='In Progress'),
        Patch(facecolor='#ff6b6b', edgecolor='black', label='Pending'),
    ]
    ax.legend(handles=legend_elements, loc='upper right')

    ax.set_xlim(-3, 2)
    ax.set_ylim(-1, y_pos)
    ax.axis('off')
    ax.set_title('Data Product Processing Status', fontsize=14, fontweight='bold', pad=20)

    plt.tight_layout()
    output = os.path.join(MAP_DIR, "Map_processing_status.png")
    plt.savefig(output, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()

    log_map_generation("summary", "Processing Status", output)
    print(f"  Generated: Map_processing_status.png")


def save_tracking_log():
    """Save tracking log to JSON"""
    log_path = os.path.join(OUTPUT_DIR, "map_generation_log.json")
    with open(log_path, 'w') as f:
        json.dump({
            "generated": datetime.now().isoformat(),
            "total_maps": len(TRACKING_LOG),
            "successful": sum(1 for e in TRACKING_LOG if e['status'] == 'success'),
            "entries": TRACKING_LOG
        }, f, indent=2)
    print(f"\nTracking log saved to: {log_path}")


def main():
    """Generate all tracking maps"""
    print("=" * 60)
    print("SYSTEMATIC MAP GENERATION")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    generate_dem_maps()
    generate_terrain_maps()
    generate_scarp_maps()
    generate_comparison_maps()
    generate_status_summary()

    save_tracking_log()

    print("\n" + "=" * 60)
    print(f"COMPLETE: Generated {sum(1 for e in TRACKING_LOG if e['status'] == 'success')} maps")
    print(f"Outputs in: {MAP_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
