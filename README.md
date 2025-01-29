![SPOT-BGC logo](./img/spot-bgc_logo.png)

# SPOT-BGC

_A Snakemake Pipeline to Output meTagenomics-derived Biosynthetic Gene Clusters_

Author: Vi Varga

Last Major Update: 2025.01.29


## Introduction 

The SPOT-BGC pipeline is a workflow designed to process metagenomic FASTQ read data, eliminate human contamination, and assemble bacterial genomes; in order to predict Biosynthetic Gene Clusters (BGCs) present in the data. Metagenome-Assembled Genomes (MAGs) are produced during an intermediate step of this pipeline.

This pipeline can process both paired-end (PE) and single-end (SE) FASTQ input. In order to preserve as much data as possible, assembly is performed on both a per-sample and per-cohort basis. 


## Pipeline structure

The SPOT-BGC pipeline performs the following on input metagenomic FASTQ reads: 
1. Quality assessment: FastQC, MultiQC
2. Quality trimming: Trimmomatic
3. Human read filtration by mapping to the human genome: Bowtie2
4. Normalization of read counts: BBNorm
5. For the per-sample assemblies, sample IDs with <100k reads remaining are filtered out
6. Assembly: per-sample with (Meta)SPAdes, per-cohort with MEGAHIT (Note that if the complexity of a file causes MetaSPAdes to be unable to process it, MEGAHIT will be used, instead.)
8. Human contig elimination (sanity check): Kraken2
9. Binning of contigs into MAGs: MetaBAT
10. Quality assessment of the MAGs: CheckM
11. Taxonomic assignments of the MAGs: CheckM
12. BGC predictions: GECCO, AntiSMASH


## Dependencies

The primary dependencies of the SPOT-BGC pipeline are: 
 - Snakemake
 - Apptainer


## Running SPOT-BGC

Owing to a temporary bug in Snakemake at the time of this pipeline's creation, the programs used must be run out of containers, rather than via `conda` environments ([see source here](https://github.com/snakemake/snakemake/issues/3163)). All files necessary to generate the containers are included in this repository. 

To build the containers with Apptainer, run the following code from the `workflow/` directory: 

```bash
# create the workflow/containers/ directory
mkdir containers
cd containers/
# then build the containers with Apptainer
# the read QC container
apptainer build --build-arg ENV_FILE=../envs/env-QualityChecking.yml env-QualityChecking.sif ../scripts/conda_environment_args_ubuntu.def
# read trimming container
apptainer build --build-arg ENV_FILE=../envs/env-trimmomatic.yml env-trimmomatic.sif ../scripts/conda_environment_args_ubuntu.def
# human read removal container
apptainer build --build-arg ENV_FILE=../envs/env-bowtie2.yml env-bowtie2.sif ../scripts/conda_environment_args_ubuntu.def
# normalization via BBTools container
apptainer build --build-arg ENV_FILE=../envs/java-11.yml bbtools.sif ../scripts/conda_environment_args_ubuntu-bbtools.def
# assembly container
apptainer build --build-arg ENV_FILE=../envs/metagenome_assembly.yml metagenome_assembly.sif ../scripts/conda_environment_args_ubuntu.def
# human contig elimination with Kraken2
apptainer build --build-arg ENV_FILE=../envs/env-kraken.yml --build-arg REF_FILE=../../resources/Ref/{REFERENCE} env-kraken2db.sif ../scripts/conda_environment_args_ubuntu-kraken2db.def
# replace the {REFERENCE} placeholder with the name of your reference file
# note that this container will take some time to assemble, owing to the need to download & install databases
# QC of MAGs & taxonomic profiling
apptainer build --build-arg ENV_FILE=../envs/mag_assembly_qc.yml mag_assembly_qc.sif ../scripts/conda_environment_args_ubuntu.def
# BGCs with AntiSMASH
apptainer build --build-arg ENV_FILE=../envs/env-antismash.yml env-antismash.sif ../scripts/conda_environment_args_ubuntu-antismash.def
# BGCs with GECCO
apptainer build --build-arg ENV_FILE=../envs/env-gecco.yml env-gecco.sif ../scripts/conda_environment_args_ubuntu.def

```

Set up your project file structure as follows: 

```
├── LICENSE
├── README.md
├── config
│   └── config.yaml
├── resources
│   ├── RawData
│   │     ├── {COHORT_ID}
│   │     │    └── {SAMPLE_ID}
│   │     │        ├── {SAMPLE_1.fastq}
│   │     │        └── {SAMPLE_1.fastq}
│   │     └── {COHORT_ID}
│   │         └── {SAMPLE_ID}
│   │             └── {SAMPLE.fastq}
│   └── Ref
|       └── {REFERENCE}
└── workflow
    ├── containers
    ├── envs
    └── scripts

```

For the setup above, please note the following: 
 - The COHORT_ID is intended to be the NCBI BioProject number, but can be designated by the user however you wish. However, a cohort ID **must** be provided for every sample.
 - The sample raw FASTQ files should be in directories with the sample name. This is the structure that results if the data is downloaded directly from the NCBI with SRA (Sequence Read Archive) `fetch`.
 - The REFERENCE should be a DNA reference genome. Modify the `config.yaml` file located in the `config/` directory with your reference genome name.
 - As is illustrated, the SPOT-BGC pipeline works with both PE and SE input FASTQ files. 

Once you have organized your project as illustrated above, you can run the pipeline from your terminal from the main directory (i.e., the directory where `config/`, `resources/` and `workflow/` are located) like so: 

```bash
# activate your conda snakemake environment
conda activate snakemake
# standard usage
snakemake --use-singularity --cores 20 --config threads_trimming=6
# note that you must call the --use-singularity flag, as all programs are installed in Apptainer containers
# note that when working on a server, 
# you can specify the specific cores used with `taskset`
```

To modify the number of threads used by various programs, do the following:

```bash
# program thread modification
snakemake --use-singularity --cores 20 --config threads_{PROGRAM}={NUMBER}
# for example: 
snakemake --use-singularity --cores 20 --config threads_trimming=6
```

Please check the `config.yaml` file located at `config/config.yaml` to see the list of programs whose thread allocation can be modified in this way.


## Pipeline status

### Current published version

First major update, 2025.01.17: Build 2.0.0
 - Kraken2 has replaced BLASTN for the human contig elimination step, to improve speed
 - A safety measure has been added to the per-sample MetaSPAdes/SPAdes assembly: If a sample does not successfully assembly within 6 hours, the process will terminate & MEGAHIT will be used to assemble the sample, instead
 - Taxonomic profiling is now done with CheckM
 - The threads allocated for most rules can be modified from the command line with `--config thread_{PROGRAM}={NUMBER}`. Please see the configuration file at `config/config.yaml` for the full list of programs whose thread count can be modified in this manner.
 - If a cohort contains both SE and PE reads, the per-cohort assembly will be able to use all three together.
 - The initial files needed to run the entire pipeline are now generated as part of the workflow.
 - Usage notes/disclaimers:
   - At this stage, most users will need to modify the `config.yaml` file manually in order to change the reference genome, as well as modify the `Snakefile` or `bash` scripts manually in order to change the settings/arguments of the various programs.
   - The workflow has not yet been tested on a SLURM HPC environment, only on a server. 

### Ongoing work for future versions

Minor update, 2025.01.XX (date tentative): Build 2.1.0
 - Ensuring environmental compliance & functionality on SLURM HPCs

### Logs of earlier updates

Initial publication, 2024.11.12: Build 1.0.0-beta
 - The SPOT-BGC pipeline is functional, with the human genome as the reference genome. 
 - Note that while it has been successfully run for the analysis it was designed for, extensive testing of the pipeline has not been carried out.
 - At this stage, most users will need to modify the `config.yaml` file manually in order to change the reference genome, as well as modify the `Snakefile` manually in order to change the settings/arguments of the various programs. 
 - Note that the containers used to run the programs are not included in this repository, but should be created by the user as described below.
