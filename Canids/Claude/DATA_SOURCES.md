# Data Sources - Canidae Phylogenomics

Complete documentation of all data sources used in this comparative genomics pipeline.

---

## Overview

This project uses publicly available genomic data from Ensembl and other repositories. All data can be freely downloaded and reproduced.

**Data Access Policy:** All data sources are open-access and comply with FAIR principles (Findable, Accessible, Interoperable, Reusable).

---

## Primary Data Sources

### 1. Ensembl Genome Database

**Website:** https://ensembl.org
**Release Used:** Ensembl Release 111 (July 2023)
**Access:** Free, open-access

**Data Types Downloaded:**
- Genome assemblies (reference sequences)
- CDS (Coding Sequence) annotations
- Gene annotations and descriptions
- Ortholog predictions (via Ensembl Compara)

**Citation:**
```
Cunningham, F., et al. (2022). Ensembl 2022.
Nucleic Acids Research, 50(D1), D988-D995.
DOI: 10.1093/nar/gkab1049
```

---

## Species-Specific Data

### Dog (*Canis lupus familiaris*)

**Assembly:** ROS_Cfam_1.0
**Assembly Accession:** GCA_014441545.1
**INSDC Project:** PRJEB24066

**Data Files:**
- **CDS Sequences:** `Canis_lupus_familiaris.ROS_Cfam_1.0.cds.all.fa.gz`
- **Download URL:** https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/
- **File Size:** ~88 MB (compressed)
- **Number of CDS:** 43,525 coding sequences

**Genome Reference:**
```
Field, M. A., et al. (2020). Canfam_GSD: De novo chromosome-length
genome assembly of the German Shepherd Dog.
GigaScience, 9(6), giaa027.
DOI: 10.1093/gigascience/giaa027
```

**Download Command:**
```bash
curl -o data/cds/Canis_familiaris.cds.fa.gz \
  "https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_familiaris/cds/Canis_lupus_familiaris.ROS_Cfam_1.0.cds.all.fa.gz"
gunzip data/cds/Canis_familiaris.cds.fa.gz
```

---

### Red Fox (*Vulpes vulpes*)

**Assembly:** VulVul2.2
**Assembly Accession:** GCA_003160815.1
**INSDC Project:** PRJNA378561

**Data Files:**
- **CDS Sequences:** `Vulpes_vulpes.VulVul2.2.cds.all.fa.gz`
- **Download URL:** https://ftp.ensembl.org/pub/release-111/fasta/vulpes_vulpes/cds/
- **File Size:** ~90 MB (compressed)
- **Number of CDS:** 41,026 coding sequences

**Genome Reference:**
```
Kukekova, A. V., et al. (2018). Red fox genome assembly identifies
genomic regions associated with tame and aggressive behaviours.
Nature Ecology & Evolution, 2(9), 1479-1491.
DOI: 10.1038/s41559-018-0611-6
```

**Download Command:**
```bash
curl -o data/cds/Vulpes_vulpes.cds.fa.gz \
  "https://ftp.ensembl.org/pub/release-111/fasta/vulpes_vulpes/cds/Vulpes_vulpes.VulVul2.2.cds.all.fa.gz"
gunzip data/cds/Vulpes_vulpes.cds.fa.gz
```

---

### Dingo (*Canis lupus dingo*)

**Assembly:** ASM325472v1
**Assembly Accession:** GCA_003254725.1
**INSDC Project:** PRJNA420116

**Data Files:**
- **CDS Sequences:** `Canis_lupus_dingo.ASM325472v1.cds.all.fa.gz`
- **Download URL:** https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_dingo/cds/
- **File Size:** ~70 MB (compressed)
- **Number of CDS:** 34,534 coding sequences

**Download Command:**
```bash
curl -o data/cds/Canis_lupus_dingo.cds.fa.gz \
  "https://ftp.ensembl.org/pub/release-111/fasta/canis_lupus_dingo/cds/Canis_lupus_dingo.ASM325472v1.cds.all.fa.gz"
gunzip data/cds/Canis_lupus_dingo.cds.fa.gz
```

---

*Full documentation available in repository*

*Last updated: November 17, 2025*
