# Pb XRF Field Screening Protocol

## Purpose
Rapid triage of ash samples for lead contamination following wildfire events.

## Method Parameters
- Instrument: Portable XRF (pellet preparation)
- Matrix: Fire ash
- LOD: 197 ppm
- LOQ: 657 ppm
- Calibration: Ash-matrix validated against ICP-MS

## Decision Thresholds

| XRF Reading | Priority | Action |
|-------------|----------|--------|
| < 197 ppm | LOW | Below detection, no immediate action |
| 197-300 ppm | MEDIUM-LOW | Lab confirmation optional |
| 300-400 ppm | MEDIUM | Lab confirmation advised |
| > 400 ppm | HIGH | Exceeds EPA residential RSL |
| > 800 ppm | CRITICAL | Exceeds EPA industrial RSL |

## Performance Characteristics

| Threshold | Sensitivity | Specificity | FNR |
|-----------|-------------|-------------|-----|
| CA DTSC Residential (80 ppm) | 55% | 100% | 45% |
| CA DTSC Commercial (320 ppm) | 50% | 100% | 50% |
| EPA RSL Residential (400 ppm) | 50% | 100% | 50% |
| EPA RSL Industrial (800 ppm) | 33% | 100% | 67% |

## Limitations
1. XRF shows conservative bias (underestimates Pb in ash)
2. Cannot reliably screen for CA DTSC residential (80 ppm) due to LOD
3. High-Pb samples (>1000 ppm) extrapolate beyond calibration range
4. Matrix effects vary with ash composition

## Quality Assurance
- Run PBP calibration check at start of each session
- Include field blank and duplicate every 10 samples
- Confirm high-priority samples with ICP-MS
