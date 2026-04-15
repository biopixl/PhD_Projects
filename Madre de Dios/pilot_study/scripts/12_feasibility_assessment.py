#!/usr/bin/env python3
"""
Feasibility Assessment and Science Traceability Matrix Tracking

This script:
1. Assesses data product availability and readiness
2. Calculates feasibility scores for each science objective
3. Tracks carbon quantification parameter status
4. Generates summary reports

Integrates with:
- TRACKING.md
- FEASIBILITY_ANALYSIS.md
- outputs/PROGRESS.md
"""

import os
import sys
import json
from datetime import datetime
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Optional
from pathlib import Path

# Add parent directory for config
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import (
    PROJECT_ROOT, OUTPUT_DIR, GEOTIFF_DIR, DATA_PRODUCTS,
    get_products_by_status, get_products_by_category
)

# =============================================================================
# DATA STRUCTURES
# =============================================================================

@dataclass
class ScienceObjective:
    """Science Traceability Matrix entry"""
    id: str
    level: int  # 1=primary, 2=secondary, 3=tertiary
    description: str
    data_products: List[str]
    variables: List[str]
    validation: str
    feasibility: str  # HIGH, MODERATE, LOW
    status: str  # complete, in_progress, pending
    notes: str = ""

@dataclass
class CarbonParameter:
    """Carbon quantification parameter"""
    name: str
    symbol: str
    value_range: str
    source: str
    status: str  # complete, in_progress, pending
    uncertainty: str
    current_value: Optional[float] = None

@dataclass
class FeasibilityScore:
    """Feasibility assessment score"""
    criterion: str
    score: int  # 1-5
    max_score: int = 5
    evidence: str = ""

# =============================================================================
# SCIENCE TRACEABILITY MATRIX
# =============================================================================

STM_OBJECTIVES = [
    # Level 1 - Primary
    ScienceObjective(
        id="L1.1",
        level=1,
        description="Quantify buried forest carbon stocks in Amazonian river terraces",
        data_products=["All"],
        variables=["Carbon stock (Mg C)"],
        validation="Full methodology",
        feasibility="MODERATE",
        status="in_progress",
        notes="Primary research objective"
    ),

    # Level 2 - Secondary
    ScienceObjective(
        id="L2.1",
        level=2,
        description="Map spatial distribution of terrace scarps",
        data_products=["NASADEM", "Copernicus", "GEDI"],
        variables=["Slope", "TPI", "Edge magnitude"],
        validation="GPS survey",
        feasibility="HIGH",
        status="complete"
    ),
    ScienceObjective(
        id="L2.2",
        level=2,
        description="Estimate scarp geometry (height, length, orientation)",
        data_products=["GEDI L2A", "DEM"],
        variables=["Height (m)", "Length (m)", "Azimuth (°)"],
        validation="Laser rangefinder",
        feasibility="HIGH",
        status="in_progress"
    ),
    ScienceObjective(
        id="L2.3",
        level=2,
        description="Identify locations with buried wood potential",
        data_products=["EMIT L2A", "Sentinel-2"],
        variables=["Cellulose index", "NDVI anomaly"],
        validation="Visual inspection",
        feasibility="MODERATE",
        status="in_progress"
    ),
    ScienceObjective(
        id="L2.4",
        level=2,
        description="Quantify wood volume at exposed scarps",
        data_products=["Field data", "TLS"],
        variables=["Cross-section area", "Volume (m³/m)"],
        validation="Pit excavation",
        feasibility="LOW",
        status="pending"
    ),
    ScienceObjective(
        id="L2.5",
        level=2,
        description="Estimate carbon density per unit scarp length",
        data_products=["Lab analysis"],
        variables=["Density (kg/m³)", "C fraction"],
        validation="CHN analyzer",
        feasibility="LOW",
        status="pending"
    ),

    # Level 3 - Tertiary (STM detailed)
    ScienceObjective(
        id="STM-1.1",
        level=3,
        description="Detect slope breaks >15°",
        data_products=["NASADEM", "Copernicus"],
        variables=["Slope (degrees)"],
        validation="GPS + visual",
        feasibility="HIGH",
        status="complete"
    ),
    ScienceObjective(
        id="STM-1.2",
        level=3,
        description="Map terrace/floodplain transitions via TPI",
        data_products=["DEM"],
        variables=["TPI multi-scale"],
        validation="GPS survey",
        feasibility="HIGH",
        status="complete"
    ),
    ScienceObjective(
        id="STM-1.3",
        level=3,
        description="Identify linear scarp features",
        data_products=["DEM"],
        variables=["Edge magnitude"],
        validation="Field mapping",
        feasibility="HIGH",
        status="complete"
    ),
    ScienceObjective(
        id="STM-1.4",
        level=3,
        description="Calculate composite scarp probability",
        data_products=["Derived"],
        variables=["Probability (0-1)"],
        validation="Confusion matrix",
        feasibility="HIGH",
        status="complete"
    ),
    ScienceObjective(
        id="STM-2.1",
        level=3,
        description="Measure scarp height from lidar",
        data_products=["GEDI L2A"],
        variables=["Ground elevation (m)"],
        validation="Laser rangefinder",
        feasibility="HIGH",
        status="in_progress"
    ),
    ScienceObjective(
        id="STM-3.1",
        level=3,
        description="Detect wood via cellulose absorption",
        data_products=["EMIT L2A"],
        variables=["Cellulose 2100nm"],
        validation="ASD spectrometer",
        feasibility="MODERATE",
        status="in_progress"
    ),
    ScienceObjective(
        id="STM-3.2",
        level=3,
        description="Detect organic matter via lignin absorption",
        data_products=["EMIT L2A"],
        variables=["Lignin 2270nm"],
        validation="Lab chemistry",
        feasibility="MODERATE",
        status="in_progress"
    ),
]

# =============================================================================
# CARBON PARAMETERS
# =============================================================================

CARBON_PARAMETERS = [
    CarbonParameter(
        name="Total scarp length",
        symbol="L_total",
        value_range="TBD km",
        source="DEM vectorization",
        status="in_progress",
        uncertainty="±10%"
    ),
    CarbonParameter(
        name="Mean scarp height",
        symbol="H_mean",
        value_range="5-15 m",
        source="GEDI + DEM",
        status="pending",
        uncertainty="±2 m"
    ),
    CarbonParameter(
        name="Wood presence probability",
        symbol="P_wood",
        value_range="0.3-0.8",
        source="EMIT + Field",
        status="pending",
        uncertainty="±0.2"
    ),
    CarbonParameter(
        name="Volume per meter",
        symbol="V_per_m",
        value_range="0.5-2.0 m³/m",
        source="Field measurement",
        status="pending",
        uncertainty="±50%"
    ),
    CarbonParameter(
        name="Wood density (subfossil)",
        symbol="ρ_wood",
        value_range="400-700 kg/m³",
        source="Lab analysis",
        status="pending",
        uncertainty="±100 kg/m³"
    ),
    CarbonParameter(
        name="Carbon fraction",
        symbol="f_C",
        value_range="0.47",
        source="Literature",
        status="complete",
        uncertainty="±0.02",
        current_value=0.47
    ),
    CarbonParameter(
        name="Preservation factor",
        symbol="f_pres",
        value_range="0.50-0.97",
        source="Lab analysis",
        status="pending",
        uncertainty="±0.15"
    ),
]

# =============================================================================
# FEASIBILITY ASSESSMENT
# =============================================================================

def assess_data_product_feasibility(product_name: str) -> Dict:
    """Assess feasibility for a single data product"""

    assessments = {
        "nasadem": {
            "scores": [
                FeasibilityScore("Spatial resolution", 4, 5, "30m resolves >50m scarps"),
                FeasibilityScore("Vertical accuracy", 4, 5, "±5m absolute"),
                FeasibilityScore("Coverage", 5, 5, "Global"),
                FeasibilityScore("Accessibility", 5, 5, "Free, NASA EarthData"),
                FeasibilityScore("Scarp detection", 5, 5, "Excellent via derivatives"),
            ],
            "overall": "HIGH",
            "recommendation": "Primary DEM source"
        },
        "copernicus": {
            "scores": [
                FeasibilityScore("Spatial resolution", 4, 5, "30m resolves >50m scarps"),
                FeasibilityScore("Vertical accuracy", 4, 5, "±4m absolute"),
                FeasibilityScore("Coverage", 5, 5, "Global"),
                FeasibilityScore("Accessibility", 5, 5, "Free, AWS"),
                FeasibilityScore("Scarp detection", 5, 5, "Excellent, less noise"),
            ],
            "overall": "HIGH",
            "recommendation": "Validation/comparison DEM"
        },
        "gedi_l4a": {
            "scores": [
                FeasibilityScore("Spatial resolution", 3, 5, "25m footprint, point sampling"),
                FeasibilityScore("Elevation accuracy", 5, 5, "±1m ground elevation"),
                FeasibilityScore("Coverage", 3, 5, "±51.6° lat, not wall-to-wall"),
                FeasibilityScore("Accessibility", 5, 5, "Free, NASA LP DAAC"),
                FeasibilityScore("Scarp detection", 4, 5, "Good for height validation"),
            ],
            "overall": "MODERATE-HIGH",
            "recommendation": "Height validation"
        },
        "emit_l2a": {
            "scores": [
                FeasibilityScore("Spatial resolution", 2, 5, "60m - coarse for outcrops"),
                FeasibilityScore("Spectral resolution", 5, 5, "285 bands, full VSWIR"),
                FeasibilityScore("Coverage", 3, 5, "ISS orbit, variable"),
                FeasibilityScore("Accessibility", 5, 5, "Free, NASA LP DAAC"),
                FeasibilityScore("Wood detection", 3, 5, "Theoretical potential"),
            ],
            "overall": "MODERATE",
            "recommendation": "Exploratory spectral analysis"
        },
        "sentinel2": {
            "scores": [
                FeasibilityScore("Spatial resolution", 4, 5, "10-20m"),
                FeasibilityScore("Spectral bands", 3, 5, "13 bands, limited SWIR"),
                FeasibilityScore("Temporal coverage", 5, 5, "5-day revisit"),
                FeasibilityScore("Accessibility", 5, 5, "Free, Copernicus"),
                FeasibilityScore("Scarp detection", 3, 5, "Indirect via NDVI gaps"),
            ],
            "overall": "MODERATE",
            "recommendation": "Vegetation context mapping"
        }
    }

    return assessments.get(product_name, {"overall": "UNKNOWN", "scores": []})


def calculate_overall_feasibility() -> Dict:
    """Calculate overall project feasibility"""

    # Count products by status
    complete = len(get_products_by_status("complete"))
    downloading = len(get_products_by_status("downloading"))
    pending = len(get_products_by_status("pending"))
    total = complete + downloading + pending

    # Count objectives by status
    obj_complete = sum(1 for o in STM_OBJECTIVES if o.status == "complete")
    obj_progress = sum(1 for o in STM_OBJECTIVES if o.status == "in_progress")
    obj_pending = sum(1 for o in STM_OBJECTIVES if o.status == "pending")

    # Count parameters by status
    param_complete = sum(1 for p in CARBON_PARAMETERS if p.status == "complete")
    param_progress = sum(1 for p in CARBON_PARAMETERS if p.status == "in_progress")
    param_pending = sum(1 for p in CARBON_PARAMETERS if p.status == "pending")

    # Feasibility by objective level
    high_feas = sum(1 for o in STM_OBJECTIVES if o.feasibility == "HIGH")
    mod_feas = sum(1 for o in STM_OBJECTIVES if o.feasibility == "MODERATE")
    low_feas = sum(1 for o in STM_OBJECTIVES if o.feasibility == "LOW")

    return {
        "data_products": {
            "complete": complete,
            "downloading": downloading,
            "pending": pending,
            "total": total,
            "percent_complete": round(100 * complete / total, 1) if total > 0 else 0
        },
        "objectives": {
            "complete": obj_complete,
            "in_progress": obj_progress,
            "pending": obj_pending,
            "total": len(STM_OBJECTIVES),
            "percent_complete": round(100 * obj_complete / len(STM_OBJECTIVES), 1)
        },
        "carbon_parameters": {
            "complete": param_complete,
            "in_progress": param_progress,
            "pending": param_pending,
            "total": len(CARBON_PARAMETERS),
            "percent_complete": round(100 * param_complete / len(CARBON_PARAMETERS), 1)
        },
        "feasibility_distribution": {
            "HIGH": high_feas,
            "MODERATE": mod_feas,
            "LOW": low_feas
        },
        "overall_assessment": determine_overall_assessment(complete, total, obj_complete, len(STM_OBJECTIVES))
    }


def determine_overall_assessment(prod_complete, prod_total, obj_complete, obj_total) -> str:
    """Determine overall project feasibility assessment"""
    prod_pct = prod_complete / prod_total if prod_total > 0 else 0
    obj_pct = obj_complete / obj_total if obj_total > 0 else 0

    combined = (prod_pct + obj_pct) / 2

    if combined >= 0.75:
        return "HIGH - Ready for field validation"
    elif combined >= 0.50:
        return "MODERATE-HIGH - Core methodology established"
    elif combined >= 0.25:
        return "MODERATE - Key components in progress"
    else:
        return "LOW - Early development stage"


# =============================================================================
# REPORT GENERATION
# =============================================================================

def generate_feasibility_report() -> str:
    """Generate a text-based feasibility report"""

    report = []
    report.append("=" * 70)
    report.append("FEASIBILITY ASSESSMENT REPORT")
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("=" * 70)

    # Overall assessment
    overall = calculate_overall_feasibility()

    report.append("\n1. OVERALL ASSESSMENT")
    report.append("-" * 40)
    report.append(f"   Status: {overall['overall_assessment']}")

    report.append("\n2. DATA PRODUCT STATUS")
    report.append("-" * 40)
    dp = overall['data_products']
    report.append(f"   Complete:    {dp['complete']:3d} / {dp['total']}")
    report.append(f"   Downloading: {dp['downloading']:3d} / {dp['total']}")
    report.append(f"   Pending:     {dp['pending']:3d} / {dp['total']}")
    report.append(f"   Progress:    {dp['percent_complete']:.1f}%")

    report.append("\n3. SCIENCE OBJECTIVES STATUS")
    report.append("-" * 40)
    obj = overall['objectives']
    report.append(f"   Complete:    {obj['complete']:3d} / {obj['total']}")
    report.append(f"   In Progress: {obj['in_progress']:3d} / {obj['total']}")
    report.append(f"   Pending:     {obj['pending']:3d} / {obj['total']}")
    report.append(f"   Progress:    {obj['percent_complete']:.1f}%")

    report.append("\n4. FEASIBILITY DISTRIBUTION")
    report.append("-" * 40)
    fd = overall['feasibility_distribution']
    report.append(f"   HIGH:     {fd['HIGH']:3d} objectives")
    report.append(f"   MODERATE: {fd['MODERATE']:3d} objectives")
    report.append(f"   LOW:      {fd['LOW']:3d} objectives")

    report.append("\n5. CARBON PARAMETERS STATUS")
    report.append("-" * 40)
    cp = overall['carbon_parameters']
    report.append(f"   Complete:    {cp['complete']:3d} / {cp['total']}")
    report.append(f"   In Progress: {cp['in_progress']:3d} / {cp['total']}")
    report.append(f"   Pending:     {cp['pending']:3d} / {cp['total']}")
    report.append(f"   Progress:    {cp['percent_complete']:.1f}%")

    report.append("\n6. SCIENCE TRACEABILITY MATRIX SUMMARY")
    report.append("-" * 40)
    for obj in STM_OBJECTIVES:
        status_icon = {"complete": "✓", "in_progress": "~", "pending": " "}.get(obj.status, "?")
        report.append(f"   [{status_icon}] {obj.id}: {obj.description[:45]}...")
        report.append(f"       Feasibility: {obj.feasibility}")

    report.append("\n7. CARBON QUANTIFICATION PARAMETERS")
    report.append("-" * 40)
    for param in CARBON_PARAMETERS:
        status_icon = {"complete": "✓", "in_progress": "~", "pending": " "}.get(param.status, "?")
        report.append(f"   [{status_icon}] {param.symbol}: {param.name}")
        report.append(f"       Range: {param.value_range}, Source: {param.source}")

    report.append("\n8. RECOMMENDATIONS")
    report.append("-" * 40)
    report.append("   Immediate:")
    report.append("   • Complete GEDI L4A download and processing")
    report.append("   • Complete EMIT L2A download and spectral extraction")
    report.append("   Short-term:")
    report.append("   • Download Sentinel-2 time series")
    report.append("   • Generate wall-to-wall scarp probability map")
    report.append("   Medium-term:")
    report.append("   • Execute field validation campaign")
    report.append("   • Collect samples for lab analysis")

    report.append("\n" + "=" * 70)
    report.append("END OF REPORT")
    report.append("=" * 70)

    return "\n".join(report)


def save_assessment_json():
    """Save assessment data to JSON for programmatic access"""

    data = {
        "generated": datetime.now().isoformat(),
        "overall": calculate_overall_feasibility(),
        "objectives": [asdict(o) for o in STM_OBJECTIVES],
        "carbon_parameters": [asdict(p) for p in CARBON_PARAMETERS],
        "product_assessments": {
            name: assess_data_product_feasibility(name)
            for name in ["nasadem", "copernicus", "gedi_l4a", "emit_l2a", "sentinel2"]
        }
    }

    # Convert FeasibilityScore objects to dicts
    for name, assessment in data["product_assessments"].items():
        if "scores" in assessment:
            assessment["scores"] = [asdict(s) for s in assessment["scores"]]

    output_path = os.path.join(OUTPUT_DIR, "feasibility_assessment.json")
    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)

    print(f"Assessment saved to: {output_path}")
    return output_path


# =============================================================================
# MAIN
# =============================================================================

def main():
    """Run feasibility assessment"""

    print(generate_feasibility_report())

    # Save JSON
    save_assessment_json()

    # Summary
    overall = calculate_overall_feasibility()
    print(f"\nOverall project feasibility: {overall['overall_assessment']}")


if __name__ == "__main__":
    main()
