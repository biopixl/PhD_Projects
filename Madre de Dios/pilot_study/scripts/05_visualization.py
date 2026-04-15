"""
Visualization and Analysis Outputs for CICRA Study
Madre de Dios, Peru

This script creates publication-quality figures showing:
1. Study area overview with sampling locations
2. Terrain derivatives and scarp detection
3. Spectral indices for organic matter
4. Integration of all data layers

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
from pathlib import Path
from typing import List, Optional

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    GEOTIFF_DIR, FIGURE_DIR, VECTOR_DIR,
    CICRA_BBOX, EXTENDED_BBOX, SAMPLING_LOCATIONS, CICRA_CENTER,
    VIZ_PARAMS, SLOPE_PARAMS, TPI_PARAMS
)

try:
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from matplotlib.colors import LinearSegmentedColormap, Normalize
    from matplotlib.lines import Line2D
    from mpl_toolkits.axes_grid1 import make_axes_locatable
except ImportError:
    plt = None
    print("matplotlib not installed. Install with: pip install matplotlib")

try:
    import rasterio
    from rasterio.plot import show
except ImportError:
    rasterio = None

try:
    import contextily as ctx
except ImportError:
    ctx = None
    print("contextily not installed (optional for basemaps). Install with: pip install contextily")


# =============================================================================
# CUSTOM COLORMAPS
# =============================================================================

def create_terrain_cmap():
    """Create terrain colormap for elevation."""
    colors = [
        (0.0, '#2E7D32'),   # Low - dark green (floodplain)
        (0.2, '#66BB6A'),   # Low-mid - light green
        (0.4, '#FDD835'),   # Mid - yellow
        (0.6, '#F57C00'),   # Mid-high - orange
        (0.8, '#BF360C'),   # High - dark orange
        (1.0, '#5D4037'),   # Highest - brown
    ]
    return LinearSegmentedColormap.from_list('terrain_custom', colors)


def create_tpi_cmap():
    """Create TPI colormap (blue-white-red diverging)."""
    colors = [
        (0.0, '#1565C0'),   # Strong negative - blue (valleys)
        (0.25, '#64B5F6'),  # Weak negative - light blue
        (0.5, '#FFFFFF'),   # Zero - white (slopes)
        (0.75, '#EF9A9A'), # Weak positive - light red
        (1.0, '#B71C1C'),   # Strong positive - red (terraces)
    ]
    return LinearSegmentedColormap.from_list('tpi_custom', colors)


def create_scarp_cmap():
    """Create scarp probability colormap."""
    colors = [
        (0.0, '#FFFFFF00'),  # Zero - transparent
        (0.3, '#FFEB3B'),    # Low - yellow
        (0.5, '#FF9800'),    # Medium - orange
        (0.7, '#F44336'),    # High - red
        (1.0, '#B71C1C'),    # Very high - dark red
    ]
    return LinearSegmentedColormap.from_list('scarp_custom', colors)


# =============================================================================
# FIGURE 1: STUDY AREA OVERVIEW
# =============================================================================

def plot_study_area(dem_path: str = None, output_path: str = None):
    """
    Create study area overview map with sampling locations.

    Parameters:
    -----------
    dem_path : str
        Path to DEM (optional, for hillshade background)
    output_path : str
        Output figure path
    """
    if plt is None:
        print("matplotlib required for visualization")
        return

    fig, ax = plt.subplots(figsize=(12, 10))

    # Plot DEM hillshade if available
    if dem_path and rasterio and os.path.exists(dem_path):
        with rasterio.open(dem_path) as src:
            hillshade = src.read(1)
            extent = [src.bounds.left, src.bounds.right,
                      src.bounds.bottom, src.bounds.top]

        ax.imshow(hillshade, cmap='gray', extent=extent, alpha=0.7)

    # Add basemap if contextily available
    elif ctx:
        try:
            ctx.add_basemap(ax, crs='EPSG:4326', source=ctx.providers.Esri.WorldImagery)
        except:
            pass

    # Filter to only CICRA sites (exclude Puerto Maldonado)
    cicra_sites = [loc for loc in SAMPLING_LOCATIONS if 'PM' not in loc.name]

    # Plot sampling locations
    for loc in cicra_sites:
        ax.scatter(loc.longitude, loc.latitude,
                   c='red', marker='o',
                   s=120, edgecolors='white', linewidth=1.5, zorder=10)
        # Clean up label
        label = loc.name.replace('COLUMNA_', 'Col ').replace('_CICRA', '').replace('_LOS_AMIGOS', '\n(Los Amigos)')
        ax.annotate(label,
                    (loc.longitude, loc.latitude),
                    xytext=(8, 5), textcoords='offset points',
                    fontsize=9, fontweight='bold',
                    bbox=dict(boxstyle='round,pad=0.3', facecolor='white', alpha=0.8))

    # CICRA center marker
    ax.scatter(*CICRA_CENTER, c='blue', marker='*', s=250,
               edgecolors='white', linewidth=1.5, zorder=11)

    # Legend
    legend_elements = [
        Line2D([0], [0], marker='o', color='w', markerfacecolor='red',
               markersize=10, label='Sampling Columns'),
        Line2D([0], [0], marker='*', color='w', markerfacecolor='blue',
               markersize=15, label='CICRA Station'),
    ]
    ax.legend(handles=legend_elements, loc='upper right')

    # Labels
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    ax.set_title('CICRA Flood-Buried Forest Study Area\nMadre de Dios, Peru',
                 fontsize=14, fontweight='bold')

    # Set extent to CICRA area
    ax.set_xlim(CICRA_BBOX["west"] - 0.01, CICRA_BBOX["east"] + 0.01)
    ax.set_ylim(CICRA_BBOX["south"] - 0.01, CICRA_BBOX["north"] + 0.01)

    plt.tight_layout()

    if output_path is None:
        output_path = os.path.join(FIGURE_DIR, "Fig1_study_area.png")

    plt.savefig(output_path, dpi=VIZ_PARAMS["figure_dpi"], bbox_inches='tight')
    print(f"Saved: {output_path}")

    plt.close()
    return output_path


# =============================================================================
# FIGURE 2: TERRAIN DERIVATIVES
# =============================================================================

def plot_terrain_derivatives(dem_path: str, slope_path: str, tpi_path: str,
                            hillshade_path: str = None,
                            output_path: str = None):
    """
    Create multi-panel figure of terrain derivatives.

    Parameters:
    -----------
    dem_path : str
        Path to DEM
    slope_path : str
        Path to slope raster
    tpi_path : str
        Path to TPI raster
    hillshade_path : str
        Path to hillshade raster (optional)
    output_path : str
        Output figure path
    """
    if plt is None or rasterio is None:
        print("matplotlib and rasterio required")
        return

    fig, axes = plt.subplots(2, 2, figsize=(12, 10))

    # Panel A: DEM/Hillshade
    ax = axes[0, 0]
    with rasterio.open(dem_path) as src:
        dem = src.read(1)
        extent = [src.bounds.left, src.bounds.right,
                  src.bounds.bottom, src.bounds.top]
        dem = np.where(dem == src.nodata, np.nan, dem)

    im = ax.imshow(dem, cmap=create_terrain_cmap(), extent=extent, aspect='auto')
    add_colorbar(ax, im, 'Elevation (m)')
    ax.set_title('A) Digital Elevation Model', fontweight='bold')
    plot_sampling_locations(ax)

    # Panel B: Hillshade (if available) or Slope
    ax = axes[0, 1]
    if hillshade_path and os.path.exists(hillshade_path):
        with rasterio.open(hillshade_path) as src:
            hillshade = src.read(1)
        ax.imshow(hillshade, cmap='gray', extent=extent, aspect='auto')
        ax.set_title('B) Hillshade', fontweight='bold')
    else:
        with rasterio.open(slope_path) as src:
            slope = src.read(1)
            slope = np.where(slope == src.nodata, np.nan, slope)
        im = ax.imshow(slope, cmap='YlOrRd', extent=extent, vmin=0, vmax=45, aspect='auto')
        add_colorbar(ax, im, 'Slope (degrees)')
        ax.set_title('B) Slope', fontweight='bold')
    plot_sampling_locations(ax)

    # Panel C: Slope
    ax = axes[1, 0]
    with rasterio.open(slope_path) as src:
        slope = src.read(1)
        slope = np.where(slope == src.nodata, np.nan, slope)

    im = ax.imshow(slope, cmap='YlOrRd', extent=extent, vmin=0, vmax=45, aspect='auto')
    add_colorbar(ax, im, 'Slope (degrees)')

    # Add scarp threshold contour (use X, Y coordinates for proper alignment)
    y = np.linspace(extent[3], extent[2], slope.shape[0])
    x = np.linspace(extent[0], extent[1], slope.shape[1])
    X, Y = np.meshgrid(x, y)
    ax.contour(X, Y, slope, levels=[SLOPE_PARAMS["scarp_min_degrees"]],
               colors='red', linewidths=0.5)
    ax.set_title(f'C) Slope with Scarp Threshold ({SLOPE_PARAMS["scarp_min_degrees"]}°)',
                 fontweight='bold')
    plot_sampling_locations(ax)

    # Panel D: TPI
    ax = axes[1, 1]
    with rasterio.open(tpi_path) as src:
        tpi = src.read(1)
        tpi = np.where(tpi == src.nodata, np.nan, tpi)

    # Symmetric colorbar around zero
    vmax = np.nanpercentile(np.abs(tpi), 95)
    im = ax.imshow(tpi, cmap=create_tpi_cmap(), extent=extent,
                   vmin=-vmax, vmax=vmax, aspect='auto')
    add_colorbar(ax, im, 'TPI (m)')
    ax.set_title('D) Topographic Position Index', fontweight='bold')
    plot_sampling_locations(ax)

    # Common formatting
    for ax in axes.flat:
        ax.set_xlabel('Longitude')
        ax.set_ylabel('Latitude')

    plt.suptitle('Terrain Analysis for Terrace Scarp Detection',
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()

    if output_path is None:
        output_path = os.path.join(FIGURE_DIR, "Fig2_terrain_derivatives.png")

    plt.savefig(output_path, dpi=VIZ_PARAMS["figure_dpi"], bbox_inches='tight')
    print(f"Saved: {output_path}")

    plt.close()
    return output_path


# =============================================================================
# FIGURE 3: SCARP DETECTION RESULTS
# =============================================================================

def plot_scarp_detection(dem_path: str, scarp_prob_path: str,
                         hillshade_path: str = None,
                         output_path: str = None):
    """
    Create scarp detection results figure.

    Parameters:
    -----------
    dem_path : str
        Path to DEM
    scarp_prob_path : str
        Path to scarp probability raster
    hillshade_path : str
        Path to hillshade raster (optional background)
    output_path : str
        Output figure path
    """
    if plt is None or rasterio is None:
        return

    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    # Get extent from DEM
    with rasterio.open(dem_path) as src:
        extent = [src.bounds.left, src.bounds.right,
                  src.bounds.bottom, src.bounds.top]

    # Panel A: Hillshade with scarp overlay
    ax = axes[0]
    if hillshade_path and os.path.exists(hillshade_path):
        with rasterio.open(hillshade_path) as src:
            hillshade = src.read(1)
        ax.imshow(hillshade, cmap='gray', extent=extent, aspect='auto')
    else:
        with rasterio.open(dem_path) as src:
            dem = src.read(1)
            dem = np.where(dem == src.nodata, np.nan, dem)
        ax.imshow(dem, cmap='terrain', extent=extent, aspect='auto')

    # Overlay scarp probability
    with rasterio.open(scarp_prob_path) as src:
        scarp_prob = src.read(1)
        scarp_prob = np.where(scarp_prob == src.nodata, np.nan, scarp_prob)

    # Only show high probability scarps
    scarp_masked = np.ma.masked_where(scarp_prob < 0.4, scarp_prob)
    ax.imshow(scarp_masked, cmap=create_scarp_cmap(), extent=extent,
              alpha=0.8, vmin=0, vmax=1, aspect='auto')

    plot_sampling_locations(ax)
    ax.set_title('A) Detected Terrace Scarps', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    # Panel B: Scarp probability map
    ax = axes[1]
    im = ax.imshow(scarp_prob, cmap='YlOrRd', extent=extent, vmin=0, vmax=1, aspect='auto')
    add_colorbar(ax, im, 'Scarp Probability')

    # Add threshold contour with proper coordinates
    y = np.linspace(extent[3], extent[2], scarp_prob.shape[0])
    x = np.linspace(extent[0], extent[1], scarp_prob.shape[1])
    X, Y = np.meshgrid(x, y)
    ax.contour(X, Y, scarp_prob, levels=[0.4, 0.6, 0.8],
               colors=['yellow', 'orange', 'red'],
               linewidths=[0.5, 1, 1.5])

    plot_sampling_locations(ax)
    ax.set_title('B) Scarp Probability Map', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    # Legend for thresholds
    legend_elements = [
        Line2D([0], [0], color='yellow', linewidth=1, label='P > 0.4'),
        Line2D([0], [0], color='orange', linewidth=1.5, label='P > 0.6'),
        Line2D([0], [0], color='red', linewidth=2, label='P > 0.8'),
    ]
    ax.legend(handles=legend_elements, loc='lower right', title='Thresholds')

    plt.suptitle('Terrace Scarp Detection Results',
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()

    if output_path is None:
        output_path = os.path.join(FIGURE_DIR, "Fig3_scarp_detection.png")

    plt.savefig(output_path, dpi=VIZ_PARAMS["figure_dpi"], bbox_inches='tight')
    print(f"Saved: {output_path}")

    plt.close()
    return output_path


# =============================================================================
# FIGURE 4: SPECTRAL INDICES
# =============================================================================

def plot_spectral_indices(ndvi_path: str, bsi_path: str, soci_path: str,
                          output_path: str = None):
    """
    Create spectral indices figure.

    Parameters:
    -----------
    ndvi_path : str
        Path to NDVI raster
    bsi_path : str
        Path to BSI raster
    soci_path : str
        Path to SOCI raster
    output_path : str
        Output figure path
    """
    if plt is None or rasterio is None:
        return

    fig, axes = plt.subplots(1, 3, figsize=(15, 5))

    # NDVI
    ax = axes[0]
    with rasterio.open(ndvi_path) as src:
        ndvi = src.read(1)
        extent = [src.bounds.left, src.bounds.right,
                  src.bounds.bottom, src.bounds.top]

    im = ax.imshow(ndvi, cmap='RdYlGn', extent=extent, vmin=-0.5, vmax=1)
    add_colorbar(ax, im, 'NDVI')
    ax.set_title('A) Vegetation Index (NDVI)', fontweight='bold')
    plot_sampling_locations(ax)

    # BSI
    ax = axes[1]
    with rasterio.open(bsi_path) as src:
        bsi = src.read(1)

    im = ax.imshow(bsi, cmap='RdYlBu_r', extent=extent, vmin=-0.5, vmax=0.5)
    add_colorbar(ax, im, 'BSI')
    ax.set_title('B) Bare Soil Index (BSI)', fontweight='bold')
    plot_sampling_locations(ax)

    # SOCI
    ax = axes[2]
    with rasterio.open(soci_path) as src:
        soci = src.read(1)

    im = ax.imshow(soci, cmap='YlOrBr', extent=extent, vmin=-0.2, vmax=0.2)
    add_colorbar(ax, im, 'SOCI')
    ax.set_title('C) Soil Organic Carbon Index', fontweight='bold')
    plot_sampling_locations(ax)

    # Common formatting
    for ax in axes:
        ax.set_xlabel('Longitude')
        ax.set_ylabel('Latitude')

    plt.suptitle('Sentinel-2 Spectral Indices for Organic Matter Detection',
                 fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()

    if output_path is None:
        output_path = os.path.join(FIGURE_DIR, "Fig4_spectral_indices.png")

    plt.savefig(output_path, dpi=VIZ_PARAMS["figure_dpi"], bbox_inches='tight')
    print(f"Saved: {output_path}")

    plt.close()
    return output_path


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def add_colorbar(ax, im, label: str):
    """Add colorbar to axis."""
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im, cax=cax, label=label)


def plot_sampling_locations(ax, subset: str = None):
    """Plot sampling locations on axis (CICRA sites only)."""
    for loc in SAMPLING_LOCATIONS:
        # Skip Puerto Maldonado sites
        if 'PM' in loc.name:
            continue
        if subset and subset not in loc.name:
            continue
        ax.scatter(loc.longitude, loc.latitude,
                   c='white', marker='o', s=60,
                   edgecolors='black', linewidth=1.5, zorder=10)


# =============================================================================
# MAIN
# =============================================================================

def main():
    """Generate all figures."""
    import glob

    print("=" * 60)
    print("GENERATING VISUALIZATION OUTPUTS")
    print("=" * 60)

    # Find available data files
    from config import DEM_DIR
    dem_files = glob.glob(os.path.join(DEM_DIR, "*.tif"))

    slope_files = glob.glob(os.path.join(GEOTIFF_DIR, "*_slope.tif"))
    tpi_files = glob.glob(os.path.join(GEOTIFF_DIR, "*_tpi.tif"))
    hillshade_files = glob.glob(os.path.join(GEOTIFF_DIR, "*_hillshade.tif"))
    scarp_files = glob.glob(os.path.join(GEOTIFF_DIR, "*_scarp_probability.tif"))

    # Figure 1: Study area (always possible)
    print("\nGenerating Figure 1: Study Area Overview")
    dem_path = dem_files[0] if dem_files else None
    plot_study_area(dem_path)

    # Figure 2: Terrain derivatives
    if dem_files and slope_files and tpi_files:
        print("\nGenerating Figure 2: Terrain Derivatives")
        plot_terrain_derivatives(
            dem_files[0],
            slope_files[0],
            tpi_files[0],
            hillshade_files[0] if hillshade_files else None
        )
    else:
        print("\nSkipping Figure 2: Missing terrain derivative files")
        print("  Run 02_terrain_analysis.py first")

    # Figure 3: Scarp detection
    if dem_files and scarp_files:
        print("\nGenerating Figure 3: Scarp Detection")
        plot_scarp_detection(
            dem_files[0],
            scarp_files[0],
            hillshade_files[0] if hillshade_files else None
        )
    else:
        print("\nSkipping Figure 3: Missing scarp detection files")
        print("  Run 03_scarp_detection.py first")

    # Figure 4: Spectral indices
    sentinel_dir = os.path.dirname(GEOTIFF_DIR).replace('outputs', 'data/sentinel')
    ndvi_files = glob.glob(os.path.join(sentinel_dir, "**", "NDVI.tif"), recursive=True)
    bsi_files = glob.glob(os.path.join(sentinel_dir, "**", "BSI.tif"), recursive=True)
    soci_files = glob.glob(os.path.join(sentinel_dir, "**", "SOCI.tif"), recursive=True)

    if ndvi_files and bsi_files and soci_files:
        print("\nGenerating Figure 4: Spectral Indices")
        plot_spectral_indices(ndvi_files[0], bsi_files[0], soci_files[0])
    else:
        print("\nSkipping Figure 4: Missing spectral index files")
        print("  Run 04_sentinel_spectral.py first")

    print("\n" + "=" * 60)
    print("VISUALIZATION COMPLETE")
    print("=" * 60)
    print(f"\nFigures saved to: {FIGURE_DIR}")


if __name__ == "__main__":
    main()
