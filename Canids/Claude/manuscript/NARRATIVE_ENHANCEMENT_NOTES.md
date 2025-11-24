# Narrative Enhancement Notes for Manuscript
## Strategic Guide for Clarity and Concise Study Flow

**Date:** 2024-11-24
**Status:** Figure harmonization complete; ready for narrative refinement
**Next Phase:** Enhance manuscript clarity, conciseness, and logical flow

---

## Current Manuscript Status

### Completed Work

1. **Three main figures harmonized** (Figure 2, 3, 4)
   - Consistent aesthetics (13pt base text, 11pt axes)
   - Clean layouts with balanced white space
   - No text-heavy elements (captions in manuscript, not figures)
   - Optimized for both PDF (vector) and PNG (raster, 300 dpi)

2. **Manuscript structure drafted** (`manuscript/manuscript_main.Rmd`)
   - R Markdown format for flexible output (PDF, Word, HTML)
   - Integrated figure references with detailed captions
   - Preliminary results section text

3. **Exploratory thesis established**
   > "Here we identify genes under positive selection during dog breed formation and characterize their functional properties through enrichment analysis. Rather than testing specific hypotheses, we use an exploratory approach to identify patterns in the genomic data that can inform mechanistic understanding of domestication trait correlations."

### What Needs Enhancement

The manuscript currently has:
- Draft figure captions that are complete but may be too verbose
- Results sections that need tightening for conciseness
- Narrative transitions that could be smoother between sections
- Discussion that needs to emphasize exploratory insights more clearly

---

## Key Narrative Themes to Emphasize

### 1. Exploratory, Data-Driven Discovery (Not Hypothesis Testing)

**Current framing:** Generally good but could be reinforced throughout

**Enhancement opportunities:**
- Introduction: Frame study as "genomic exploration" or "pattern discovery"
- Methods: Emphasize "unbiased scanning" and "data-driven enrichment"
- Results: Use language like "emerged from the data," "revealed pattern," "unexpected discovery"
- Discussion: Highlight how exploratory approach enabled Wnt pathway discovery

**Avoid language suggesting:**
- "We hypothesized..." or "We tested whether..."
- "As predicted..." or "Confirming our expectations..."
- Instead use: "Exploratory analysis revealed..." "Data-driven discovery showed..."

### 2. Episodic Selection as Mechanism

**Current explanation:** Strong in Figure 3 caption but needs reinforcement

**Key biological insight:**
- ω < 1 with p ≈ 0 indicates **site-specific positive selection within constrained genes**
- This is NOT contradictory—it's the expected pattern for pleiotropic developmental genes
- Represents "constrained adaptation": morphological plasticity within functional constraints

**Enhancement opportunities:**
- Introduction: Briefly introduce episodic vs. gene-wide selection concepts
- Results (Figure 3): Emphasize biological interpretation immediately after presenting data
- Discussion: Dedicate a subsection to episodic selection as domestication mechanism
- Consider a conceptual diagram showing site-specific ω > 1 within gene-wide ω < 1

### 3. Convergence of Evidence

**Current framing:** Present in Figure 4 caption and discussion

**Critical pattern:**
- 4 of 6 Tier 1 genes are Wnt-associated (FZD3, FZD4, EDNRB, potentially GABRA3)
- Independent evidence lines (selection, relevance, tractability, literature) converge
- This convergence validates both the enrichment analysis AND the prioritization framework

**Enhancement opportunities:**
- Results (Figure 4): Highlight convergence as key finding, not just description
- Discussion: Frame convergence as "mutual validation" of complementary approaches
- Consider quantifying: "67% of Tier 1 genes connect to data-driven enrichment pattern"

---

## Section-by-Section Enhancement Roadmap

### Abstract

**Current status:** Placeholder "[To be completed]"

**Writing priorities:**
1. One sentence: Domestication genetic basis question
2. One sentence: Exploratory genomic approach + key methods (aBSREL, enrichment)
3. Two sentences: Main findings (selection widespread, Wnt enrichment with episodic pattern)
4. One sentence: Prioritization convergence on Wnt genes
5. One sentence: Biological implications (constrained adaptation mechanism)

**Target length:** 150-200 words

**Key phrases to include:**
- "exploratory genomic approach"
- "data-driven discovery"
- "episodic selection pattern"
- "convergence of independent evidence"

### Introduction

**Current status:** Thesis statement strong; needs expansion

**Enhancement priorities:**

1. **Opening paragraph (current research context):**
   - Domestication as model for rapid evolution
   - Dog breeds as replicated domestication "experiments"
   - Outstanding questions about genetic mechanisms

2. **Second paragraph (methodological context):**
   - Phylogenetic selection methods enable genome-wide scans
   - Enrichment analysis identifies functional patterns
   - Challenge: distinguishing genuine signals from noise

3. **Third paragraph (knowledge gaps):**
   - Prior work focused on specific candidate genes or pathways
   - Need for unbiased, exploratory approaches
   - Question: What functional patterns emerge from data-driven analysis?

4. **Fourth paragraph (study approach and rationale):**
   - **Keep current thesis statement** (this is excellent!)
   - Briefly mention three-part analytical workflow:
     - Genome-wide selection scan (unbiased discovery)
     - Functional enrichment (pattern identification)
     - Multi-criteria prioritization (convergent evidence)

**Target length:** 4 paragraphs, ~600-800 words total

**Conciseness tips:**
- Limit background review to essentials
- Avoid exhaustive literature review (save for discussion)
- Each paragraph = one clear idea
- Remove any "filler" sentences that don't advance the narrative

### Methods

**Current status:** Section headers only; needs content

**Writing priorities (in order):**

1. **Genome Data and Ortholog Identification**
   - Species used: Dog, Dingo, Fox (state rationale briefly)
   - Ensembl genome assemblies and versions
   - Ortholog identification approach (1:1:1 orthologs, filtering criteria)
   - Final gene count

2. **Selection Analysis**
   - aBSREL method brief description (cite Pond et al.)
   - Why aBSREL: detects episodic/site-specific selection
   - Parameters used
   - Statistical thresholds (p-value, FDR if applicable)

3. **Functional Enrichment Analysis**
   - GO enrichment: tools and databases used
   - Pathway enrichment: resources (KEGG, Reactome, etc.)
   - Multiple testing correction
   - Enrichment significance thresholds

4. **Gene Prioritization Framework**
   - Four criteria: selection, relevance, tractability, literature
   - Scoring system (0-5 scale for each, explain rationale)
   - Tier assignment thresholds (16 for Tier 1, 13 for Tier 2)
   - Validation of scoring through independent evidence convergence

**Conciseness strategy:**
- Standard methods: cite and briefly state
- Novel methods (prioritization): explain in detail
- Use subsections for clarity
- Include key parameter values in text, full details in supplements

### Results

**Current status:** Draft text with figure integration; needs tightening

**Enhancement roadmap:**

#### Results Section 1: Genome-wide Selection Pattern

**Current text:** Good structure, needs conciseness

**Revisions needed:**
1. Open with concrete numbers immediately: "aBSREL identified N genes under positive selection (p < 0.05, corrected) across X ortholog groups tested."
2. Cut "Key observations" bulleted list—integrate smoothly into narrative
3. Add specific quantitative details where placeholders exist ([N genes])
4. Emphasize exploratory framing: "unbiased genome scan" language

**Target length:** 2 paragraphs, ~200-250 words + Figure 2 caption

#### Results Section 2: Wnt Signaling Enrichment

**Current text:** Strong biological interpretation; could be more concise

**Revisions needed:**
1. Lead with discovery: "Functional enrichment analysis revealed unexpected over-representation of Wnt signaling genes..."
2. Quantify enrichment: "N Wnt pathway genes among M selected genes (fold enrichment = X, p = Y)"
3. Tighten "Biological interpretation" subsection:
   - Combine episodic selection explanation into 2-3 sentences
   - Add specific gene examples with ω values and p-values
   - Example: "FZD3 (ω = 0.67, p ≈ 0) exemplifies this pattern..."
4. Remove redundancy between text and caption

**Target length:** 2-3 paragraphs, ~250-300 words + Figure 3 caption

#### Results Section 3: Gene Prioritization

**Current text:** Good convergence emphasis; needs quantification

**Revisions needed:**
1. Lead with framework purpose: "To translate exploratory patterns into testable hypotheses..."
2. Quantify tier distribution: "337 genes evaluated, 6 Tier 1 (1.8%), 47 Tier 2 (13.9%), 284 Tier 3 (84.3%)"
3. Emphasize convergence statistically: "Notably, 4/6 (67%) Tier 1 genes belong to Wnt-associated pathways identified in exploratory enrichment (p = [calculate enrichment p-value])"
4. Tier 1 gene list: Consider moving detailed scores to table, keep only key highlights in text

**Target length:** 2-3 paragraphs, ~250-300 words + Figure 4 captions

**Total Results section target: ~700-850 words + 3 main figures**

### Discussion

**Current status:** Draft with good structure; needs expansion and refinement

**Enhancement roadmap:**

#### Discussion Section 1: Exploratory Approach Value

**Current text:** Good foundation

**Enhancements needed:**
1. Expand on "why exploratory worked": traditional candidate gene approaches might have missed Wnt enrichment
2. Contrast with hypothesis-driven studies: benefits and limitations of each
3. Acknowledge limitations: exploratory requires validation (hence prioritization)
4. Connect to broader trend in genomics: data-driven discovery vs. hypothesis testing

**Target length:** 2 paragraphs, ~250-300 words

#### Discussion Section 2: Episodic Selection Mechanism

**Current text:** Good concept, needs expansion

**Enhancements needed:**
1. Explain biological rationale for episodic selection in developmental genes
2. Connect to domestication syndrome literature: pleiotropic effects of development genes
3. Provide mechanistic speculation: which sites under selection? (regulatory, binding, etc.)
4. Compare to other domestication studies: is episodic selection common?
5. Broader implications: constrained adaptation as general evolutionary mechanism

**Target length:** 2-3 paragraphs, ~300-350 words

#### Discussion Section 3: Wnt Pathway in Domestication

**New section needed**

**Content priorities:**
1. Known roles of Wnt in morphological development
2. Specific traits that Wnt genes might influence: skull shape, ear positioning, coat color
3. Connect to domestic trait correlations: neural crest hypothesis
4. Prior evidence for Wnt in domestication (if any)
5. Why might Wnt be under selection in dog breeds specifically?

**Target length:** 2 paragraphs, ~250-300 words

#### Discussion Section 4: Prioritization Framework

**Current text:** Brief; needs expansion

**Enhancements needed:**
1. Justify multi-criteria approach: why not selection alone?
2. Discuss individual criteria contributions: which weighted most heavily?
3. Validation of framework: convergence on Wnt genes supports validity
4. Comparison to other prioritization approaches in literature
5. Generalizability: could this framework apply to other systems?

**Target length:** 1-2 paragraphs, ~200-250 words

#### Discussion Section 5: Future Directions

**Current text:** Placeholder

**Content priorities:**
1. Experimental validation of Tier 1 genes: functional assays, knockout/knockdown
2. Extend analysis: more species, more genes, finer-scale genomic resolution
3. Mechanistic studies: which sites under selection? What are functional effects?
4. Comparative domestication: do other domesticated species show similar patterns?
5. Clinical/breeding applications: can insights inform selective breeding or veterinary genetics?

**Target length:** 1-2 paragraphs, ~200-250 words

**Total Discussion target: ~1200-1450 words**

### Conclusions

**Current text:** Good summary of key findings

**Enhancements needed:**
1. More concise: current version is 6 lines, aim for 4-5
2. Emphasize take-home messages:
   - Exploratory genomics enables unexpected discoveries
   - Episodic selection = mechanism for constrained adaptation
   - Convergent evidence validates Wnt pathway importance
   - Framework provides validated targets for follow-up
3. End with forward-looking statement about experimental validation

**Target length:** Single paragraph, ~100-120 words

---

## Figure Captions: Conciseness Review

### Figure 2 Caption

**Current length:** ~85 words

**Assessment:** Good balance of detail and conciseness

**Minor revisions:**
- Consider shortening "(A)..." descriptions to single phrases
- Example: "(A) Functional category distribution of selected genes"
- Remove some redundancy: "showing" appears 4 times

**Target length:** ~70 words

### Figure 3 Caption

**Current length:** ~110 words

**Assessment:** Slightly verbose due to episodic selection explanation

**Revisions:**
- Shorten Panel B description: combine episodic selection explanation into 2 sentences instead of 3
- Remove "Points sized by significance, colored by ω magnitude"—evident from figure
- Simplify Panel C: "Functional categorization by selection strength and significance"

**Target length:** ~80-90 words

### Figure 4 Main Caption

**Current length:** ~155 words

**Assessment:** Too detailed—this reads like results text, not caption

**Revisions:**
- Cut "Score distributions show..." sentence—evident from figure
- Reduce Panel C description: "Tier 1 genes' scoring profiles showing Wnt pathway enrichment"
- Shorten Panel D: "Selection strength vs. total score by tier"
- Move interpretation to results text: "Note that high prioritization..." sentence should be in main text

**Target length:** ~100-120 words

### Figure 4 Heatmap Caption

**Current length:** ~70 words

**Assessment:** Good conciseness

**Minor revisions:**
- Clarify tier color code: "Tiers: red = 1, orange = 2, gray = 3"

**Target length:** ~65 words

---

## Writing Style Guidelines for Enhancement

### Conciseness Strategies

1. **Eliminate redundancy:**
   - ❌ "We identified genes showing selection..."
   - ✅ "We identified selected genes..."

2. **Use active voice:**
   - ❌ "Selection was detected in N genes..."
   - ✅ "aBSREL detected selection in N genes..."

3. **Avoid filler phrases:**
   - ❌ "It is interesting to note that..."
   - ❌ "The results clearly show that..."
   - ✅ "Wnt pathway genes show..."

4. **Combine related sentences:**
   - ❌ "We used aBSREL. aBSREL detects episodic selection."
   - ✅ "We used aBSREL to detect episodic selection."

5. **Prefer specific to general:**
   - ❌ "Multiple genes were found..."
   - ✅ "Six Tier 1 genes were identified..."

### Clarity Strategies

1. **Define terms on first use:**
   - "episodic selection" → "site-specific positive selection (episodic selection)"
   - ω → "ω (dN/dS ratio, where ω > 1 indicates positive selection)"

2. **Use parallel structure:**
   - Lists should have consistent grammatical form
   - Panel descriptions should follow same pattern

3. **Signpost transitions:**
   - Between sections: "Having established genomic landscape (Fig. 2), we next..."
   - Between paragraphs: "This pattern suggests..." "In contrast to..." "Building on this..."

4. **Avoid ambiguous pronouns:**
   - ❌ "This shows that selection is widespread"
   - ✅ "This pattern shows that selection is widespread"

5. **Quantify when possible:**
   - ❌ "Many genes showed selection..."
   - ✅ "N genes (X% of total) showed selection..."

### Narrative Flow Strategies

1. **Each paragraph should:**
   - Start with topic sentence (main idea)
   - Provide supporting evidence/details
   - End with transition or implication

2. **Logical progression within sections:**
   - General → Specific (e.g., "genome-wide pattern" → "Wnt genes")
   - Observation → Interpretation
   - Finding → Implication

3. **Connect figures to narrative:**
   - Reference figures when first relevant: "(Figure 2A)"
   - Explain what reader should observe: "Figure 3B shows that Wnt genes..."
   - Interpret after presenting: "This pattern indicates..."

4. **Results-Discussion balance:**
   - Results: What did we find? (factual, minimal interpretation)
   - Discussion: What does it mean? (interpretation, context, implications)
   - Avoid duplicating content

---

## Next Steps: Implementation Plan

### Phase 1: Manuscript Text Refinement (Priority)

**Week 1 tasks:**
1. ✅ Complete Abstract (draft)
2. ✅ Expand Introduction (integrate thesis into broader context)
3. ✅ Write Methods sections (prioritize novel prioritization framework)
4. ✅ Tighten Results sections (apply conciseness strategies)

**Week 2 tasks:**
5. ✅ Expand Discussion sections (add Wnt pathway subsection)
6. ✅ Refine Conclusions (make more punchy)
7. ✅ Shorten figure captions (especially Fig 4)
8. ✅ Proofread for consistency and flow

### Phase 2: Supplementary Materials

**Tasks:**
- Supplementary Table S1: Full list of selected genes with statistics
- Supplementary Table S2: GO enrichment results (top 50)
- Supplementary Table S3: Complete prioritization scores (all 337 genes)
- Supplementary Figure S1: Quality control metrics
- Supplementary Figure S2: Chromosome distribution
- Supplementary Figure S3: Additional pathway enrichments (non-Wnt)
- Supplementary Methods: Extended methods text with all parameters

### Phase 3: Technical Review

**Tasks:**
- Check all citations are properly formatted
- Verify statistical test details are complete
- Confirm data availability statements
- Review code availability (GitHub repo cleanup)
- Check figure resolution and quality
- Verify supplementary materials are referenced in main text

### Phase 4: Collaborator Review

**Prepare for collaborators:**
- Draft cover letter summarizing key findings
- Highlight specific feedback needed areas:
  - Biological interpretation of Wnt enrichment
  - Episodic selection mechanism explanation
  - Future experimental validation priorities
- Provide tracked-changes version for editing

---

## Key Questions to Address in Revision

### Scientific Questions

1. **Selection method details:**
   - Why aBSREL specifically? (episodic detection capability)
   - What about other methods (BUSTED, MEME, FUBAR)? Any comparisons?
   - How robust are results to method choice?

2. **Enrichment analysis:**
   - Multiple testing correction method? (Bonferroni, FDR?)
   - Background gene set? (all tested genes, or genome-wide?)
   - Other enriched pathways besides Wnt? (mention briefly in results, detail in supplements)

3. **Prioritization validation:**
   - How were criterion weights determined? (equal weighting, or data-driven?)
   - Sensitivity analysis: how do tier assignments change with different thresholds?
   - External validation: do Tier 1 genes match known domestication genes?

4. **Biological mechanisms:**
   - Which specific Wnt pathway components are selected? (receptors, ligands, downstream effectors?)
   - Canonical vs. non-canonical Wnt signaling?
   - Proposed connection to specific domestication traits?

### Writing/Presentation Questions

1. **Should Figure 4 heatmap be:**
   - Part of main figure 4? (currently separate)
   - Separate Figure 5?
   - Moved to supplementary materials?
   → **Recommendation:** Keep separate for flexibility; journal can decide placement

2. **Results vs. Discussion balance:**
   - Is episodic selection explanation (Fig 3) too much interpretation for Results?
   → **Recommendation:** Brief mechanistic explanation in Results (1-2 sentences), detailed discussion in Discussion

3. **Supplementary materials scope:**
   - How much detail to include? (full gene lists, all enrichments, etc.)
   - Balance between completeness and readability?
   → **Recommendation:** Include comprehensive tables but highlight key findings in main text

4. **Target journal considerations:**
   - Word limits? (check target journal)
   - Figure limits? (typically 4-6 for research articles)
   - Supplementary limits?
   → **Action:** Select 2-3 target journals and review author guidelines

---

## Long-term Narrative Enhancement Goals

### Beyond Current Manuscript

1. **Develop conceptual framework figure:**
   - Illustrate exploratory → enrichment → prioritization → validation workflow
   - Show how episodic selection works at sequence level
   - Visualize Wnt pathway's role in domestication traits
   → Consider for graphical abstract or Figure 1

2. **Create summary infographic:**
   - Key findings in visual format
   - For presentations and lay summaries
   - Show convergence of evidence on Wnt genes

3. **Write lay summary:**
   - For university press release
   - For grant proposals
   - For public engagement

4. **Plan follow-up studies:**
   - Experimental validation proposals (functional assays)
   - Computational extensions (more species, more genes)
   - Comparative domestication across species

---

## Success Metrics for Enhanced Manuscript

### Clarity Metrics

- [ ] Non-expert reader can understand main findings from abstract alone
- [ ] Each paragraph has clear topic sentence
- [ ] No ambiguous terminology (all terms defined on first use)
- [ ] Logical flow between sections (smooth transitions)
- [ ] Figures stand alone (captions provide sufficient context)

### Conciseness Metrics

- [ ] Abstract: 150-200 words
- [ ] Introduction: 600-800 words
- [ ] Methods: 800-1000 words
- [ ] Results: 700-850 words
- [ ] Discussion: 1200-1450 words
- [ ] Total main text: ~4000-4500 words (typical research article length)

### Narrative Coherence Metrics

- [ ] Thesis statement (exploratory approach) evident throughout
- [ ] Three main findings (selection landscape, Wnt enrichment, convergence) clearly emphasized
- [ ] Episodic selection mechanism explained consistently
- [ ] Convergence of evidence highlighted in multiple places
- [ ] Logical progression: unbiased discovery → functional pattern → validated targets

### Scientific Rigor Metrics

- [ ] All statistical tests properly described
- [ ] All parameters and thresholds justified
- [ ] Limitations acknowledged
- [ ] Alternative explanations considered
- [ ] Data and code availability stated

---

## Notes for Specific Enhancements

### Emphasizing Exploratory Nature

**Language to use throughout:**
- "exploratory genomic scan"
- "data-driven discovery"
- "unbiased functional enrichment"
- "patterns emerged from the data"
- "rather than testing specific hypotheses"

**Language to avoid:**
- "we hypothesized"
- "as expected"
- "confirming predictions"
- "to test whether"

### Explaining Episodic Selection Clearly

**Key points to hit:**
1. aBSREL detects site-specific (episodic) positive selection
2. Gene can have average ω < 1 but significant p-value if some sites have ω > 1
3. This is NOT contradictory—it's biologically meaningful
4. Pleiotropic developmental genes are expected to show this pattern
5. Allows morphological variation within functional constraints

**Helpful analogies:**
- "Like editing a few words in a book while keeping most of the story intact"
- "Constrained adaptation: change what's necessary, preserve what's essential"

### Highlighting Convergent Evidence

**Concrete examples:**
- "FZD3: Tier 1 (16.25 points) + Wnt enrichment (p < 0.001) + known Wnt receptor"
- "4/6 Tier 1 genes = Wnt associated (67% vs. ~5% expected by chance, p = X)"
- "Independent evidence lines converge on same biological pathway"

**Visual representation ideas:**
- Venn diagram: Selection ∩ Enrichment ∩ High Priority = 4 genes
- Network diagram: Tier 1 genes connected to Wnt pathway
- Table: Show all 4 criteria scores for top genes with Wnt annotation

---

## Final Checklist Before Submission

### Content Completeness

- [ ] All placeholders filled ([N genes], [To be completed], etc.)
- [ ] All figures referenced in text
- [ ] All supplementary materials referenced
- [ ] All citations formatted correctly
- [ ] Author contributions stated
- [ ] Acknowledgments complete
- [ ] Data/code availability statements included

### Narrative Quality

- [ ] Thesis statement clear and consistently reinforced
- [ ] Each section flows logically to next
- [ ] No contradictions or inconsistencies
- [ ] Technical terms defined on first use
- [ ] Appropriate level of detail (not too dense, not too superficial)

### Figure Integration

- [ ] Figures support narrative (not just descriptive)
- [ ] Captions are concise yet complete
- [ ] Panel labels match text references
- [ ] Figure quality suitable for publication (resolution, fonts, colors)
- [ ] Color schemes accessible (colorblind-friendly)

### Technical Accuracy

- [ ] All statistical tests appropriate for data
- [ ] All p-values reported with appropriate precision
- [ ] All gene names formatted correctly (italics for genes, regular for proteins)
- [ ] All acronyms defined
- [ ] All methods replicable from description

---

**Document Owner:** Isaac (PhD candidate)
**Last Updated:** 2024-11-24
**Next Review:** After Phase 1 manuscript drafting complete
**Version:** 1.0 - Initial strategic guide

