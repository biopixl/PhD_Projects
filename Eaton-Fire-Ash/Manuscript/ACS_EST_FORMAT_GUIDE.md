# ACS Environmental Science & Technology (ES&T) Formatting Guide

## Quick Reference

| Element | Requirement |
|---------|------------|
| **Word limit** | 7,000 words (abstract through main text) |
| **Abstract** | 150-200 words |
| **Synopsis** | ~20 words after abstract (environmental significance) |
| **Keywords** | 5-8 keywords |
| **Figures** | 1-4 panels max per figure |
| **References** | Superscript numbers, include article titles |

---

## Manuscript Structure (Required Order)

1. **Title** - Concise, informative
2. **Author names and affiliations**
3. **Abstract** (150-200 words)
4. **Synopsis statement** (~20 words, environmental relevance)
5. **Keywords** (5-8)
6. **Introduction**
7. **Materials and Methods** (or Experimental Section)
8. **Results and Discussion** (combined - NO separate Conclusion section!)
9. **Associated Content** (Supporting Information description)
10. **Author Information** (corresponding author, ORCID, contributions)
11. **Acknowledgments**
12. **References**

### Important: NO Conclusion Section!
ES&T explicitly prohibits separate Conclusion/Summary sections. Concluding remarks must be incorporated into Results and Discussion.

---

## Figure Requirements

### Resolution
- Line art: **1200 dpi minimum**
- Grayscale: **600 dpi minimum**
- Color: **300 dpi minimum**

### Size
- Single column: up to 3.33 inches (240 pt)
- Double column: 4.2-7 inches (300-504 pt)
- Maximum depth: 660 pt including caption

### Formatting
- Maximum **4 panels** per figure (closely related)
- Text minimum **4.5 pt** in final format
- Embed in text at point of relevance for submission
- Label sequentially (Figure 1, Figure 2, etc.)

---

## Table Requirements

- Brief title (one phrase/sentence) that stands alone
- Details in footnotes, not title
- Avoid merged/split cells
- Number sequentially (Table 1, Table 2, etc.)

---

## Reference Format

References are numbered consecutively as superscript numerals in order of appearance.

Example format:
```
(1) Author, A. B.; Author, C. D. Article Title. Journal Abbrev. Year, Volume, Pages. DOI
```

**Important**: Article titles ARE required in ES&T references.

---

## Supporting Information

- Submit as separate file(s) simultaneously
- Provide brief description of contents
- Label figures as Figure S1, S2, etc.
- Label tables as Table S1, S2, etc.

---

## LaTeX Setup for Overleaf

### Document Class
```latex
\documentclass[
  journal=esthag,        % ES&T journal code
  manuscript=article,    % or communication, letter
  layout=twocolumn
]{achemso}
```

### Required Packages
```latex
\usepackage[version=4]{mhchem}  % Chemical formulas
\usepackage{siunitx}            % SI units
\usepackage{graphicx}           % Figures
\usepackage{booktabs}           % Professional tables
```

### File Organization in Overleaf
```
project/
├── main.tex                 # Main manuscript
├── supporting_info.tex      # SI document
├── references.bib           # Bibliography
├── figures/
│   ├── Figure1.png
│   ├── Figure2.png
│   └── ...
└── tables/
    └── (optional, can embed in .tex)
```

---

## Checklist Before Submission

- [ ] Word count ≤7,000 (abstract through main text)
- [ ] Abstract 150-200 words
- [ ] Synopsis statement included (~20 words)
- [ ] 5-8 keywords provided
- [ ] No Conclusion section (merged into Results and Discussion)
- [ ] Figures ≤4 panels each, properly labeled
- [ ] Figure resolution meets requirements
- [ ] Tables have brief standalone titles
- [ ] References include article titles
- [ ] Supporting Information prepared as separate file
- [ ] TOC graphic prepared (required)

---

## Sources

- [ES&T Author Guidelines](https://pubs.acs.org/page/esthag/submission/authors.html)
- [ACS LaTeX Guidelines](https://pubs.acs.org/page/4authors/submission/tex.html)
- [Overleaf ACS Template](https://www.overleaf.com/latex/templates/latex-template-for-american-chemical-society-acs-journal-submissions/nzngbcrcptmm)
- [achemso Package Documentation](https://ctan.org/pkg/achemso)
