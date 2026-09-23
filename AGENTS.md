# Curtobacterium Biogeography — Project Memory

Analysis pipeline for the California *Curtobacterium* biogeography project:
community ecology, diversity, and random forest / GLM modelling of subclade
relative abundance. Working directory: `~/SyncFolder/CA_curto/mg`.

## Conventions

- Scripts are numbered `.Rmd` files, run in order starting at `01_load_data.Rmd`.
- All file paths use `here::here()` relative to the project root — no absolute paths.
- Intermediate objects are passed between scripts as `.rds` files in
  `results/rds/` (git-ignored). Each script reads the `.rds` outputs of earlier
  scripts and saves its own at the end.
- Shared helper functions live in `R/` (`colors_themes.R`, `rf_functions.R`,
  `utils.R`), sourced at the top of scripts.
- Base R pipe assumed; tidyverse + phyloseq + vegan are the core stacks.

## Pipeline overview

| Script | Description |
|--------|-------------|
| `01_load_data.Rmd` | Load count table, taxonomy, sample metadata; build initial objects |
| `02_litter_chemistry.Rmd` | Process litter chemistry; PCA |
| `03_climate.Rmd` | Process PRISM climate data; bioclimate PCA; site map |
| `04_normalize_phyloseq.Rmd` | RPK-normalise count table; build phyloseq object |
| `05_relative_abundance.Rmd` | Clade/subclade relative abundance summaries |
| `06_alpha_diversity.Rmd` | Alpha diversity analyses |
| `07_beta_diversity.Rmd` | Beta diversity (Bray-Curtis), PERMANOVA |
| `08_dbrda.Rmd` | Distance-based RDA; DistLM |
| `09_linear_regression.Rmd` | CWM / abundance linear regressions |
| `10_pdp.Rmd` | Random forest models + partial dependence plots |
| `11_traits.Rmd` | Physiological trait integration (external `phys_assays/` data) |
| `12_gdm.Rmd` | Generalised dissimilarity modelling |
| `13_reserves_rts.Rmd` | Reserve-level summaries |

Scripts 01–10 are the core pipeline (see `README.md`). Scripts 11–13 are
extensions that also read external data from a sibling `phys_assays/` directory.

## Input data inventory

Raw files read from disk (the many `results/rds/*.rds` files are intermediates,
not inputs).

### Project-root files

| File | Used in | What it is |
|------|---------|------------|
| `count_table.txt` | 01 | Metagenomics count table (*Curtobacterium* genomes × samples) |
| `parse_results_new/count_table.txt` | 01 | Count table for resequenced samples; overwrites those columns |
| `litter_chem/litter_chem.txt` | 02 | Leaf-litter chemistry measurements per sample |
| `PRISM_ppt_tmin_tmean_tmax_30yr_normal_800m_monthly_normals.csv` | 03 | 30-yr PRISM monthly climate normals (ppt, tmin, tmean, tmax) at 800 m |
| `GTDB_genus_abundance_table.tsv` | 05 | GTDB genus-level abundance for the whole prokaryotic community |

### Metadata / mapping files (`data/`)

| File | Used in | What it is |
|------|---------|------------|
| `data/reserve_sample_data.txt` | 01 | Sample/reserve metadata: reserve, GPS coords, litter type, pH |
| `data/masterMD4DB.txt` | 01, 04 | Genome DB metadata (genome ID → name, genus) |
| `data/master_md_all_sequenced_Isolates_with_extendedMD.txt` | 01 | Isolate metadata; builds genus → clade → subclade taxonomy |
| `data/clade_colors.txt` | 01 | Clade/subclade colour mapping |
| `data/gene_lengths_by_genome.csv` | 04 | Per-genome gene lengths for RPK normalisation |
| `data/bioclim_names.txt` | 03 | Human-readable labels for bioclimatic variables |

### Pre-computed PRIMER results (read back for plotting/variance)

| File | Used in | What it is |
|------|---------|------------|
| `PERMANOVA_litter_chem_VarEstimates.txt` | 02 | PERMANOVA variance components for litter chemistry |
| `PERMANOVA_subclades_PlantTypeByReserve_VarEstimates.txt` | 07 | PERMANOVA variance estimates for subclade composition (plant type × reserve) |
| `DistLM_marginal_tests.txt` | 08 | DistLM marginal test results (variance explained per predictor) |

### Runtime download

- `03_climate.Rmd` downloads Natural Earth state/province boundaries via
  `rnaturalearth::ne_download()` for the site map (needs internet, no local file).

### External inputs (scripts 11–13, `~/SyncFolder/CA_curto/phys_assays/`)

- `temp/.../temp_curve_params_table.txt` — thermal performance curve parameters
- `pH/.../curve_params.tsv` — pH response curve parameters
- `biofilm/.../biofilm_avg_data.txt` — biofilm assay averages

## Notes

- `total_coregenes.fna` (~397 MB) is not needed to re-run the R pipeline.
- `total_prok_counts.txt` and `sites_coords.csv` exist in the root but are not
  read by the current pipeline (only in commented-out backup code).
- `diversity_analysis_ORIGINAL_BACKUP.Rmd` is the pre-refactor monolithic script,
  kept for reference; it uses absolute `~/SyncFolder/...` paths.
