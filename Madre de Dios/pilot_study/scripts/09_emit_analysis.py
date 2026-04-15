"""
EMIT Hyperspectral Analysis for Buried Wood Detection
NASA Earth Surface Mineral Dust Source Investigation

EMIT provides:
- 285 spectral bands (380-2500 nm)
- 60m spatial resolution
- Potential for detecting organic matter absorption features

Key spectral features for buried wood/organic matter:
- Cellulose/lignin absorption: ~1730 nm, ~2100 nm, ~2270 nm
- Organic carbon: visible absorption (400-700 nm)
- Iron oxides: 480 nm, 900 nm (weathering indicator)

Author: Isaac
Date: 2024
"""

import os
import sys
import numpy as np
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from config import (
    EMIT_DIR, FIGURE_DIR, CICRA_BBOX, SAMPLING_LOCATIONS
)

# EMIT band centers (approximate, full list has 285 bands)
EMIT_BANDS = {
    'organic_vis': (450, 700),      # Visible organic absorption
    'cellulose_1': (1700, 1750),    # Cellulose absorption
    'lignin': (2050, 2150),         # Lignin absorption  
    'cellulose_2': (2250, 2300),    # Cellulose absorption
    'swir_continuum': (2150, 2200), # Reference continuum
}


def print_emit_info():
    """Print EMIT data product information."""
    print("""
================================================================================
EMIT HYPERSPECTRAL DATA FOR BURIED WOOD DETECTION
================================================================================

EMIT (Earth Surface Mineral Dust Source Investigation):
- Platform: International Space Station
- Coverage: ±52° latitude (similar to GEDI)
- Resolution: 60m spatial, 285 spectral bands
- Wavelength: 380-2500 nm
- Access: NASA Earthdata (free)

SPECTRAL FEATURES FOR ORGANIC MATTER DETECTION:

1. Cellulose Absorption Features:
   - 1730 nm: C-H stretching
   - 2100 nm: O-H + C-O combination
   - 2270 nm: C-H stretching overtone

2. Lignin Features:
   - 1680 nm: Aromatic C-H
   - 2140 nm: Phenolic O-H

3. Soil Organic Carbon Indicators:
   - 450-700 nm: Visible darkening
   - 2200 nm: Clay-organic associations

DETECTION STRATEGY FOR TERRACE SCARPS:

Surface exposures of buried wood may show:
- Lower reflectance in visible (darker due to organic matter)
- Cellulose/lignin absorption if wood is recently exposed
- Different moisture content than surrounding sediment

Limitations:
- 60m resolution may not resolve narrow scarps
- Canopy cover prevents subsurface detection
- Exposed wood must be at surface to be detectable

RECOMMENDED INDICES:

1. Cellulose Index (CI):
   CI = R2270 / R2100
   High values indicate cellulose presence

2. Lignin Index (LI):
   LI = (R1680 - R1750) / (R1680 + R1750)
   
3. Organic Matter Index (OMI):
   OMI = (R660 - R560) / (R660 + R560)
   Similar to SOCI but with full spectral resolution

================================================================================
DATA ACCESS INSTRUCTIONS
================================================================================

1. NASA Earthdata Search:
   https://search.earthdata.nasa.gov/
   - Search: "EMIT L2A RFL"
   - Draw polygon: -70.14, -12.60, -70.06, -12.54
   - Download NetCDF files

2. LP DAAC AppEEARS (subset tool):
   https://appeears.earthdatacloud.nasa.gov/
   - Upload coordinates
   - Select EMIT L2A Reflectance
   - Submit order for subset extraction

3. NASA Harmony API (programmatic):
   from harmony import Client
   client = Client()
   # Submit subset request

================================================================================
""")


def simulate_emit_spectra():
    """
    Generate simulated EMIT-like spectra for different surface types.
    This demonstrates the spectral analysis approach.
    """
    print("\nGenerating simulated EMIT spectra...")
    
    # Wavelength grid (simplified)
    wavelengths = np.arange(400, 2500, 10)  # 210 bands
    
    # Reference spectra (simplified based on literature)
    spectra = {}
    
    # Bare soil (mineral)
    soil_baseline = 0.15 + 0.25 * (wavelengths - 400) / 2100
    soil_baseline = np.clip(soil_baseline, 0, 0.5)
    spectra['bare_soil'] = soil_baseline
    
    # Organic-rich soil (darker, with features)
    organic_soil = soil_baseline * 0.6
    # Add cellulose features
    organic_soil *= (1 - 0.05 * np.exp(-((wavelengths - 1730)**2) / (50**2)))
    organic_soil *= (1 - 0.08 * np.exp(-((wavelengths - 2270)**2) / (50**2)))
    spectra['organic_soil'] = organic_soil
    
    # Exposed wood (strong organic features)
    wood = np.ones_like(wavelengths, dtype=float) * 0.25
    wood *= (1 - 0.1 * np.exp(-((wavelengths - 480)**2) / (100**2)))   # Visible abs
    wood *= (1 - 0.12 * np.exp(-((wavelengths - 1730)**2) / (40**2)))  # Cellulose
    wood *= (1 - 0.15 * np.exp(-((wavelengths - 2100)**2) / (50**2)))  # Lignin
    wood *= (1 - 0.18 * np.exp(-((wavelengths - 2270)**2) / (40**2)))  # Cellulose
    spectra['exposed_wood'] = wood
    
    # Green vegetation
    veg = np.ones_like(wavelengths, dtype=float) * 0.05
    veg[wavelengths < 700] = 0.03 + 0.02 * (wavelengths[wavelengths < 700] - 500) / 200
    veg[(wavelengths >= 700) & (wavelengths < 1300)] = 0.45
    veg[wavelengths >= 1300] = 0.35 - 0.15 * (wavelengths[wavelengths >= 1300] - 1300) / 1200
    # Water absorption
    veg *= (1 - 0.3 * np.exp(-((wavelengths - 1450)**2) / (100**2)))
    veg *= (1 - 0.35 * np.exp(-((wavelengths - 1940)**2) / (100**2)))
    spectra['vegetation'] = np.clip(veg, 0, 0.6)
    
    return wavelengths, spectra


def plot_simulated_spectra(wavelengths, spectra, output_dir):
    """Create figure showing simulated spectra and detection approach."""
    import matplotlib.pyplot as plt
    
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
    
    # Panel A: Full spectra
    ax1 = axes[0, 0]
    colors = {'bare_soil': 'brown', 'organic_soil': 'sienna', 
              'exposed_wood': 'darkred', 'vegetation': 'green'}
    labels = {'bare_soil': 'Bare Soil (mineral)', 
              'organic_soil': 'Organic-rich Soil',
              'exposed_wood': 'Exposed Wood', 
              'vegetation': 'Green Vegetation'}
    
    for name, spectrum in spectra.items():
        ax1.plot(wavelengths, spectrum, color=colors[name], 
                label=labels[name], linewidth=1.5)
    
    # Mark key absorption features
    features = [
        (1730, 'Cellulose'),
        (2100, 'Lignin/OH'),
        (2270, 'Cellulose'),
    ]
    for wl, name in features:
        ax1.axvline(wl, color='gray', linestyle='--', alpha=0.5)
        ax1.text(wl, 0.52, name, rotation=90, fontsize=8, va='bottom')
    
    ax1.set_xlabel('Wavelength (nm)')
    ax1.set_ylabel('Reflectance')
    ax1.set_title('A) Simulated EMIT Spectra')
    ax1.legend(loc='upper right')
    ax1.set_xlim(400, 2500)
    ax1.set_ylim(0, 0.55)
    ax1.grid(True, alpha=0.3)
    
    # Panel B: Cellulose Index
    ax2 = axes[0, 1]
    ci_values = {}
    for name, spectrum in spectra.items():
        idx_2270 = np.argmin(np.abs(wavelengths - 2270))
        idx_2100 = np.argmin(np.abs(wavelengths - 2100))
        ci = spectrum[idx_2270] / spectrum[idx_2100] if spectrum[idx_2100] > 0 else 0
        ci_values[name] = ci
    
    bars = ax2.bar(range(len(ci_values)), list(ci_values.values()),
                   color=[colors[k] for k in ci_values.keys()])
    ax2.set_xticks(range(len(ci_values)))
    ax2.set_xticklabels([labels[k].split()[0] for k in ci_values.keys()], 
                        rotation=45, ha='right')
    ax2.set_ylabel('Cellulose Index (R2270/R2100)')
    ax2.set_title('B) Cellulose Detection Index')
    ax2.grid(True, alpha=0.3, axis='y')
    
    # Panel C: SWIR detail (2000-2400 nm)
    ax3 = axes[1, 0]
    swir_mask = (wavelengths >= 2000) & (wavelengths <= 2400)
    for name, spectrum in spectra.items():
        ax3.plot(wavelengths[swir_mask], spectrum[swir_mask], 
                color=colors[name], label=labels[name], linewidth=1.5)
    ax3.axvline(2100, color='gray', linestyle='--', alpha=0.5)
    ax3.axvline(2270, color='gray', linestyle='--', alpha=0.5)
    ax3.set_xlabel('Wavelength (nm)')
    ax3.set_ylabel('Reflectance')
    ax3.set_title('C) SWIR Detail - Cellulose/Lignin Region')
    ax3.legend(loc='upper right', fontsize=8)
    ax3.grid(True, alpha=0.3)
    
    # Panel D: Detection capability summary
    ax4 = axes[1, 1]
    ax4.axis('off')
    
    summary_text = """
    EMIT DETECTION CAPABILITY FOR BURIED WOOD
    
    Best case scenarios:
    ✓ Recently exposed wood at terrace scarps
    ✓ Organic-rich soil with wood fragments
    ✓ Low vegetation cover areas
    
    Limitations:
    ✗ 60m resolution averages signal
    ✗ Canopy prevents subsurface detection
    ✗ Weathered wood may lose spectral features
    
    Recommended approach:
    1. Extract EMIT spectra at scarp locations
    2. Calculate Cellulose Index (CI = R2270/R2100)
    3. Compare high-slope vs low-slope areas
    4. Field validation at anomalous pixels
    
    Expected CI values:
    • Bare soil: 0.85-0.95
    • Organic soil: 0.75-0.85
    • Exposed wood: 0.65-0.80
    • Green vegetation: 0.70-0.85
    """
    ax4.text(0.1, 0.95, summary_text, transform=ax4.transAxes,
             fontsize=10, verticalalignment='top', fontfamily='monospace',
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    ax4.set_title('D) Detection Capability Summary')
    
    plt.tight_layout()
    output_path = os.path.join(output_dir, "Fig_EMIT_spectra.png")
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"Saved: {output_path}")
    plt.close()


def main():
    os.makedirs(EMIT_DIR, exist_ok=True)
    
    print_emit_info()
    
    # Generate simulated spectra
    wavelengths, spectra = simulate_emit_spectra()
    
    # Create figure
    plot_simulated_spectra(wavelengths, spectra, FIGURE_DIR)
    
    # Save wavelengths and simulated spectra for reference
    import json
    spectra_dict = {
        'wavelengths': wavelengths.tolist(),
        'spectra': {k: v.tolist() for k, v in spectra.items()},
        'description': 'Simulated EMIT spectra for different surface types',
        'note': 'Use for spectral unmixing reference when real EMIT data available'
    }
    
    json_path = os.path.join(EMIT_DIR, "simulated_spectra.json")
    with open(json_path, 'w') as f:
        json.dump(spectra_dict, f, indent=2)
    print(f"Saved reference spectra: {json_path}")
    
    print("\n" + "=" * 60)
    print("EMIT ANALYSIS PREPARATION COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
