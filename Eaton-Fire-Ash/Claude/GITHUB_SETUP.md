# GitHub Repository Setup Guide

## Current Status

The Eaton-Fire-Ash project is currently located at:
```
/Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Claude/
```

It is a subdirectory of the `PhD_Projects` repository:
- **Remote**: `git@github.com:biopixl/PhD_Projects.git`
- **Branch**: `main`

## Options for Repository Organization

### Option A: Keep as Subdirectory (Current)

**Pros:**
- No changes needed to current structure
- All PhD projects in one place
- Simple management

**Cons:**
- Large repository with mixed projects
- Cannot have project-specific collaborators easily
- Harder to cite/share individual projects

**To commit current changes:**
```bash
cd /Users/isaac/Documents/GitHub/PhD_Projects
git add Eaton-Fire-Ash/Claude/
git commit -m "Add Eaton Fire ash geochemical analysis

- ICP-MS characterization of trace metals
- XRF validation and correction models
- Spectral proxy comparison (FTIR, ASD)
- Mineral classification framework

🤖 Generated with Claude Code"
git push origin main
```

### Option B: Create Standalone Repository (Recommended for Publication)

**Pros:**
- Clean, focused repository for manuscript
- Easy to share/cite with DOI (Zenodo)
- Independent version history
- Can add project-specific collaborators

**Cons:**
- Requires repository creation
- Need to manage separately

**Steps:**

1. **Create new repository on GitHub:**
   - Go to https://github.com/new
   - Repository name: `Eaton-Fire-Ash` or `wui-ash-geochemistry`
   - Description: "Multi-modal geochemical characterization of WUI fire ash"
   - Public or Private (your choice)
   - Do NOT initialize with README (we have one)

2. **Initialize and push:**
```bash
cd /Users/isaac/Documents/GitHub/PhD_Projects/Eaton-Fire-Ash/Claude

# Initialize new git repo (removes connection to PhD_Projects)
rm -rf .git  # Only if you want to disconnect from parent
git init
git add .
git commit -m "Initial commit: Eaton Fire ash geochemical analysis

Multi-modal characterization of WUI fire ash:
- ICP-MS elemental concentrations
- XRF field proxy validation
- FTIR/ASD spectroscopic analysis
- Mineral classification

🤖 Generated with Claude Code"

# Connect to new remote
git remote add origin git@github.com:biopixl/Eaton-Fire-Ash.git
git branch -M main
git push -u origin main
```

### Option C: Git Subtree/Submodule

Keep in PhD_Projects but also maintain as separate repo using git subtree or submodule.

**Not recommended** - adds complexity without significant benefits.

---

## Recommended Approach

For a **publication-ready** project:

1. **Create standalone repository** (Option B)
2. **Add Zenodo integration** for DOI
3. **Create release** when manuscript is submitted

For **ongoing development**:

1. **Keep in PhD_Projects** (Option A)
2. **Create standalone repo later** when ready to publish

---

## Files Ready for Commit

### Core Files
- [x] `README.md` - Project overview
- [x] `LICENSE` - MIT License
- [x] `.gitignore` - Ignore patterns
- [x] `MANUSCRIPT_ROADMAP.md` - Implementation guide
- [x] `SATM_REVISED.md` - Analysis framework

### Scripts (17 files)
- [x] `scripts/01_data_harmonization.R`
- [x] `scripts/02_spectral_processing.R`
- [x] ... (all 17 scripts)

### Data (processed outputs)
- [x] `data/df_master_aviris.csv`
- [x] `data/table*.csv` (analysis outputs)
- [x] `data/*.csv` (processed data)

### Figures
- [x] `figures/Fig*.pdf`
- [x] `figures/Fig*.png`

### Documentation
- [x] `docs/ANALYTICAL_FRAMEWORK.md`
- [x] `docs/ANALYSIS_SUMMARY.md`
- [x] `docs/MANUSCRIPT_PROPOSAL.md`

---

## Quick Start Commands

### To add to existing PhD_Projects repo:
```bash
cd /Users/isaac/Documents/GitHub/PhD_Projects
git add Eaton-Fire-Ash/
git commit -m "Add Eaton Fire ash analysis project"
git push
```

### To create new standalone repo:
```bash
# First create repo on GitHub, then:
cd /Users/isaac/Documents/GitHub/
cp -r PhD_Projects/Eaton-Fire-Ash/Claude Eaton-Fire-Ash-Standalone
cd Eaton-Fire-Ash-Standalone
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:biopixl/Eaton-Fire-Ash.git
git push -u origin main
```

---

*Setup guide created: December 4, 2025*
