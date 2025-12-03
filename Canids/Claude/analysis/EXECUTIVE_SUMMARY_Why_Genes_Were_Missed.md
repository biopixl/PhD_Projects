# Executive Summary: Why Critical Genes Were Missed

## The Problem

Our alternative hypotheses analysis uncovered **4-5 high-significance genes** (p < 10⁻¹² to 10⁻¹⁶) that were excluded from top-tier candidates due to systematic biases in the prioritization system.

---

## Root Causes

### 1. **Confirmation Bias in Scoring System**

The "relevance score" criterion was **pre-tuned to favor specific pathways**:

| Gene | P-value | Category | Relevance Score | Why So Low? |
|------|---------|----------|----------------|-------------|
| **TFAP2B** | <10⁻¹⁶ | Neural crest TF | **0.25 / 5.0** | Not in Wnt/neurotransmitter lists |
| **PORCN** | <10⁻¹⁶ | Wnt secretion | **0.0 / 5.0** | Not in pathway database |
| **SLC6A4** | <10⁻¹⁶ | Serotonin transporter | 3.0 / 5.0 | Underweighted vs receptors |
| **LEF1** | <10⁻¹⁶ | Wnt transcription | 2.0 / 5.0 | Not in WNT enrichment |

**Result:** These genes scored 11.0-14.5 points (Tier 2-3) instead of ≥16 (Tier 1).

### 2. **Incomplete Pathway Databases**

The WNT enrichment used standard databases (KEGG, Reactome) that:
- Include **receptors** (FZD3, FZD4) ✓
- Include **signal transducers** (DVL3) ✓
- **MISS ligand processing enzymes** (PORCN) ✗
- **MISS transcription factors** (LEF1) ✗
- **MISS inhibitors** (WIF1) ✗

**Consequence:** Wnt pathway reported as 7 genes; should be **9-10 genes**.

### 3. **Hypotheses Not Tested**

We did not proactively search for:
- **Neural crest genes** (Wilkins' domestication syndrome hypothesis)
- **Craniofacial development genes**
- **Behavioral regulation genes beyond receptors**

These are **core domestication hypotheses** but were not in our initial query list.

---

## What We Missed

### **TFAP2B - Neural Crest Master Regulator**
- **p < 10⁻¹⁶, ω = 1.20**
- **#1 neural crest specification factor**
- Essential for neural crest cell fate determination
- Loss → craniofacial defects, pigmentation loss
- **Directly supports Wilkins (2014) neural crest hypothesis**

**Impact:** This is arguably the MOST important gene for domestication syndrome theory, yet it scored **13.25 (Tier 2)** because relevance score = 0.25.

### **SLC6A4 - Serotonin Transporter**
- **p < 10⁻¹⁶, ω = 1.12**
- **THE gene for anxiety/fear behavior in mammals**
- 5-HTTLPR polymorphism linked to human anxiety, dog temperament
- More important than HTR2B (serotonin receptor) for behavioral phenotypes

**Impact:** We found 3 neurotransmitter **receptors** in Tier 1, but missed the **transporter** that regulates serotonin availability.

### **FGFR2 - Craniofacial Growth Factor Receptor**
- **p = 8.7×10⁻¹², ω = 0.42**
- Mutations → craniosynostosis (premature skull fusion) in humans
- Central regulator of skull shape, snout length
- Explains breed-specific craniofacial diversity

**Impact:** Just missed Tier 1 (score 15.25 vs cutoff 16.0), but is critical for morphological variation.

### **LEF1 - Wnt Transcription Factor**
- **p < 10⁻¹⁶, ω = 0.52**
- TCF/LEF family: downstream effectors of Wnt signaling
- Not in WNT enrichment results despite being a core Wnt gene

**Impact:** Shows our Wnt pathway analysis was incomplete.

### **PORCN - Wnt Ligand Secretion Enzyme**
- **p < 10⁻¹⁶, ω = 0.69**
- **Required for ALL Wnt ligand function** (palmitoylation)
- Loss → complete loss of Wnt signaling (lethal)
- Received **relevance score = 0.0** because not in pathway database

**Impact:** Most critical Wnt gene (without it, no Wnt signaling) but scored Tier 3.

---

## Pattern Recognition: What This Tells Us

### Original Narrative (Biased):
- **4/6 Tier 1** = neurotransmitter receptors
- **2/6 Tier 1** = Wnt receptors
- **Conclusion:** "Domestication involves neurotransmitter and Wnt receptor dysregulation"

### Revised Narrative (Unbiased):
- **4/10 high-priority** = neurotransmitter signaling (receptors + transporter)
- **3/10 high-priority** = Wnt pathway (receptors + transcription + secretion)
- **1/10 high-priority** = neural crest specification (TFAP2B)
- **1/10 high-priority** = craniofacial development (FGFR2)
- **1/10 high-priority** = cardiovascular/neural crest (EDNRB)

**Conclusion:** "Domestication involves **distributed selection across multiple systems**: neurotransmitter signaling, developmental pathways (Wnt, FGF), neural crest specification, and craniofacial morphogenesis."

---

## Statistical Impact

### Wnt Pathway Enrichment
- **Original:** 7 genes, p = 0.0037 (11th ranked pathway)
- **Corrected:** 9-10 genes (add LEF1, PORCN, WIF1)
- **New p-value:** Need to re-calculate

### Category Distribution (281 significant genes)
| Category | N Genes | % of Total |
|----------|---------|------------|
| Neural Crest | 8 | 2.8% |
| Craniofacial | 4 | 1.4% |
| Behavior/Temperament | 3 | 1.1% |
| Pigmentation | 6 | 2.1% |
| Immune | 8 | 2.8% |
| Metabolism | 3 | 1.1% |
| Stress | 1 | 0.4% |
| Cardiovascular | 1 | 0.4% |
| **Uncategorized** | **246** | **87.5%** |

**Key insight:** Even with expanded categories, **88% of genes don't fit predefined hypotheses** → domestication is highly complex and polygenic.

---

## Lessons Learned

### For This Manuscript:
1. **Add caveat** about hypothesis-driven vs data-driven prioritization
2. **Acknowledge** TFAP2B, SLC6A4, FGFR2 in Results/Discussion
3. **Re-frame** from "Wnt pathway" to "multiple pathways"
4. **Emphasize** genetic complexity (88% uncategorized genes)

### For Future Studies:
1. **Use unbiased scoring** (e.g., p-value + ω only, no "relevance")
2. **Test alternative hypotheses proactively** before finalizing
3. **Combine multiple pathway databases** (KEGG + Reactome + GO + manual curation)
4. **Validate pathways manually** (don't trust automated annotations)

---

## Recommended Actions

### Immediate (for this manuscript):

1. ✅ **Document the issue** (this file)
2. ⬜ **Update Results section:**
   - Mention TFAP2B, SLC6A4, FGFR2 as "high-significance candidates"
   - Note they narrowly missed Tier 1 due to scoring system
3. ⬜ **Add Discussion subsection:**
   - "Multiple Biological Pathways in Domestication"
   - Acknowledge limitations of pathway databases
   - Emphasize genetic complexity
4. ⬜ **Revise Abstract/Conclusion:**
   - Change from "Wnt pathway" to "multiple pathways"
   - Mention neural crest, neurotransmitters, craniofacial development

### Secondary:

5. ⬜ **Create Supplementary Table:**
   - All categorized genes (neural crest, craniofacial, behavior, immune, etc.)
6. ⬜ **Update Figure 4 Panel B:**
   - Add or highlight TFAP2B, SLC6A4, FGFR2
   - Use functional category color coding
7. ⬜ **Re-calculate Wnt enrichment:**
   - Include LEF1, PORCN, WIF1
   - Report corrected p-value

### For Follow-up Paper:

8. ⬜ **Deep dive on TFAP2B:**
   - Literature review on neural crest and domestication
   - Expression analysis in dog tissues
   - Comparison to fox domestication experiment
9. ⬜ **Validate SLC6A4 polymorphisms:**
   - Sequence SLC6A4 across breeds
   - Correlate with temperament scores
10. ⬜ **Comprehensive pathway analysis:**
    - All significant genes (430)
    - Multiple databases (KEGG, Reactome, GO, WikiPathways)
    - Manual curation of pathway assignments

---

## Key Messages

### What Went Wrong:
✗ Pre-tuned scoring system favored hypothesis-confirming genes
✗ Standard pathway databases are incomplete
✗ Did not test alternative hypotheses proactively

### What We Learned:
✓ TFAP2B (neural crest) is a major discovery
✓ SLC6A4 (behavior) strengthens neurotransmitter theme
✓ Wnt pathway larger than initially recognized (9-10 genes)
✓ Multiple pathways involved, not just Wnt
✓ 88% of genes are uncategorized → extreme genetic complexity

### Revised Take-Home Message:
> **"Domestication in dogs involved distributed selection across multiple biological systems—neurotransmitter signaling (GABRA3, HTR2B, HCRTR1, SLC6A4), developmental pathways (Wnt: FZD3/4, LEF1, PORCN; FGF: FGFR2, FGF18), neural crest specification (TFAP2B), and craniofacial morphogenesis—rather than disruption of a single master pathway. This polygenic architecture reflects the complexity of domestication syndrome."**

---

## Bottom Line

We **did not fail** to find these genes—they were **genome-wide significant** (p < 10⁻¹⁶).

We **failed to recognize their importance** due to:
1. Hypothesis-driven scoring that favored pre-selected pathways
2. Incomplete pathway annotations
3. Not testing alternative hypotheses

**Solution:** Revise narrative to emphasize **multiple pathways** and **genetic complexity**, acknowledge limitations of automated prioritization, and highlight TFAP2B (neural crest), SLC6A4 (behavior), and FGFR2 (craniofacial) as key discoveries.

This is a **correctable bias**, not a fundamental flaw in the analysis. The data are sound; the interpretation needs refinement.
