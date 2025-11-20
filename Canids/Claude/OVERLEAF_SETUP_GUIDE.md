# Overleaf Setup Guide
**Date:** November 19, 2025
**Status:** GitHub synced to Overleaf - Ready to compile

---

## ✅ Your Overleaf Project is Ready!

Your GitHub repository is now synced with Overleaf. I've created the LaTeX structure for compilation.

---

## Quick Start (3 Steps)

### Step 1: Open Overleaf Project
1. Go to your Overleaf project that's linked to GitHub
2. The files should automatically sync from GitHub
3. Main compilation file: **main.tex**

### Step 2: Compile the Document
1. In Overleaf, set **main.tex** as the main document
   - Click "Menu" (top left)
   - Under "Main document" select **main.tex**
2. Click "Recompile" button
3. PDF should generate with abstract, introduction, and placeholders for full content

### Step 3: Add Full Content
The main.tex currently has placeholders. You need to add full text from revised sections:
- Copy from **ABSTRACT_INTRODUCTION_REVISED.md**
- Copy from **RESULTS_REVISED.md**
- Copy from **DISCUSSION_REVISED.md**
- Copy from **CONCLUSIONS_REVISED.md**

---

## File Structure in Overleaf

```
Claude/ (your project root)
├── main.tex                           ← Main LaTeX document (COMPILES HERE)
├── references.bib                     ← BibTeX bibliography (citations)
├── manuscript/
│   └── figures/
│       ├── Figure1_StudyDesign.pdf
│       ├── Figure2_SelectionResults.pdf
│       ├── Figure3_WntEnrichment.pdf
│       └── Figure4_GenePrioritization.pdf (pending)
├── ABSTRACT_INTRODUCTION_REVISED.md   ← Source content to copy
├── RESULTS_REVISED.md                 ← Source content to copy
├── DISCUSSION_REVISED.md              ← Source content to copy
├── CONCLUSIONS_REVISED.md             ← Source content to copy
└── COMPREHENSIVE_REFERENCE_LIST.md    ← Additional refs if needed
```

---

## How to Edit in Overleaf

### Adding Content from Revised Sections

**Option A: Copy-Paste (Simplest)**

1. Open **ABSTRACT_INTRODUCTION_REVISED.md** in Overleaf (or GitHub)
2. Copy the text (Markdown format)
3. Paste into **main.tex** in the appropriate section
4. Add LaTeX formatting:
   - Italicize species names: `\textit{Canis lupus familiaris}`
   - Format citations: `\citep{Cairns2022}` or `\citet{Wilkins2014}`
   - Format p-values: `\textit{p}=0.041`
   - Format gene names: `\textit{EDNRB}`

**Option B: Use Pandoc (Automatic Conversion)**

If you have Pandoc locally:
```bash
cd /Users/isaac/Documents/GitHub/PhD_Projects/Canids/Claude
pandoc ABSTRACT_INTRODUCTION_REVISED.md -o sections/introduction.tex
pandoc RESULTS_REVISED.md -o sections/results.tex
pandoc DISCUSSION_REVISED.md -o sections/discussion.tex
pandoc CONCLUSIONS_REVISED.md -o sections/conclusions.tex
```

Then in main.tex, replace placeholders with:
```latex
\section{Introduction}
\input{sections/introduction.tex}

\section{Results}
\input{sections/results.tex}

\section{Discussion}
\input{sections/discussion.tex}

\section{Conclusions}
\input{sections/conclusions.tex}
```

---

## Formatting Guide

### Species Names (Italicized)
```latex
\textit{Canis lupus familiaris}  % Dog
\textit{Canis lupus dingo}       % Dingo
\textit{Vulpes vulpes}           % Fox
```

### Gene Names (Italicized)
```latex
\textit{EDNRB}
\textit{GABRA3}
\textit{FZD3}
```

### Citations

**In-text citation (author-year):**
```latex
\citet{Wilkins2014} proposed...        % Wilkins et al. (2014) proposed...
Recent work \citep{Cairns2022}...      % Recent work (Cairns et al. 2022)...
Multiple \citep{Ostrander2024,Meadows2023}  % (Ostrander 2024; Meadows 2023)
```

**For numbered citations (Nature/PLOS style):**
```latex
\cite{Wilkins2014}                     % [1]
\cite{Cairns2022,Ostrander2024}        % [2,3]
```

### P-values and Statistics
```latex
\textit{p}=0.041                       % p-value
\textit{p}$<$1$\times$10$^{-10}$      % p < 1×10^-10
$\alpha$=2.93$\times$10$^{-6}$        % α = 2.93×10^-6
$\omega$ (dN/dS ratio)                 % omega
```

### GO Terms
```latex
GO:0016055 (Wnt signaling pathway)
FDR$<$0.05                             % FDR < 0.05
```

---

## Citation Management

### Using references.bib

Your **references.bib** file contains 30+ core citations. To add more:

1. Open **references.bib** in Overleaf
2. Add new BibTeX entries from COMPREHENSIVE_REFERENCE_LIST.md
3. Format:
```bibtex
@article{AuthorYear,
  author = {LastName, FirstName and others},
  title = {Full title},
  journal = {Journal Name},
  year = {2024},
  volume = {10},
  pages = {1--20},
  doi = {10.xxxx/xxxxx}
}
```

### Citation Style Options

**For Nature Communications / PLOS Genetics (Numbered):**
```latex
\bibliographystyle{naturemag}  % or vancouver, plos
```

**For Molecular Biology and Evolution (Author-Year):**
```latex
\bibliographystyle{apalike}    % or plainnat
```

---

## Figures

### Current Status
- ✅ Figure 1: Study Design (PDF available)
- ✅ Figure 2: Selection Results (PDF available)
- ✅ Figure 3: Wnt Enrichment (PDF available)
- ⏸️ Figure 4: Gene Prioritization (data ready, heatmap pending)

### Including Figures

Figures are already included in main.tex:
```latex
\begin{figure}[h]
\centering
\includegraphics[width=0.9\textwidth]{manuscript/figures/Figure1_StudyDesign.pdf}
\caption{\textbf{Study Design.} Description...}
\label{fig:studydesign}
\end{figure}
```

### If Figures Don't Appear
1. Check that `manuscript/figures/` folder exists in Overleaf
2. Upload PDFs manually if needed (drag-and-drop in Overleaf)
3. Verify file paths match exactly

---

## Common LaTeX Commands

### Sections
```latex
\section{Introduction}          % Main section
\subsection{Background}          % Subsection
\subsubsection{Details}          % Subsubsection
```

### Text Formatting
```latex
\textbf{Bold text}
\textit{Italic text}
\underline{Underlined}
```

### Lists
```latex
% Bulleted list
\begin{itemize}
  \item First item
  \item Second item
\end{itemize}

% Numbered list
\begin{enumerate}
  \item First
  \item Second
\end{enumerate}
```

### Math Mode
```latex
$\alpha$, $\beta$, $\omega$      % Greek letters
$\times$                          % multiplication sign
$<$, $>$                          % less/greater than
$^{-10}$                          % superscript
$_{subscript}$                    % subscript
```

---

## Compilation Options

### Line Numbers (For Review)
Currently enabled. To disable:
```latex
%\linenumbers  % Comment out this line
```

### Spacing (For Review vs Final)
Currently: 1.5 spacing
```latex
\onehalfspacing    % 1.5 spacing
\doublespacing     % Double spacing (for review)
\singlespacing     % Single spacing (for final)
```

### Journal Templates

To use specific journal templates:

**Nature Communications:**
```latex
\documentclass{nature}
% Download nature.cls from journal website
% Upload to Overleaf
```

**PLOS Genetics:**
```latex
\documentclass{plos}
% Download plos.cls from journal website
```

**Current Setup:**
Generic article class that works for all journals. Format to specific journal style before final submission.

---

## Troubleshooting

### "Cannot find references.bib"
- Ensure references.bib is in the same directory as main.tex
- In Overleaf, check file is uploaded and synced

### "Cannot find figure files"
- Upload PDFs manually to `manuscript/figures/` folder in Overleaf
- Or commit to GitHub and let sync update

### "Undefined control sequence"
- Check for special characters that need escaping: `_`, `%`, `&`, `#`
- Use `\_`, `\%`, `\&`, `\#`

### "Citation undefined"
- Run compilation twice (first pass creates .aux, second resolves citations)
- Verify citation key matches references.bib exactly (case-sensitive)

### "Package xxx not found"
- Most packages are pre-installed in Overleaf
- Check Menu → TeX Live version (use latest)

---

## GitHub ↔ Overleaf Sync

### Pushing Changes to GitHub
1. Edit in Overleaf
2. Click "Menu" → "GitHub" → "Push Overleaf changes to GitHub"
3. Add commit message
4. Push

### Pulling Changes from GitHub
1. Edit files in GitHub (or locally with git push)
2. In Overleaf: "Menu" → "GitHub" → "Pull GitHub changes to Overleaf"
3. Files update automatically

### Best Practices
- **Edit in one place at a time** to avoid conflicts
- **Use Overleaf for text editing** (nice interface)
- **Use GitHub/local for code, figures, data**
- **Commit frequently** with descriptive messages

---

## Next Steps

### Immediate (To Get Compiling Document):

1. **Open Overleaf project**
2. **Verify main.tex compiles** (should produce PDF with placeholders)
3. **Copy content from revised .md files** into main.tex sections
4. **Add LaTeX formatting** (italics, citations, math)
5. **Recompile** to see full manuscript

### Medium-Term (For Submission):

1. **Choose target journal** (Nature Communications, PLOS, MBE)
2. **Download journal LaTeX template** and replace main.tex
3. **Format citations** to journal style (numbered or author-year)
4. **Finalize Figure 4** (debug heatmap or create manually)
5. **Convert supplementary tables** to Excel format
6. **Proofread entire manuscript**

### Final Submission:

1. **Generate final PDF** from Overleaf
2. **Download source files** (LaTeX + figures) as ZIP
3. **Prepare supplementary materials** (tables, figures)
4. **Write cover letter**
5. **Submit to journal online portal**

---

## Tips for Overleaf Editing

### Keyboard Shortcuts
- **Ctrl/Cmd + Enter**: Recompile
- **Ctrl/Cmd + F**: Find
- **Ctrl/Cmd + /** : Comment line
- **Ctrl/Cmd + /** : Uncomment line

### Split View
- Use split screen: LaTeX source (left) + PDF preview (right)
- Click on PDF to jump to source line

### Track Changes (For Collaborators)
- Menu → Review → Turn on Track Changes
- Shows edits with color highlighting
- Accept/reject changes before final compile

### Comments
```latex
% This is a comment
\textcolor{red}{TODO: Add more detail here}
```

---

## Summary

**✅ What's Ready:**
- main.tex (compiles with placeholders)
- references.bib (30+ citations)
- Figures 1-3 (PDFs ready)
- Revised content in .md files

**⏸️ What You Need to Do:**
1. Copy revised .md content into main.tex
2. Add LaTeX formatting (italics, citations)
3. Verify compilation
4. Continue editing in Overleaf's nice interface!

**📧 If you have issues:**
- Check Overleaf documentation: https://www.overleaf.com/learn
- LaTeX help: https://www.overleaf.com/learn/latex/Main_Page
- BibTeX help: https://www.overleaf.com/learn/latex/Bibliography_management_with_bibtex

---

**Your manuscript is now ready for collaborative editing in Overleaf with proper GitHub version control! 🎉**
