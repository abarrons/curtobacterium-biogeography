# *Curtobacterium* Biogeography — Metagenomics Analysis

Analysis pipeline for the California *Curtobacterium* biogeography project, covering community ecology, diversity, and random forest / GLM predictive modelling of subclade relative abundance.

## Pipeline overview

Scripts are numbered and intended to be run in order:

| Script | Description |
|--------|-------------|
| `01_load_data.Rmd` | Load count table, taxonomy, and sample metadata; build phyloseq object |
| `02_litter_chemistry.Rmd` | Process litter chemistry data; PCA |
| `03_climate.Rmd` | Process PRISM climate data; bioclimate PCA |
| `04_normalize_phyloseq.Rmd` | Normalise count table (RPK); build phyloseq object |
| `05_relative_abundance.Rmd` | Clade/subclade relative abundance summaries |
| `06_alpha_diversity.Rmd` | Alpha diversity analyses |
| `07_beta_diversity.Rmd` | Beta diversity (Bray-Curtis) |
| `08_dbrda.Rmd` | Distance-based RDA |
| `09_linear_regression.Rmd` | CWM linear regressions |
| `10_pdp.Rmd` | Random forest models + partial dependence plots |

Utility functions shared across scripts live in `R/`.

## Data requirements

The following **raw data files** must be present to run scripts 01–10.  
Files marked ⚠️ are **not included in this repository** and must be obtained separately (see contacts).

### Within the repository (`data/`)

| File | Description |
|------|-------------|
| `count_table.txt` | Metagenomics count table (genomes × samples) |
| `parse_results_new/count_table.txt` | Count table for resequenced samples |
| `litter_chem/litter_chem.txt` | Litter chemistry measurements |
| `PRISM_ppt_tmin_tmean_tmax_30yr_normal_800m_monthly_normals.csv` | 30-yr PRISM climate normals |
| `GTDB_genus_abundance_table.tsv` | GTDB genus-level abundance table |
| `total_prok_counts.txt` | Total prokaryote counts per sample |
| `sites_coords.csv` | Reserve GPS coordinates |

### External files (⚠️ not in repository)

These files are read by `01_load_data.Rmd`, `03_climate.Rmd`, and `04_normalize_phyloseq.Rmd`
with absolute paths that must be updated to match your local setup:

| File | Used in | Description |
|------|---------|-------------|
| `clade_colors.txt` | `01` | Clade colour mapping |
| `masterMD4DB.txt` | `01`, `04` | Genome database metadata |
| `master_md_all_sequenced_Isolates_with_extendedMD.txt` | `01` | Isolate master metadata |
| `reserve_sample_data.txt` | `01` | Reserve-level sample metadata |
| `bioclim_names.txt` | `03` | Bioclimate variable labels |
| `gene_lengths_by_genome.csv` | `04` | Gene lengths for RPK normalisation |

> **Note:** `total_coregenes.fna` (397 MB core-gene sequences) is excluded from this repository.  
> It is not required to re-run the R analysis pipeline (scripts 01–10).

## Setup

```r
# Install required packages (run once)
install.packages(c(
  "tidyverse", "phyloseq", "vegan", "ggpubr", "ggh4x",
  "ranger", "iml", "pdp", "here", "writexl", "readxl",
  "bslib", "scales", "ggrepel", "extrafont"
))
```

Intermediate objects are passed between scripts via `.rds` files written to `results/rds/`
(excluded from version control). Run scripts in order starting from `01_load_data.Rmd`.
