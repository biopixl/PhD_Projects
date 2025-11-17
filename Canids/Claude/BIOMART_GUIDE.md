# Ensembl BioMart Ortholog Download Guide

**Step-by-step instructions for downloading Canidae ortholog data**

---

## Quick Overview

We need to download a table of orthologous genes across Canidae species from Ensembl BioMart. This table tells us which genes in different species are evolutionary equivalents (orthologs).

**Time required:** 10-15 minutes
**URL:** https://www.ensembl.org/biomart/martview

---

## Step 1: Access BioMart

1. Go to: **https://www.ensembl.org/biomart/martview**
2. You should see the BioMart query interface

---

## Step 2: Choose Database and Dataset

1. **CHOOSE DATABASE:**
   - Select: **Ensembl Genes 111** (or latest version)

2. **CHOOSE DATASET:**
   - Select: **Dog genes (UU_Cfam_GSD_1.0)** or **Canis lupus familiaris genes**

   *This sets dog as our reference species - all other species will be compared to dog genes*

---

## Step 3: Set Filters (Optional but Recommended)

Click **Filters** in the left sidebar

1. Expand **GENE:**
   - Check: **Gene type**
   - Select: `protein_coding` (this filters to only protein-coding genes)

This reduces the dataset to ~20,000-25,000 genes instead of all genes.

---

## Step 4: Select Attributes (IMPORTANT)

Click **Attributes** in the left sidebar

### Gene Information (from Dog)

1. Expand **GENE:**
   - ✅ Gene stable ID
   - ✅ Gene name
   - ✅ Transcript stable ID
   - ✅ Protein stable ID
   - ✅ Chromosome/scaffold name
   - ✅ Gene start (bp)
   - ✅ Gene end (bp)

### Ortholog Information for Each Species

For **EACH** of the following species, you need to add ortholog attributes:

**Available Canidae species in Ensembl (as of 2024):**
- Wolf (Canis lupus)
- Red fox (Vulpes vulpes)
- Arctic fox (Vulpes lagopus)

**For EACH species:**

1. Expand **ORTHOLOGUES [Species name]** (e.g., "ORTHOLOGUES (Wolf genes)")

2. Select these attributes:
   - ✅ [Species] Gene stable ID
   - ✅ [Species] Protein stable ID
   - ✅ [Species] orthology type
   - ✅ %id target [Species] gene identical to query gene (optional but useful)
   - ✅ [Species] gene name (if available)

**Repeat for:**
- Wolf orthologues
- Red fox orthologues
- Arctic fox orthologues

**Note:** Unfortunately, many Canidae species (African wild dog, dhole, coyote) are NOT in Ensembl, so we'll only get dog-wolf-fox orthologs from BioMart. That's okay - we'll use other methods for additional species.

---

## Step 5: Preview and Count

1. Click **Count** button (top of page)
   - Should show ~20,000-25,000 genes if you filtered to protein-coding

2. Click **Results** button (top of page)
   - Preview first 10 rows to verify your selection looks correct

---

## Step 6: Export Results

1. In the **Results** section:
   - **Export:** Select **TSV** (tab-separated values)
   - **Unique results only:** ✅ Check this box (very important!)
   - **Compressed file (.gz):** Your choice (uncompressed is easier)

2. Click **Go** button

3. Download will start - save as:
   ```
   ensembl_canidae_orthologs.tsv
   ```

4. Move to your project directory:
   ```bash
   mv ~/Downloads/ensembl_canidae_orthologs.tsv \
      data/orthologs/ensembl_compara_table.tsv
   ```

---

## Step 7: Verify Download

Check the file was downloaded correctly:

```bash
# Check file exists and size
ls -lh data/orthologs/ensembl_compara_table.tsv

# Look at first few lines
head -5 data/orthologs/ensembl_compara_table.tsv

# Count rows (should be 20,000-25,000)
wc -l data/orthologs/ensembl_compara_table.tsv
```

Expected output:
- File size: 5-20 MB
- Number of lines: 20,000-25,000 (plus header)
- Columns: Should have gene IDs, names, and ortholog information

---

## Alternative: Minimal Quick Version

If you just want to test the pipeline quickly:

1. Database: **Ensembl Genes 111**
2. Dataset: **Dog genes**
3. Filters: Gene type = `protein_coding`
4. Attributes:
   - Gene stable ID
   - Gene name
   - Transcript stable ID
   - Wolf gene stable ID
   - Wolf protein stable ID
5. Export as TSV → Unique results

This gives you just dog-wolf orthologs (~20k genes) which is enough to test the pipeline.

---

## What If Species Are Missing?

BioMart has limited Canidae coverage. If you need more species:

### Option A: Use OrthoFinder (Recommended for missing species)

Build orthologs from your genome data:

```bash
# Install OrthoFinder
conda install -c bioconda orthofinder

# Prepare protein sequences
mkdir orthofinder_input
cp data/proteins/*.fa orthofinder_input/

# Run OrthoFinder
orthofinder -f orthofinder_input/ -t 10 -o data/orthologs/orthofinder_results/
```

This will create ortholog groups from ALL your species, not just those in Ensembl.

### Option B: Use eggNOG-mapper

Map genes to eggNOG ortholog groups:

```bash
# Will create orthologs based on evolutionary relationships
# Details in advanced section of main README
```

---

## Expected BioMart Output Format

Your TSV file should look like this:

```
Gene_stable_ID  Gene_name  Transcript_stable_ID  Wolf_Gene_ID  Wolf_Protein_ID  ...
ENSCAFG00000000001  ATP5F1A  ENSCAFT00000000001  ENSCAFG00845000001  ENSCAFP00845000001  ...
ENSCAFG00000000002  BRCA1   ENSCAFT00000000002  ENSCAFG00845000123  ENSCAFP00845000123  ...
...
```

Each row = one dog gene and its orthologs in other species

---

## Common Issues

### Issue: Can't find certain species
**Solution:** Many Canidae species aren't in Ensembl yet. Use OrthoFinder instead (see above).

### Issue: Too many results (>100k)
**Solution:** You didn't filter to protein_coding genes. Add gene type filter.

### Issue: Download times out
**Solution:**
1. Reduce number of species
2. Download in batches (dog-wolf first, then dog-fox, etc.)
3. Use API instead of web interface

### Issue: Results look weird/duplicated
**Solution:** Make sure "Unique results only" is checked

---

## After Download

Once you have the ortholog table, run the extraction script:

```bash
python scripts/alignment/extract_cds.py \
    --orthologs data/orthologs/ensembl_compara_table.tsv \
    --cds_dir data/cds/ \
    --out data/orthologs/ \
    --min_species 2
```

Note: Use `--min_species 2` for BioMart data (since we only have 3-4 species from Ensembl)

---

## Advanced: BioMart API (For Automation)

If you want to automate this:

```R
# Using biomaRt R package
library(biomaRt)

ensembl <- useEnsembl(biomart = "genes", dataset = "clfamiliaris_gene_ensembl")

# Get orthologs
orthologs <- getBM(
  attributes = c(
    'ensembl_gene_id',
    'external_gene_name',
    'ensembl_transcript_id',
    'wolf_homolog_ensembl_gene',
    'wolf_homolog_ensembl_peptide'
  ),
  filters = 'biotype',
  values = 'protein_coding',
  mart = ensembl
)

write.table(orthologs,
            "data/orthologs/ensembl_compara_table.tsv",
            sep="\t",
            row.names=FALSE,
            quote=FALSE)
```

---

## Summary Checklist

- [ ] Go to BioMart: https://www.ensembl.org/biomart/martview
- [ ] Select Database: Ensembl Genes 111
- [ ] Select Dataset: Dog genes
- [ ] Add Filter: Gene type = protein_coding
- [ ] Add Attributes: Gene IDs, names, transcript IDs
- [ ] Add Ortholog Attributes for Wolf, Red fox, Arctic fox
- [ ] Click Results → Export TSV
- [ ] Check "Unique results only"
- [ ] Download and save to: `data/orthologs/ensembl_compara_table.tsv`
- [ ] Verify file with `head` and `wc -l`

---

## Next Steps After BioMart

1. Verify ortholog table is downloaded
2. Wait for genomes to finish downloading
3. Run CDS extraction script
4. Check data status
5. Launch pipeline!

---

**Questions?** See main `DATA_SOURCES.md` or `README.md`

Generated by Claude Code 🤖
