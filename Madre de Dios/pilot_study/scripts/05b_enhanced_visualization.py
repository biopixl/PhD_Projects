"""
Enhanced Visualization for CICRA Scarp Detection
Shows multi-scale analysis results with improved feature visibility
"""

import os
import sys
import numpy as np
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    GEOTIFF_DIR, FIGURE_DIR, DEM_DIR,
    CICRA_BBOX, SAMPLING_LOCATIONS, CICRA_CENTER, VIZ_PARAMS
)

import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.lines import Line2D
from mpl_toolkits.axes_grid1 import make_axes_locatable
import rasterio


def create_scarp_cmap():
    """Enhanced scarp colormap."""
    colors = [
        (0.0, '#f7f7f7'),    # Low - light gray
        (0.3, '#ffffb2'),    # Low-med - yellow
        (0.5, '#fd8d3c'),    # Medium - orange
        (0.7, '#e31a1c'),    # High - red
        (1.0, '#800026'),    # Very high - dark red
    ]
    return LinearSegmentedColormap.from_list('scarp_enhanced', colors)


def plot_sampling_sites(ax):
    """Plot CICRA sampling sites only."""
    for loc in SAMPLING_LOCATIONS:
        if 'PM' in loc.name:
            continue
        ax.scatter(loc.longitude, loc.latitude,
                   c='cyan', marker='o', s=80,
                   edgecolors='black', linewidth=1.5, zorder=10)


def main():
    """Generate enhanced visualization figure."""

    # Load rasters
    dem_path = os.path.join(DEM_DIR, "copernicus_cicra_30m.tif")
    hillshade_path = os.path.join(GEOTIFF_DIR, "enhanced_cicra_hillshade_multidirectional.tif")
    scarp_path = os.path.join(GEOTIFF_DIR, "enhanced_cicra_scarp_probability_enhanced.tif")
    tpi_path = os.path.join(GEOTIFF_DIR, "enhanced_cicra_tpi_multiscale.tif")
    edge_path = os.path.join(GEOTIFF_DIR, "enhanced_cicra_edge_magnitude.tif")
    slope_path = os.path.join(GEOTIFF_DIR, "enhanced_cicra_slope_enhanced.tif")

    # Read data
    with rasterio.open(dem_path) as src:
        dem = src.read(1)
        extent = [src.bounds.left, src.bounds.right, src.bounds.bottom, src.bounds.top]
        nodata = src.nodata

    dem = np.where(dem == nodata, np.nan, dem)

    with rasterio.open(hillshade_path) as src:
        hillshade = src.read(1)

    with rasterio.open(scarp_path) as src:
        scarp_prob = src.read(1)
        scarp_prob = np.where(scarp_prob == src.nodata, np.nan, scarp_prob)

    with rasterio.open(tpi_path) as src:
        tpi = src.read(1)
        tpi = np.where(tpi == src.nodata, np.nan, tpi)

    with rasterio.open(edge_path) as src:
        edges = src.read(1)
        edges = np.where(edges == src.nodata, np.nan, edges)

    with rasterio.open(slope_path) as src:
        slope = src.read(1)
        slope = np.where(slope == src.nodata, np.nan, slope)

    # Create figure
    fig = plt.figure(figsize=(14, 10))

    # Panel A: Multi-directional hillshade with scarp overlay
    ax1 = fig.add_subplot(2, 2, 1)
    ax1.imshow(hillshade, cmap='gray', extent=extent, aspect='auto')

    # Overlay high-probability scarps
    scarp_masked = np.ma.masked_where(scarp_prob < 0.5, scarp_prob)
    im1 = ax1.imshow(scarp_masked, cmap=create_scarp_cmap(), extent=extent,
                     aspect='auto', alpha=0.7, vmin=0, vmax=1)

    plot_sampling_sites(ax1)
    ax1.set_title('A) Multi-directional Hillshade + Scarp Detection', fontweight='bold')
    ax1.set_xlabel('Longitude')
    ax1.set_ylabel('Latitude')

    # Colorbar
    divider = make_axes_locatable(ax1)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im1, cax=cax, label='Scarp Probability')

    # Panel B: Enhanced scarp probability
    ax2 = fig.add_subplot(2, 2, 2)
    im2 = ax2.imshow(scarp_prob, cmap=create_scarp_cmap(), extent=extent,
                     aspect='auto', vmin=0, vmax=1)

    # Add contours
    y = np.linspace(extent[3], extent[2], scarp_prob.shape[0])
    x = np.linspace(extent[0], extent[1], scarp_prob.shape[1])
    X, Y = np.meshgrid(x, y)
    ax2.contour(X, Y, scarp_prob, levels=[0.5, 0.7, 0.9],
                colors=['yellow', 'orange', 'red'], linewidths=[0.5, 1, 1.5])

    plot_sampling_sites(ax2)
    ax2.set_title('B) Enhanced Scarp Probability', fontweight='bold')
    ax2.set_xlabel('Longitude')
    ax2.set_ylabel('Latitude')

    divider = make_axes_locatable(ax2)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im2, cax=cax, label='Probability')

    # Panel C: Multi-scale TPI
    ax3 = fig.add_subplot(2, 2, 3)
    vmax = np.nanpercentile(np.abs(tpi), 95)
    im3 = ax3.imshow(tpi, cmap='RdBu_r', extent=extent, aspect='auto',
                     vmin=-vmax, vmax=vmax)

    plot_sampling_sites(ax3)
    ax3.set_title('C) Multi-scale Topographic Position Index', fontweight='bold')
    ax3.set_xlabel('Longitude')
    ax3.set_ylabel('Latitude')

    divider = make_axes_locatable(ax3)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    cbar = plt.colorbar(im3, cax=cax, label='TPI (m)')

    # Panel D: Edge detection + Slope composite
    ax4 = fig.add_subplot(2, 2, 4)

    # Normalize and combine edge and slope
    edge_norm = edges / np.nanpercentile(edges, 98)
    slope_norm = slope / 30  # Normalize to 0-1 for slopes up to 30 deg

    composite = 0.5 * np.clip(edge_norm, 0, 1) + 0.5 * np.clip(slope_norm, 0, 1)

    im4 = ax4.imshow(composite, cmap='YlOrRd', extent=extent, aspect='auto',
                     vmin=0, vmax=1)

    plot_sampling_sites(ax4)
    ax4.set_title('D) Edge + Slope Composite', fontweight='bold')
    ax4.set_xlabel('Longitude')
    ax4.set_ylabel('Latitude')

    divider = make_axes_locatable(ax4)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im4, cax=cax, label='Intensity')

    # Legend for sampling sites
    legend_elements = [
        Line2D([0], [0], marker='o', color='w', markerfacecolor='cyan',
               markeredgecolor='black', markersize=10, label='Sampling Columns'),
    ]
    fig.legend(handles=legend_elements, loc='lower center', ncol=1,
               bbox_to_anchor=(0.5, 0.02))

    plt.suptitle('Enhanced Terrain Analysis for Terrace Scarp Detection\nCICRA Study Area, Madre de Dios',
                 fontsize=14, fontweight='bold', y=0.98)

    plt.tight_layout(rect=[0, 0.05, 1, 0.95])

    # Save
    output_path = os.path.join(FIGURE_DIR, "Fig4_enhanced_scarp_detection.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Saved: {output_path}")

    plt.close()

    # Create focused scarp map
    create_focused_scarp_figure(hillshade, scarp_prob, dem, extent)


def create_focused_scarp_figure(hillshade, scarp_prob, dem, extent):
    """Create a single focused figure showing detected scarps."""

    fig, ax = plt.subplots(figsize=(10, 8))

    # Hillshade background
    ax.imshow(hillshade, cmap='gray', extent=extent, aspect='auto')

    # Scarp probability overlay (only show > 0.4)
    scarp_masked = np.ma.masked_where(scarp_prob < 0.4, scarp_prob)
    im = ax.imshow(scarp_masked, cmap=create_scarp_cmap(), extent=extent,
                   aspect='auto', alpha=0.8, vmin=0.4, vmax=1)

    # Elevation contours
    y = np.linspace(extent[3], extent[2], dem.shape[0])
    x = np.linspace(extent[0], extent[1], dem.shape[1])
    X, Y = np.meshgrid(x, y)

    contour_levels = np.arange(220, 310, 10)  # 10m contours
    cs = ax.contour(X, Y, dem, levels=contour_levels, colors='blue',
                    linewidths=0.3, alpha=0.5)
    ax.clabel(cs, inline=True, fontsize=6, fmt='%d m')

    # Sampling sites with labels
    for loc in SAMPLING_LOCATIONS:
        if 'PM' in loc.name:
            continue
        ax.scatter(loc.longitude, loc.latitude,
                   c='cyan', marker='o', s=100,
                   edgecolors='black', linewidth=2, zorder=10)

        label = loc.name.replace('COLUMNA_', 'C').replace('_CICRA', '').replace('_LOS_AMIGOS', '')
        ax.annotate(label, (loc.longitude, loc.latitude),
                    xytext=(8, 8), textcoords='offset points',
                    fontsize=10, fontweight='bold', color='white',
                    bbox=dict(boxstyle='round,pad=0.3', facecolor='black', alpha=0.7))

    # CICRA marker
    ax.scatter(*CICRA_CENTER, c='yellow', marker='*', s=200,
               edgecolors='black', linewidth=1.5, zorder=11)

    ax.set_xlabel('Longitude', fontsize=11)
    ax.set_ylabel('Latitude', fontsize=11)
    ax.set_title('Detected Terrace Scarps at CICRA\nMadre de Dios River, Peru',
                 fontsize=13, fontweight='bold')

    # Colorbar
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="4%", pad=0.1)
    cbar = plt.colorbar(im, cax=cax)
    cbar.set_label('Scarp Probability', fontsize=10)

    # Legend
    legend_elements = [
        Line2D([0], [0], marker='o', color='w', markerfacecolor='cyan',
               markeredgecolor='black', markersize=10, label='Sampling Columns'),
        Line2D([0], [0], marker='*', color='w', markerfacecolor='yellow',
               markeredgecolor='black', markersize=15, label='CICRA Station'),
        Line2D([0], [0], color='blue', linewidth=0.5, alpha=0.5, label='Elevation Contours'),
    ]
    ax.legend(handles=legend_elements, loc='upper left', fontsize=9)

    plt.tight_layout()

    output_path = os.path.join(FIGURE_DIR, "Fig5_scarp_map_focused.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Saved: {output_path}")

    plt.close()


if __name__ == "__main__":
    main()
