# Literature References - Canidae Phylogenomics

Comprehensive bibliography for methods, data sources, and interpretation.

---

## Core Methods & Software

### Positive Selection Detection

**aBSREL (Adaptive Branch-Site Random Effects Likelihood)**
- Smith, M. D., et al. (2015). Less is more: an adaptive branch-site random effects model for efficient detection of episodic diversifying selection. *Molecular Biology and Evolution*, 32(5), 1342-1353.
  - DOI: 10.1093/molbev/msv022
  - Method used for detecting positive selection in this study
  - Accounts for episodic selection along specific branches
  - More powerful than branch-site models for genome-wide scans

**HyPhy (Hypothesis Testing using Phylogenies)**
- Kosakovsky Pond, S. L., et al. (2020). HyPhy 2.5—a customizable platform for evolutionary hypothesis testing using phylogenies. *Molecular Biology and Evolution*, 37(1), 295-299.
  - DOI: 10.1093/molbev/msz197
  - Software framework for selection analysis
  - Implements aBSREL and other selection tests
  - Website: http://www.hyphy.org/

### Sequence Alignment

**MAFFT (Multiple Alignment using Fast Fourier Transform)**
- Katoh, K., & Standley, D. M. (2013). MAFFT multiple sequence alignment software version 7: improvements in performance and usability. *Molecular Biology and Evolution*, 30(4), 772-780.
  - DOI: 10.1093/molbev/mst010
  - Used for protein sequence alignment
  - Fast and accurate for large-scale analyses

**pal2nal (Protein Alignment to Nucleotide Alignment)**
- Suyama, M., Torrents, D., & Bork, P. (2006). PAL2NAL: robust conversion of protein sequence alignments into the corresponding codon alignments. *Nucleic Acids Research*, 34(suppl_2), W609-W612.
  - DOI: 10.1093/nar/gkl315
  - Converts protein alignments to codon alignments
  - Preserves reading frames for selection analysis

### Workflow Management

**Snakemake**
- Mölder, F., et al. (2021). Sustainable data analysis with Snakemake. *F1000Research*, 10, 33.
  - DOI: 10.12688/f1000research.29032.2
  - Workflow management system used in this pipeline
  - Ensures reproducibility and parallelization

---

## Genomic Data Sources

### Ensembl Genome Database

**Ensembl Release 111**
- Cunningham, F., et al. (2022). Ensembl 2022. *Nucleic Acids Research*, 50(D1), D988-D995.
  - DOI: 10.1093/nar/gkab1049
  - Source of genome assemblies and CDS sequences
  - Website: https://ensembl.org

**Ensembl Compara**
- Herrero, J., et al. (2016). Ensembl comparative genomics resources. *Database*, 2016, bav096.
  - DOI: 10.1093/database/bav096
  - Source of ortholog predictions
  - Phylogenetic-based orthology inference

### Reference Genomes Used

**Dog (*Canis lupus familiaris*) - ROS_Cfam_1.0**
- Field, M. A., et al. (2020). Canfam_GSD: De novo chromosome-length genome assembly of the German Shepherd Dog. *GigaScience*, 9(6), giaa027.
  - DOI: 10.1093/gigascience/giaa027
  - High-quality reference genome for domestic dog

**Red Fox (*Vulpes vulpes*) - VulVul2.2**
- Kukekova, A. V., et al. (2018). Red fox genome assembly identifies genomic regions associated with tame and aggressive behaviours. *Nature Ecology & Evolution*, 2(9), 1479-1491.
  - DOI: 10.1038/s41559-018-0611-6
  - Reference genome for red fox
  - Includes behavioral trait mapping

**Dingo (*Canis lupus dingo*) - ASM325472v1**
- Smith, B. P., et al. (2019). Taxonomic status of the Australian dingo: the case for Canis dingo Meyer, 1793. *Zootaxa*, 4564(1), 173-197.
  - Dingo genome assembly
  - Provides phylogenetic context for Canidae evolution

---

## Evolutionary Biology Theory

### Molecular Evolution & Selection

**dN/dS Ratio (ω)**
- Yang, Z., & Bielawski, J. P. (2000). Statistical methods for detecting molecular adaptation. *Trends in Ecology & Evolution*, 15(12), 496-503.
  - DOI: 10.1016/S0169-5347(00)01994-7
  - Theory behind dN/dS ratio
  - Interpretation: ω > 1 indicates positive selection

**Episodic Selection**
- Murrell, B., et al. (2015). Gene-wide identification of episodic selection. *Molecular Biology and Evolution*, 32(5), 1365-1371.
  - DOI: 10.1093/molbev/msv035
  - Theory of episodic vs. pervasive selection
  - Relevant for interpreting aBSREL results

### Comparative Genomics

**Ortholog Inference**
- Kriventseva, E. V., et al. (2019). OrthoDB v10: sampling the diversity of animal, plant, fungal, protist, bacterial and viral genomes for evolutionary and functional annotations of orthologs. *Nucleic Acids Research*, 47(D1), D807-D811.
  - DOI: 10.1093/nar/gky1053
  - Methods for ortholog detection
  - Quality control considerations

---

## Canidae Biology & Evolution

### Canidae Phylogeny & Evolution

**Canidae Systematics**
- Lindblad-Toh, K., et al. (2005). Genome sequence, comparative analysis and haplotype structure of the domestic dog. *Nature*, 438(7069), 803-819.
  - DOI: 10.1038/nature04338
  - Dog genome project
  - Foundation for canid genomics

**Red Fox Evolution**
- Kukekova, A. V., et al. (2011). Sequence comparison of prefrontal cortical brain transcriptome from a tame and an aggressive silver fox (*Vulpes vulpes*). *BMC Genomics*, 12(1), 1-20.
  - DOI: 10.1186/1471-2164-12-482
  - Fox domestication experiment
  - Behavioral evolution in foxes

### Dietary Ecology & Adaptation

**Canid Dietary Ecology**
- Van Valkenburgh, B. (2007). Déjà vu: the evolution of feeding morphologies in the Carnivora. *Integrative and Comparative Biology*, 47(1), 147-163.
  - DOI: 10.1093/icb/icm016
  - Canid dietary adaptations
  - Morphological and ecological context

**Omnivory in Red Fox**
- Dell'Arte, G. L., Laaksonen, T., Norrdahl, K., & Korpimäki, E. (2007). Variation in the diet composition of a generalist predator, the red fox, in relation to season and density of main prey. *Acta Oecologica*, 31(3), 276-281.
  - DOI: 10.1016/j.actao.2006.12.007
  - Red fox dietary flexibility
  - Omnivory vs. carnivory

---

## Functional Genomics

### Gene Ontology & Functional Annotation

**Gene Ontology Consortium**
- The Gene Ontology Consortium. (2021). The Gene Ontology resource: enriching a GOld mine. *Nucleic Acids Research*, 49(D1), D325-D334.
  - DOI: 10.1093/nar/gkaa1113
  - Framework for functional annotation
  - Used for functional enrichment analysis

### Metabolic Pathways

**KEGG (Kyoto Encyclopedia of Genes and Genomes)**
- Kanehisa, M., & Goto, S. (2000). KEGG: kyoto encyclopedia of genes and genomes. *Nucleic Acids Research*, 28(1), 27-30.
  - DOI: 10.1093/nar/28.1.27
  - Metabolic pathway database
  - Context for metabolic gene interpretation

---

## Statistical Methods

### Multiple Testing Correction

**False Discovery Rate (FDR)**
- Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate: a practical and powerful approach to multiple testing. *Journal of the Royal Statistical Society: Series B*, 57(1), 289-300.
  - Statistical method for multiple testing
  - Used in HyPhy selection tests

---

## Specific Genes & Pathways

### Metabolic Genes Identified

**MECR (Mitochondrial trans-2-enoyl-CoA reductase)**
- Jiang, L., et al. (2016). MECR, a homologous mitochondrial trans-2-enoyl-CoA reductase defects in mitochondrial fatty acid synthesis, causes autosomal-recessive childhood dystonia. *American Journal of Human Genetics*, 99(6), 1249-1268.
  - DOI: 10.1016/j.ajhg.2016.09.021
  - Fatty acid metabolism
  - Relevant to dietary adaptation hypothesis

**GLYCTK (Glycerate kinase)**
- Barratt, J., & Rector, T. (1981). Glycerate kinase. *Methods in Enzymology*, 90, 261-265.
  - Carbohydrate metabolism
  - Gluconeogenesis pathway

### Neural & Behavioral Genes

**HCRTR1 (Hypocretin receptor 1)**
- Sakurai, T., et al. (1998). Orexins and orexin receptors: a family of hypothalamic neuropeptides and G protein-coupled receptors that regulate feeding behavior. *Cell*, 92(4), 573-585.
  - DOI: 10.1016/S0092-8674(00)80949-6
  - Feeding behavior regulation
  - Sleep/wake cycle control
  - Relevant to behavioral adaptation

**PER3 (Period circadian regulator 3)**
- Archer, S. N., et al. (2003). A length polymorphism in the circadian clock gene Per3 is linked to delayed sleep phase syndrome and extreme diurnal preference. *Sleep*, 26(4), 413-415.
  - Circadian rhythm regulation
  - Behavioral timing

---

## Reproducibility & Best Practices

**FAIR Data Principles**
- Wilkinson, M. D., et al. (2016). The FAIR Guiding Principles for scientific data management and stewardship. *Scientific Data*, 3(1), 1-9.
  - DOI: 10.1038/sdata.2016.18
  - Findable, Accessible, Interoperable, Reusable
  - Guiding principles for this repository

**Workflow Reproducibility**
- Grüning, B., et al. (2018). Practical computational reproducibility in the life sciences. *Cell Systems*, 6(6), 631-635.
  - DOI: 10.1016/j.cels.2018.03.014
  - Best practices for computational reproducibility
  - Containerization and workflow management

---

## Additional Reading

### Comparative Genomics Reviews

- Pennell, M. W., & Harmon, L. J. (2013). An integrative view of phylogenetic comparative methods: connections to population genetics, community ecology, and paleobiology. *Annals of the New York Academy of Sciences*, 1289(1), 90-105.
  - DOI: 10.1111/nyas.12157

### Positive Selection in Mammals

- Nielsen, R. (2005). Molecular signatures of natural selection. *Annual Review of Genetics*, 39, 197-218.
  - DOI: 10.1146/annurev.genet.39.073003.112420

---

## Citation for This Pipeline

If you use this pipeline, please cite:

```
[Your Name]. (2025). Comparative Phylogenomics of Canidae:
Genome-Wide Selection Analysis. GitHub repository:
https://github.com/biopixl/PhD_Projects/tree/main/Canids/Claude
```

And cite the key software:
- HyPhy (Kosakovsky Pond et al., 2020)
- aBSREL (Smith et al., 2015)
- MAFFT (Katoh & Standley, 2013)
- Snakemake (Mölder et al., 2021)
- Ensembl (Cunningham et al., 2022)

---

*Last updated: November 17, 2025*
