# Master Planning Document

## CICRA Flood-Buried Forest Carbon Pilot Study

This directory contains the master LaTeX planning document for the remote sensing detection of flood-buried forest deposits project.

## Document Structure

- `main.tex` - Master planning document containing:
  - Section 1: Motivation and Knowledge Gaps (NASA Decadal Survey & National Academies alignment)
  - Section 2: Study Area and Sampling Design
  - Section 3: Variables of Interest (complete definitions with units)
  - Section 4: Data Products and Platform Comparison
  - Section 5: Prediction Models by Platform (5 alternative models)
  - Section 6: Science Traceability Matrix
  - Section 7: Data Product Status and Tracking
  - Section 8: Validation Plan
  - Section 9: Timeline and Milestones
  - Section 10: Expert Review Notes (for comments)

## Overleaf Integration

### Option 1: GitHub Sync (Recommended)

1. Push this directory to GitHub
2. In Overleaf: New Project → Import from GitHub
3. Select the repository and this directory
4. Changes sync bidirectionally

### Option 2: Direct Upload

1. Create new project in Overleaf
2. Upload `main.tex` and any figures
3. Compile with pdfLaTeX

## Compilation

### Local compilation:
```bash
cd manuscript
pdflatex main.tex
pdflatex main.tex  # Run twice for TOC
```

### Overleaf:
- Compiler: pdfLaTeX
- Main document: main.tex

## Adding Figures

Place figures in a `figures/` subdirectory:
```
manuscript/
├── main.tex
├── figures/
│   ├── Fig1_study_area.png
│   └── ...
└── README.md
```

Reference in LaTeX:
```latex
\includegraphics[width=\textwidth]{figures/Fig1_study_area.png}
```

## Expert Review

The document includes Section 10 for expert comments. Reviewers can:
1. Add comments directly in the PDF
2. Edit the LaTeX source
3. Use Overleaf's track changes feature

## Version Control

This document consolidates:
- Previous TRACKING.md
- Previous FEASIBILITY_ANALYSIS.md
- Previous DECADAL_ALIGNMENT.md
- Previous manuscript_proposal.md

All content is now in a single, structured LaTeX document suitable for collaborative revision.
