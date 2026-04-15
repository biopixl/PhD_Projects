"""
Data Product Comparison for Manuscript Figures
Compares NASADEM vs Copernicus DEM and derived products

Generates:
- Fig_DEM_comparison.png: Side-by-side DEM comparison
- Fig_method_comparison.png: Scarp detection methods comparison
- Fig_elevation_profiles.png: Cross-sectional profiles
- Fig_data_product_matrix.png: Summary comparison matrix
"""

import os
import sys
import numpy as np
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    DEM_DIR, GEOTIFF_DIR, FIGURE_DIR,
    CICRA_BBOX, SAMPLING_LOCATIONS, CICRA_CENTER
)

import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.lines import Line2D
from mpl_toolkits.axes_grid1 import make_axes_locatable
import rasterio


def load_raster(path):
    """Load raster and return data, extent, nodata."""
    with rasterio.open(path) as src:
        data = src.read(1).astype(np.float32)
        extent = [src.bounds.left, src.bounds.right, src.bounds.bottom, src.bounds.top]
        nodata = src.nodata
        data = np.where(data == nodata, np.nan, data)
    return data, extent


def plot_sampling_sites(ax):
    """Plot CICRA sampling sites."""
    for loc in SAMPLING_LOCATIONS:
        if 'PM' in loc.name:
            continue
        ax.scatter(loc.longitude, loc.latitude,
                   c='cyan', marker='o', s=60,
                   edgecolors='black', linewidth=1.5, zorder=10)


# =============================================================================
# FIGURE 1: DEM PRODUCT COMPARISON
# =============================================================================

def create_dem_comparison():
    """Compare NASADEM vs Copernicus DEM."""

    nasadem_path = os.path.join(DEM_DIR, "nasadem_cicra_30m.tif")
    copernicus_path = os.path.join(DEM_DIR, "copernicus_cicra_30m.tif")

    if not os.path.exists(nasadem_path) or not os.path.exists(copernicus_path):
        print("Missing DEM files for comparison")
        return

    nasadem, extent = load_raster(nasadem_path)
    copernicus, _ = load_raster(copernicus_path)

    # Calculate difference
    difference = nasadem - copernicus

    fig, axes = plt.subplots(2, 2, figsize=(12, 10))

    # Panel A: NASADEM
    ax = axes[0, 0]
    vmin, vmax = np.nanpercentile(nasadem, [2, 98])
    im = ax.imshow(nasadem, cmap='terrain', extent=extent, aspect='auto', vmin=vmin, vmax=vmax)
    plot_sampling_sites(ax)
    ax.set_title('A) NASADEM (30m)', fontweight='bold', fontsize=11)
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im, cax=cax, label='Elevation (m)')

    # Panel B: Copernicus DEM
    ax = axes[0, 1]
    im = ax.imshow(copernicus, cmap='terrain', extent=extent, aspect='auto', vmin=vmin, vmax=vmax)
    plot_sampling_sites(ax)
    ax.set_title('B) Copernicus DEM (30m)', fontweight='bold', fontsize=11)
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im, cax=cax, label='Elevation (m)')

    # Panel C: Difference
    ax = axes[1, 0]
    diff_max = np.nanpercentile(np.abs(difference), 98)
    im = ax.imshow(difference, cmap='RdBu', extent=extent, aspect='auto',
                   vmin=-diff_max, vmax=diff_max)
    plot_sampling_sites(ax)
    ax.set_title('C) Difference (NASADEM - Copernicus)', fontweight='bold', fontsize=11)
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im, cax=cax, label='Δ Elevation (m)')

    # Panel D: Statistics
    ax = axes[1, 1]
    ax.axis('off')

    stats_text = f"""
    DEM COMPARISON STATISTICS
    ─────────────────────────────────────

    NASADEM:
      • Range: {np.nanmin(nasadem):.1f} - {np.nanmax(nasadem):.1f} m
      • Mean: {np.nanmean(nasadem):.1f} m
      • Std: {np.nanstd(nasadem):.1f} m

    Copernicus DEM:
      • Range: {np.nanmin(copernicus):.1f} - {np.nanmax(copernicus):.1f} m
      • Mean: {np.nanmean(copernicus):.1f} m
      • Std: {np.nanstd(copernicus):.1f} m

    Difference:
      • Mean: {np.nanmean(difference):.2f} m
      • Std: {np.nanstd(difference):.2f} m
      • RMSE: {np.sqrt(np.nanmean(difference**2)):.2f} m
      • Max |diff|: {np.nanmax(np.abs(difference)):.1f} m

    Correlation: r = {np.corrcoef(nasadem.flatten()[~np.isnan(nasadem.flatten())],
                                   copernicus.flatten()[~np.isnan(copernicus.flatten())])[0,1]:.4f}
    """

    ax.text(0.1, 0.9, stats_text, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', fontfamily='monospace',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

    plt.suptitle('Digital Elevation Model Comparison: NASADEM vs Copernicus\nCICRA Study Area, Madre de Dios',
                 fontsize=13, fontweight='bold', y=0.98)
    plt.tight_layout(rect=[0, 0, 1, 0.95])

    output_path = os.path.join(FIGURE_DIR, "Fig_DEM_comparison.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Saved: {output_path}")
    plt.close()

    return difference


# =============================================================================
# FIGURE 2: SCARP DETECTION METHOD COMPARISON
# =============================================================================

def create_method_comparison():
    """Compare different scarp detection methods."""

    # Load terrain derivatives
    files = {
        'slope': os.path.join(GEOTIFF_DIR, "enhanced_cicra_slope_enhanced.tif"),
        'tpi': os.path.join(GEOTIFF_DIR, "enhanced_cicra_tpi_multiscale.tif"),
        'edges': os.path.join(GEOTIFF_DIR, "enhanced_cicra_edge_magnitude.tif"),
        'scarp_prob': os.path.join(GEOTIFF_DIR, "enhanced_cicra_scarp_probability_enhanced.tif"),
    }

    data = {}
    for name, path in files.items():
        if os.path.exists(path):
            data[name], extent = load_raster(path)
        else:
            print(f"Missing: {path}")
            return

    fig, axes = plt.subplots(2, 3, figsize=(15, 10))

    # Panel A: Slope-based detection
    ax = axes[0, 0]
    slope_detect = (data['slope'] > 15).astype(float)
    ax.imshow(slope_detect, cmap='Reds', extent=extent, aspect='auto', vmin=0, vmax=1)
    plot_sampling_sites(ax)
    ax.set_title('A) Slope Threshold (>15°)', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    # Panel B: TPI-based detection
    ax = axes[0, 1]
    tpi_grad = np.abs(np.gradient(data['tpi'])[0]) + np.abs(np.gradient(data['tpi'])[1])
    tpi_detect = tpi_grad / np.nanpercentile(tpi_grad, 98)
    ax.imshow(np.clip(tpi_detect, 0, 1), cmap='Reds', extent=extent, aspect='auto', vmin=0, vmax=1)
    plot_sampling_sites(ax)
    ax.set_title('B) TPI Gradient', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    # Panel C: Edge detection
    ax = axes[0, 2]
    edge_norm = data['edges'] / np.nanpercentile(data['edges'], 98)
    ax.imshow(np.clip(edge_norm, 0, 1), cmap='Reds', extent=extent, aspect='auto', vmin=0, vmax=1)
    plot_sampling_sites(ax)
    ax.set_title('C) Directional Edge Detection', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    # Panel D: Combined probability
    ax = axes[1, 0]
    im = ax.imshow(data['scarp_prob'], cmap='YlOrRd', extent=extent, aspect='auto', vmin=0, vmax=1)
    plot_sampling_sites(ax)
    ax.set_title('D) Combined Scarp Probability', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="5%", pad=0.1)
    plt.colorbar(im, cax=cax, label='Probability')

    # Panel E: Binary classification comparison
    ax = axes[1, 1]

    # Create RGB composite: R=slope, G=TPI, B=edge
    rgb = np.zeros((*data['slope'].shape, 3))
    rgb[:,:,0] = np.clip(slope_detect, 0, 1)
    rgb[:,:,1] = np.clip(tpi_detect, 0, 1)
    rgb[:,:,2] = np.clip(edge_norm, 0, 1)

    ax.imshow(rgb, extent=extent, aspect='auto')
    plot_sampling_sites(ax)
    ax.set_title('E) Method Composite (R=Slope, G=TPI, B=Edge)', fontweight='bold')
    ax.set_xlabel('Longitude')
    ax.set_ylabel('Latitude')

    # Panel F: Detection statistics
    ax = axes[1, 2]
    ax.axis('off')

    # Calculate detection areas
    high_prob = data['scarp_prob'] > 0.6
    med_prob = (data['scarp_prob'] > 0.4) & (data['scarp_prob'] <= 0.6)
    slope_only = data['slope'] > 15

    stats_text = f"""
    SCARP DETECTION COMPARISON
    ─────────────────────────────────────────

    Method Performance (% of study area):

    1. Slope Threshold (>15°):
       • Detection: {100*np.nanmean(slope_only):.1f}%

    2. TPI Gradient:
       • High gradient: {100*np.nanmean(tpi_detect > 0.5):.1f}%

    3. Edge Detection:
       • Strong edges: {100*np.nanmean(edge_norm > 0.5):.1f}%

    4. Combined Probability:
       • High (>0.6): {100*np.nanmean(high_prob):.1f}%
       • Medium (0.4-0.6): {100*np.nanmean(med_prob):.1f}%
       • Total candidate: {100*np.nanmean(data['scarp_prob'] > 0.4):.1f}%

    Method Agreement:
       • All 3 methods agree: {100*np.nanmean((slope_only) & (tpi_detect > 0.5) & (edge_norm > 0.5)):.2f}%
       • At least 2 agree: {100*np.nanmean(((slope_only).astype(int) + (tpi_detect > 0.5).astype(int) + (edge_norm > 0.5).astype(int)) >= 2):.1f}%
    """

    ax.text(0.05, 0.95, stats_text, transform=ax.transAxes, fontsize=9,
            verticalalignment='top', fontfamily='monospace',
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))

    plt.suptitle('Scarp Detection Method Comparison\nCICRA Study Area',
                 fontsize=13, fontweight='bold', y=0.98)
    plt.tight_layout(rect=[0, 0, 1, 0.95])

    output_path = os.path.join(FIGURE_DIR, "Fig_method_comparison.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Saved: {output_path}")
    plt.close()


# =============================================================================
# FIGURE 3: ELEVATION PROFILES
# =============================================================================

def create_elevation_profiles():
    """Create cross-sectional elevation profiles through sampling sites."""

    nasadem_path = os.path.join(DEM_DIR, "nasadem_cicra_30m.tif")
    copernicus_path = os.path.join(DEM_DIR, "copernicus_cicra_30m.tif")

    nasadem, extent = load_raster(nasadem_path)
    copernicus, _ = load_raster(copernicus_path)

    fig, axes = plt.subplots(3, 1, figsize=(12, 10))

    # Define profile lines through each sampling site (E-W transects)
    profiles = [
        {"name": "Columna 1", "lat": -12.5653, "lon_range": (-70.13, -70.07)},
        {"name": "Columna 4", "lat": -12.5690, "lon_range": (-70.13, -70.07)},
        {"name": "Columna 5", "lat": -12.5572, "lon_range": (-70.12, -70.06)},
    ]

    for idx, profile in enumerate(profiles):
        ax = axes[idx]

        # Find row index for latitude
        lat_idx = int((extent[3] - profile["lat"]) / (extent[3] - extent[2]) * nasadem.shape[0])
        lat_idx = np.clip(lat_idx, 0, nasadem.shape[0] - 1)

        # Extract profile
        lon_start_idx = int((profile["lon_range"][0] - extent[0]) / (extent[1] - extent[0]) * nasadem.shape[1])
        lon_end_idx = int((profile["lon_range"][1] - extent[0]) / (extent[1] - extent[0]) * nasadem.shape[1])

        lon_start_idx = np.clip(lon_start_idx, 0, nasadem.shape[1] - 1)
        lon_end_idx = np.clip(lon_end_idx, 0, nasadem.shape[1] - 1)

        profile_nasadem = nasadem[lat_idx, lon_start_idx:lon_end_idx]
        profile_copernicus = copernicus[lat_idx, lon_start_idx:lon_end_idx]

        # Distance axis
        lons = np.linspace(profile["lon_range"][0], profile["lon_range"][1], len(profile_nasadem))
        distance_km = (lons - lons[0]) * 111 * np.cos(np.radians(profile["lat"]))

        # Plot profiles
        ax.plot(distance_km, profile_nasadem, 'b-', linewidth=2, label='NASADEM')
        ax.plot(distance_km, profile_copernicus, 'r--', linewidth=2, label='Copernicus')
        ax.fill_between(distance_km, profile_nasadem, profile_copernicus,
                        alpha=0.3, color='gray', label='Difference')

        # Mark sampling site location
        site_lon = [loc.longitude for loc in SAMPLING_LOCATIONS if profile["name"].split()[-1] in loc.name]
        if site_lon:
            site_dist = (site_lon[0] - profile["lon_range"][0]) * 111 * np.cos(np.radians(profile["lat"]))
            ax.axvline(site_dist, color='green', linestyle=':', linewidth=2, label=f'{profile["name"]} location')

        ax.set_xlabel('Distance (km)' if idx == 2 else '')
        ax.set_ylabel('Elevation (m)')
        ax.set_title(f'{chr(65+idx)}) E-W Profile through {profile["name"]} (Lat: {profile["lat"]:.4f}°)',
                     fontweight='bold')
        ax.legend(loc='upper right', fontsize=9)
        ax.grid(True, alpha=0.3)

        # Add terrace/floodplain annotations
        if idx == 0:
            ax.annotate('Terra Firme\n(Terrace)', xy=(0.15, 0.85), xycoords='axes fraction',
                       fontsize=9, ha='center', bbox=dict(boxstyle='round', facecolor='wheat'))
            ax.annotate('Floodplain', xy=(0.85, 0.3), xycoords='axes fraction',
                       fontsize=9, ha='center', bbox=dict(boxstyle='round', facecolor='lightblue'))

    plt.suptitle('Elevation Profiles: NASADEM vs Copernicus DEM\nE-W Transects Through Sampling Sites',
                 fontsize=13, fontweight='bold', y=0.98)
    plt.tight_layout(rect=[0, 0, 1, 0.95])

    output_path = os.path.join(FIGURE_DIR, "Fig_elevation_profiles.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Saved: {output_path}")
    plt.close()


# =============================================================================
# FIGURE 4: DATA PRODUCT MATRIX
# =============================================================================

def create_data_product_matrix():
    """Create summary matrix of data products and capabilities."""

    fig, ax = plt.subplots(figsize=(14, 10))
    ax.axis('off')

    # Define data products and attributes
    products = [
        "NASADEM",
        "Copernicus DEM",
        "ALOS PALSAR",
        "GEDI L2A",
        "ICESat-2 ATL08",
        "Sentinel-2",
        "HLS",
        "AVIRIS-NG",
        "EMIT"
    ]

    attributes = [
        "Resolution",
        "Coverage",
        "Vertical Acc.",
        "Canopy Penetration",
        "Spectral Bands",
        "Temporal",
        "Scarp Detection",
        "Wood Detection",
        "Free Access"
    ]

    # Data matrix
    data = [
        # NASADEM
        ["30 m", "Global\n(60N-56S)", "±5 m", "No", "-", "Static\n(2000)", "★★★", "★", "Yes"],
        # Copernicus
        ["30 m", "Global", "±4 m", "No", "-", "Static\n(2021)", "★★★", "★", "Yes"],
        # ALOS PALSAR
        ["12.5 m", "Global", "±5 m", "Partial\n(L-band)", "-", "2006-2011", "★★★★", "★★", "Yes"],
        # GEDI
        ["25 m\nfootprint", "±51.6°\nlat", "±1 m", "Yes", "-", "2019-2024\n(gaps)", "★★★★", "★★★", "Yes"],
        # ICESat-2
        ["100 m\nsegment", "Global", "±0.5 m", "Yes", "-", "2018-\npresent", "★★★", "★★", "Yes"],
        # Sentinel-2
        ["10-20 m", "Global", "-", "No", "13", "5 days", "★★", "★★★", "Yes"],
        # HLS
        ["30 m", "Global", "-", "No", "7", "2-3 days", "★★", "★★★", "Yes"],
        # AVIRIS-NG
        ["~5 m", "Campaign\nonly", "-", "No", "224", "On-demand", "★★", "★★★★", "Limited"],
        # EMIT
        ["60 m", "ISS\n(±51.6°)", "-", "No", "285", "Variable", "★", "★★★★", "Yes"],
    ]

    # Create table
    colors = []
    for row in data:
        row_colors = []
        for val in row:
            if '★★★★' in str(val):
                row_colors.append('#90EE90')  # Light green
            elif '★★★' in str(val):
                row_colors.append('#FFFFE0')  # Light yellow
            elif '★★' in str(val):
                row_colors.append('#FFE4B5')  # Moccasin
            elif '★' in str(val):
                row_colors.append('#FFB6C1')  # Light pink
            elif val == 'Yes':
                row_colors.append('#90EE90')
            elif val == 'No':
                row_colors.append('#FFB6C1')
            elif val == 'Limited':
                row_colors.append('#FFE4B5')
            else:
                row_colors.append('white')
        colors.append(row_colors)

    table = ax.table(cellText=data,
                     rowLabels=products,
                     colLabels=attributes,
                     cellColours=colors,
                     loc='center',
                     cellLoc='center')

    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1.2, 2.0)

    # Style header
    for j in range(len(attributes)):
        table[(0, j)].set_facecolor('#4472C4')
        table[(0, j)].set_text_props(color='white', fontweight='bold')

    # Style row labels
    for i in range(len(products)):
        table[(i+1, -1)].set_facecolor('#5B9BD5')
        table[(i+1, -1)].set_text_props(color='white', fontweight='bold')

    # Legend
    legend_text = """
    Rating Scale:  ★★★★ = Excellent    ★★★ = Good    ★★ = Moderate    ★ = Limited

    Scarp Detection: Ability to identify terrace scarps from elevation/terrain data
    Wood Detection: Potential to detect buried organic matter (spectral/penetrating sensors)
    """

    ax.text(0.5, 0.02, legend_text, transform=ax.transAxes, fontsize=10,
            ha='center', va='bottom', fontfamily='monospace',
            bbox=dict(boxstyle='round', facecolor='lightgray', alpha=0.5))

    plt.title('Remote Sensing Data Products for Buried Forest Detection\nCapability Comparison Matrix',
              fontsize=14, fontweight='bold', pad=20)

    output_path = os.path.join(FIGURE_DIR, "Fig_data_product_matrix.png")
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Saved: {output_path}")
    plt.close()


# =============================================================================
# MAIN
# =============================================================================

def main():
    """Generate all comparison figures."""

    print("=" * 60)
    print("GENERATING DATA PRODUCT COMPARISON FIGURES")
    print("=" * 60)

    print("\n1. DEM Comparison (NASADEM vs Copernicus)...")
    create_dem_comparison()

    print("\n2. Scarp Detection Method Comparison...")
    create_method_comparison()

    print("\n3. Elevation Profiles...")
    create_elevation_profiles()

    print("\n4. Data Product Capability Matrix...")
    create_data_product_matrix()

    print("\n" + "=" * 60)
    print("ALL FIGURES GENERATED")
    print("=" * 60)


if __name__ == "__main__":
    main()
