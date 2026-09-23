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

The following **raw data files** must be present to run scripts 01–10. All paths
are resolved with `here::here()` relative to the project root, so no absolute
paths need editing.

### Project-root files

| File | Used in | Description |
|------|---------|-------------|
| `count_table.txt` | `01` | Metagenomics count table (*Curtobacterium* genomes × samples) |
| `parse_results_new/count_table.txt` | `01` | Count table for resequenced samples; overwrites those columns in the main table |
| `litter_chem/litter_chem.txt` | `02` | Leaf-litter chemistry measurements per sample |
| `PRISM_ppt_tmin_tmean_tmax_30yr_normal_800m_monthly_normals.csv` | `03` | 30-yr PRISM monthly climate normals (ppt, tmin, tmean, tmax) at 800 m |
| `GTDB_genus_abundance_table.tsv` | `05` | GTDB genus-level abundance table for the whole prokaryotic community |

### Metadata and mapping files (`data/`)

| File | Used in | Description |
|------|---------|-------------|
| `data/reserve_sample_data.txt` | `01` | Sample/reserve metadata: reserve, GPS coordinates, litter type, pH |
| `data/masterMD4DB.txt` | `01`, `04` | Genome database metadata (genome ID → name, genus) |
| `data/master_md_all_sequenced_Isolates_with_extendedMD.txt` | `01` | Isolate master metadata; builds the genus → clade → subclade taxonomy |
| `data/clade_colors.txt` | `01` | Clade/subclade colour mapping |
| `data/gene_lengths_by_genome.csv` | `04` | Per-genome gene lengths for RPK normalisation |
| `data/bioclim_names.txt` | `03` | Human-readable labels for the bioclimatic variables |

### Pre-computed PRIMER results

Outputs from external PRIMER runs that are read back in for variance summaries
and plotting rather than recomputed in R:

| File | Used in | Description |
|------|---------|-------------|
| `PERMANOVA_litter_chem_VarEstimates.txt` | `02` | PERMANOVA variance-component estimates for litter chemistry |
| `PERMANOVA_subclades_PlantTypeByReserve_VarEstimates.txt` | `07` | PERMANOVA variance estimates for subclade composition (plant type × reserve) |
| `DistLM_marginal_tests.txt` | `08` | DistLM marginal test results (variance explained per predictor) |

`03_climate.Rmd` also downloads Natural Earth state/province boundaries at
runtime via `rnaturalearth::ne_download()` for the site map; this requires an
internet connection but no local file.

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
