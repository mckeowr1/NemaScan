![Build Docker (env/nemascan.Dockerfile)](https://github.com/AndersenLab/NemaScan/workflows/Build%20Docker%20(env/nemascan.Dockerfile)/badge.svg) ![Build Docker (env/mediation.Dockerfile)](https://github.com/AndersenLab/NemaScan/workflows/Build%20Docker%20(env/mediation.Dockerfile)/badge.svg) 

# NemaScan

GWA Mapping and Simulation with _C. elegans, C. tropicalis, and C. briggsae_

# Pipeline overview

![](img/nemascan.drawio.svg)

## Software Requirements

* This pipeline requires Nextflow version 20.0+. On QUEST, you can access this version by loading the `nf20_env` conda environment prior to running the pipeline command:

```
module load python/anaconda3.6
source activate /projects/b1059/software/conda_envs/nf20_env
```

Alternatively you can update Nextflow by running:

```
nextflow self-update
```

* Singularity. On QUEST, you can get this with `module load singularity` before running

*Note: previous versions of pipeline used conda environments on QUEST installed at `/projects/b1059/software/conda_envs/` but this will no longer be maintained*

* On QUEST, all software requirements are provided within the pipeline using conda environments or a docker image. To run the pipeline outside of QUEST, you can load the docker image containing all necessary software, see more in `profiles` below.

# Usage

For usage help running NemaScan on Google Cloud, check out instructions [here](GCP_readme.md)

## Running the pipeline manually (with git clone)

```
git clone https://github.com/AndersenLab/NemaScan.git
cd NemaScan
nextflow run main.nf --debug
```

## Running the pipeline remotely
For reproducible pipelines, it is recommended to run NemaScan **without cloning the repo**. In this manner, you can also choose which branch and/or commit you wish to run. 

```
nextflow run andersenlab/nemascan --debug
```

*Note: if you are running into issues with this, you can either (1) check out the help page for nextflow [here](http://andersenlab.org/dry-guide/latest/quest-nextflow/) or (2) try running manually with git clone (above)*

## Testing/debugging the mapping profile

If you are trying to run a GWAS mapping with NemaScan, it might be a good idea to first run the debug test. This test takes only a few minutes and if it completes successfully, there is a good chance your real data run will also finish.

```
nextflow run andersenlab/nemascan --debug
```

To display the help message, run `nextflow andersenlab/nemascan --help` 



# Profiles and Parameters

## Mappings Profile

This is the standard profile for running NemaScan. Use this profile to perform a genome-wide analysis with your trait of interest. To be explicit, you can use `-profile mappings`, however if no profile is provided, the pipeline will default to this one.

```
nextflow run andersenlab/nemascan -profile mappings --vcf 20220216 --traitfile input_data/c_elegans/phenotypes/PC1.tsv
```

*NOTE: you can also run specific branches or previous git commits easily. This can be especially useful to ensure that the version of NemaScan that you use doesn't change as you prepare your manuscript even if the code is updated.*

All you need to do is add a `-r XXX` to the end of your command, where `XXX` can be either (1) name of git branch, (2) name of git repo release, or (3) git commit ID

**For all runs, you can find the exact git commit used to run your analysis in the Nextflow report output after each run**

```
nextflow run andersenlab/nemascan --vcf 20220216 --traitfile input_data/c_elegans/phenotypes/PC1.tsv -r fa7046475fcfd06a49b375b4ef24a761f5133600

```

### --vcf

CeNDR release date for the VCF file with variant data (i.e. "20220216") Hard-filter VCF will be used for the GWA mapping and imputed VCF will be used for fine mapping. If this flag is not used, the most recent VCF for the _C. elegans_ species will be downloaded from [CeNDR](https://elegansvariation.org/data/release/latest).

#### Notes on VCF
*If you want to use a custom VCF, you may provide the full path to the vcf in place of the CeNDR release date. This custom VCF will be used for BOTH GWA mapping and fine-mapping steps (instead of the imputed vcf).*

### --traitfile

A tab-delimited formatted (.tsv) file that contains trait information.  Each phenotype file should be in the following format (replace trait_name with the phenotype of interest):

| strain | trait_name_1 | trait_name_2 |
| --- | --- | --- |
| JU258 | 32.73 | 19.34 |
| ECA640 | 34.065378 | 12.32 |
| ... | ... | ... | 124.33 |
| ECA250 | 34.096 | 23.1 |

#### Optional Mapping Parameters

* `--species` - Choose between `c_elegans` (DEFAULT), `c_tropicalis` or `c_briggsae`

* `--sthresh` - This determines the signficance threshold required for performing post-mapping analysis of a QTL. `BF` corresponds to Bonferroni correction, `EIGEN` corresponds to correcting for the number of independent markers in your data set, and `user-specified` corresponds to a user-defined threshold, where you replace user-specified with a number. For example `--sthresh=4` will set the threshold to a `-log10(p)` value of 4. We recommend using the strict `BF` correction as a first pass to see what the resulting data looks like. If the pipeline stops at the `summarize_maps` process, no significant QTL were discovered with the input threshold. You might want to consider lowering the threshold if this occurs. (Default: `BF`)

* `--out` - A user-specified output directory name. (Default: `Analysis_Results-{date}`)

* `--group_qtl` - QTL within this distance of each other (bp) will be grouped as a single QTL by `Find_GCTA_Intervals_*.R`. (Default: 1000)

* `--ci_size` - The number of markers for which the detection interval will be extended past the last significant marker in the interval. (Default: 150)

* `--maf` - The minor allele frequency for filtering variants to use for gwas mapping

* `--finemap` - Defaults to *true*, can change to *false* if you want to skip the finemapping steps.

* `--mediation` - Defaults to *true*, can change to *false* if you want to skip mediation.

* `--pca` - Defaults to *true*, can change to *false* to not include the first PCA as a component in the GCTA mapping.


## Genomatrix Profile

This profile takes a list of strains and outputs the genotype matrix but does not perform any other analysis for the genome-wide association. 

```
nextflow run andersenlab/nemascan -profile genomatrix --vcf 20220216 --strains input_data/c_elegans/phenotypes/strain_file.tsv
```

### --vcf

CeNDR release date for the VCF file with variant data (i.e. "20220216") Hard-filter VCF will be used for the GWA mapping and imputed VCF will be used for fine mapping. If this flag is not used, the most recent VCF for the _C. elegans_ species will be downloaded from [CeNDR](https://elegansvariation.org/data/release/latest).

### --strains

A file (.tsv) that contains a list of strains used for generating the genotype matrix. There is no header:

```
JU258
ECA640
...
ECA250
```

## Simulations Profile

This profile uses simulations to establish GWA performance benchmarks. Users can specify the heritability of simulated traits, the number of QTL underlying simulated traits of interest, the strains the user intends to use in a prospective GWA mapping experiment, or the location of previously detected QTL. Understanding the null expectations of GWA mappings within given parameter spaces may provide experimenters with additional guidance before initiating an experiment, or serve as a validation tool for previous mappings.

```
nextflow andersenlab/nemascan -profile simulations --vcf 20220216 --simulate_nqtl input_data/all_species/simulate_nqtl.csv --simulate_reps 2 --simulate_h2 input_data/all_species/simulate_h2.csv --simulate_eff input_data/all_species/simulate_effect_sizes.csv --simulate_strains input_data/all_species/simulate_strains.tsv --out example_simulation_output
module load R/3.6.3
Rscript bin/Assess_Simulated_Mappings.R example_simulation_output TRUE
```
Set the `TRUE` flag when the strain designation is a part of the mapping population id. Ex) ce.closest200.92_dark.weval 


### --vcf

CeNDR release date for the VCF file with variant data (i.e. "20220216") Hard-filter VCF will be used for the GWA mapping and imputed VCF will be used for fine mapping. If this flag is not used, the most recent VCF for the _C. elegans_ species will be downloaded from [CeNDR](https://elegansvariation.org/data/release/latest).

### --simulate_nqtl 
A single column CSV file that defines the number of QTL to simulate (format: one number per line, no column header) (Default is provided: `input_data/all_species/simulate_nqtl.csv`).

### --simulate_reps
The number of replicates to simulate per number of QTL and heritability (Default: 2).

### --simulate_h2 
A CSV file with phenotype heritability. (format: one value per line, no column header) (Default is located: `input_data/all_species/simulate_h2.csv`).

### --simulate_eff
A CSV file specifying a range of causal QTL effects. QTL effects will be drawn from a uniform distribution bound by these two values. If the user wants to specify _Gamma_ distributed effects, the value in this file can be simply specified as "gamma". (format: one value per line, no column header) (Default is located: input_data/all_species/simulate_effect_sizes.csv).

### --simulate_strains
A TSV file specifying the population in which to simulate GWA mappings. Multiple populations can be simulated at once, but causal QTL will be drawn independently for each population as a result of minor allele frequency and LD pruning prior to mapping. (format: one line per population; supplied population name and a comma-separated list of each strain in the population) (Default is located: input_data/all_species/simulate_strains.tsv).

#### Optional Simulation Parameters

* `--simulate_maf` - A single column CSV file that defines the minor allele frequency threshold used to filter the VCF prior to simulations (Default: 0.05).

* `--simulate_qtlloc` - A .bed file specifying genomic regions from which causal QTL are to be drawn after MAF filtering and LD pruning. (format: CHROM START END for each genomic region, with no header. NOTE: CHROM is specified as NUMERIC, not roman numerals as is convention in _C. elegans_)(Default is located: input_data/all_species/simulate_locations.bed).

* `--group_qtl` - QTL within this distance of each other (bp) will be grouped as a single QTL by `Find_GCTA_Intervals_*.R`. (Default: 1000)

* `--ci_size` - The number of markers for which the detection interval will be extended past the last significant marker in the interval. (Default: 150)

## Annotations Profile (in development)

`nextflow andersenlab/nemascan --vcf 20220216 -profile annotations --species briggsae --wb_build WS270`

* `--species` - specifies what species information to download from WormBase (options: elegans, briggsae, tropicalis).

* `--wb_build` - specifies what WormBase build to download annotation information from (format: WSXXX, where XXX is a number greater than 270 and less than 277).

## GWA Mapping with Docker Profile

This profile uses a docker image instead of local conda environments to perform the GWA mapping. Use this profile if you have issue with conda on QUEST or if you are running the pipeline outside of quest. *NOTE: Docker or singularity is required*

**On QUEST:**
```
module load singularity
nextflow run andersenlab/nemascan --traitfile <file> --vcf 20220216 -profile mappings_docker
```

**Local**
*make sure you have installed docker and that it is actively running. See [here](http://andersenlab.org/dry-guide/latest/pipeline-docker/) for help.*

```
nextflow run andersenlab/nemascan --traitfile <file> --vcf 20220216 -profile local

```

## GCP Profile

This profile is used to run GWA mappings on CeNDR using the GCP platform. Check out more on how to develop, test, and run nextflow on GCP [here](http://andersenlab.org/dry-guide/latest/pipeline-GCPconfig/).

```
nextflow run andersenlab/nemascan --traitfile <file> --vcf 20220216 -profile gcp
```

# Input Data Folder Structure (`NemaScan/input_data`)

```
all_species
  ├── rename_chromosomes
  ├── simulate_effect_sizes.csv
  ├── simulate_h2.csv
  ├── simulate_maf.csv
  ├── simulate_nqtl.csv
  ├── simulate_strains.tsv
  ├── simulate_locations.bed
c_elegans (repeated for c_tropicalis and c_briggsae)
  ├── genotypes  
      ├── test_vcf
      ├── test_vcf_index
      ├── test_bcsq_annotation
  ├── phenotypes
      ├── PC1.tsv
      ├── strain_file.tsv
      ├── test_pheno.tsv
  ├── annotations
      ├── GTF file
      ├── refFlat file
  ├── isotypes
      ├── div_isotype_list.txt
      ├── divergent_bins.bed
      ├── divergent_df_isotype.bed
      ├── haplotype_df_isotype.bed
      ├── strain_isotype_lookup.tsv
```

# Mapping Output Folder Structure

```
Phenotypes
  ├── strain_issues.txt
  ├── pr_traitname.tsv
Genotype_Matrix
  ├── Genotype_Matrix.tsv
  ├── total_independent_tests.txt
INBRED (or LOCO)
  ├── Mapping
      ├── Raw
          ├── traitname_lmm-exact_inbred.fastGWA
          ├── traitname_lmm-exact.loco.mlma
      ├── Processed
          ├── traitname_AGGREGATE_qtl_region.tsv
          ├── processed_traitname_AGGREGATE_mapping.tsv
  ├── Plots
      ├── ManhattanPlots
          ├── traitname_manhattan.plot.png
      ├── LDPlots
          ├── traitname_LD.plot.png (if > 1 QTL detected)
      ├── EffectPlots
          ├── traitname_[QTL.INFO]_LOCO_effect.plot.png (if detected)
          ├── traitname_[QTL.INFO]_INBRED_effect.plot.png (if detected)
  ├── Fine_Mappings
      ├── Data             
          ├── traitname_[QTL.INFO]_bcsq_genes.tsv
          ├── traitname_[QTL.INFO]_ROI_Genotype_Matrix.tsv
          ├── traitname_[QTL.INFO]_finemap_inbred.fastGWA
          ├── traitname_[QTL.INFO]_LD.tsv
      ├── Plots   
          ├── traitname_[QTL.INFO]_finemap_plot.pdf
          ├── traitname_[QTL.INFO]_gene_plot_bcsq.pdf
  ├── Divergent_and_haplotype
      ├── all_QTL_bins.bed
      ├── all_QTL_div.bed
      ├── div_isotype_list.txt
      ├── haplotype_in_QTL_region.txt
Reports
  ├── NemaScan_Report_traitname_main.html
  ├── NemaScan_Report_traitname_main.Rmd
```

### Phenotypes folder
* `strain_issues.txt` - Output of any strain names that were changed to match vcf (i.e. isotypes that are not reference strains)
* `pr_traitname.tsv` - Processed phenotype file for each trait. This is the file that goes into the mapping

### Genotype_Matrix folder
* `Genotype_Matrix.tsv` - LD-pruned genotype matrix used for GWAS and construction of kinship matrix
* `total_independent_tests.txt` - number of independent tests determined through spectral decomposition of the genotype matrix

### Mapping folder

#### Raw
* `traitname_lmm-exact_inbred.fastGWA` - Raw mapping results from GCTA's fastGWA program using an inbred kinship matrix
* `traitname_lmm-exact.loco.mlma` - Raw mapping results from GCTA's mlma program using a kinship matrix constructed from all chromosomes except for the chromosome containing each tested variant

#### Processed
* `traitname_AGGREGATE_mapping.tsv` - Combined processed mapping results from lmm-exact_inbred and lmm-exact.loco.mlma raw mappings. Contains additional information nested such as 1) rough intervals (see parameters for calculation) and estimates of the variance explained by the detected QTL 2) phenotype information and genotype status for each strain at the detected QTL.
* `traitname_AGGREGATE_qtl_region.tsv` - Contains only QTL information for each mapping. If no QTL are detected, an empty data frame is written.
* `QTL_peaks.tsv` - contains QTL information for each mapping for all traits combined.
##### QTL_Regions
* `traitname_*_qtl_region.tsv` - Contains only QTL information for each mapping. If no QTL are detected, an empty data frame is written.

### Plots
* `traitname_manhattan.plot.png` - Standard output for GWA; association of marker differences with phenotypic variation in the population.
* `traitname_LD.plot.png` - If more than 1 QTL are detected for a trait, a plot showing the linkage disequilibrium between each QTL is generated.
* `traitname_[QTL.INFO]_INBRED_effect.plot.png` - Phenotypes for each strain are plotted against their marker genotype at the peak marker for each QTL detected for a trait. The dot representing each strain is shaded according to the percentage of the chromosome containing the QTL that is characterized as a selective sweep region.

#### Fine_Mappings folder

##### Data
* `traitname_snpeff_genes.tsv` - Fine-mapping data frame for all significant QTL

##### Plots
* `traitname_qtlinterval_finemap_plot.pdf` - Fine map plot of QTL interval, colored by marker LD with the peak QTL identified from the genome-wide scan
* `traitname_qtlinterval_gene_plot.pdf` - variant annotation plot overlaid with gene CDS for QTL interval


# Simulation Output Folder Structure

```
Genotype_Matrix
  ├── [strain_set]_[MAF]_Genotype_Matrix.tsv
  ├── [strain_set]_[MAF]_total_independent_tests.txt
Simulations
  ├── NemaScan_Performance.example_simulation_output.RData
  ├── [specified effect range (simulate_effect_sizes.csv)]
      ├── [specified number of simulated QTL (simulate_nqtl.csv)]
          ├── Mappings
              ├── [nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_processed_LMM_EXACT_INBRED_mapping.tsv
              ├── [nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_processed_LMM_EXACT_LOCO_mapping.tsv
              ├── [nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_lmm-exact_inbred.fastGWA
              ├── [nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_lmm-exact.loco.mlma
          ├── Phenotypes
              ├── [nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_sims.phen
              ├── [nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_sims.par
  ├── (if applicable) [NEXT specified effect range]
      ├── ...
  ├── (if applicable) [NEXT specified effect range]
      ├── ...
```

### Genotype_Matrix folder
* `*Genotype_Matrix.tsv` - pruned LD-pruned genotype matrix used for GWAS and construction of kinship matrix. This will be appended with the chosen minor allele frequency cutoff and strain set, as they are generated separately for each strain set.
* `*total_independent_tests.txt` - number of independent tests determined through spectral decomposition of the genotype matrix. This will be also be appended with the chosen minor allele frequency cutoff and strain set, as they are generated separately for each strain set.

### Simulations
* `NemaScan_Performance.*.RData` - RData file containing all simulated and detected QTL from each successful simulated mapping. Contains:
1. Simulated and Detected status for each QTL.
2. Minor allele frequency and simulated or estimated effect for each QTL.
3. Detection interval according to specified grouping size and CI extension.
4. Estimated variance explained for each detected QTL.
5. Simulation parameters and the algorithm used for that particular regime.

### Mappings
* As with the mapping profile, raw and processed mappings for each simulation regime are nested within folders corresponding each specified effect range and number of simulated QTL. QTL region files are not provided in the simulation profile; this information along with other information related to mapping performance are iteratively gathered in the generation of the performance .RData file.

### Phenotypes
* `[nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_sims.phen` - Simulated strain phenotypes for each simulation regime.
* `[nQTL]_[rep]_[h2]_[MAF]_[effect range]_[strain_set]_sims.par` - Simulated QTL effects for each simulation regime. NOTE: Simulation regimes with identical numbers of simulated QTL, replicate indices, and simulated heritabilities should have _identical_ simulated QTL and effects.


# Relevant Docker Images

* `andersenlab/nemascan` ([link](https://hub.docker.com/r/andersenlab/nemascan)): Docker image is created within this pipeline using GitHub actions. Whenever a change is made to `env/nemascan.Dockerfile`, `env/conda.yml`, or `.github/workflows/build_docker.yml` GitHub actions will create a new docker image and push if successful
* `andersenlab/mediation` ([link](https://hub.docker.com/r/andersenlab/mediation)): Docker image is created within this pipeline using GitHub actions. Whenever a change is made to `env/mediation.Dockerfile`, `env/med_conda.yml` or `.github/workflows/build_med_docker.yml` GitHub actions will create a new docker image and push if successful


