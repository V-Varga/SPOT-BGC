![SPOT-BGC logo](./img/spot-bgc_logo.png)

# SPOT-BGC

_A Snakemake Pipeline to Output meTagenomics-derived Biosynthetic Gene Clusters_

Author: Vi Varga

Last Update: 2024.11.11


## Pipeline summary & status

### Introduction 

The SPOT-BGC pipeline is designed to process metagenomic FASTQ read data, eliminate human contamination, and assemble bacterial genomes; in order to predict Biosynthetic Gene Clusters (BGCs) present in the data. Metagenome-Assembled Genomes (MAGs) are produced during an intermediate step of this pipeline.

This pipeline can process both paired-end (PE) and single-end (SE) FASTQ input. In order to preserve as much data as possible, assembly is performed on both a per-sample and per-cohort basis. 


### Pipeline status

Initial publication, 2024.11.13: Build Alpha (ver. 0.9)
 - The SPOT-BGC pipeline is functional, with the human genome as the reference genome. 
 - Note that while it has been successfully run for the analysis it was designed for, extensive testing of the pipeline has not been carried out.
 - At this stage, most users will need to modify the `config.yaml` file manually in order to change the reference genome, as well as modify the `Snakefile` manually in order to change the settings/arguments of the various programs. 
 - Note that the containers used to run the programs are not included in this repository, but should be created by the user as described below.


## Pipeline structure

The SPOT-BGC pipeline performs the following on input metagenomic FASTQ reads: 
1. Quality assessment: FastQC, MultiQC
2. Quality trimming: Trimmomatic
3. Human read filtration by mapping to the human genome: Bowtie2
4. Normalization of read counts: BBNorm
5. For the per-sample assemblies, sample IDs with <100k reads remaining are filtered out
6. Assembly: per-sample with SPAdes, per-cohort with MEGAHIT
7. Human contig elimination (sanity check): BLASTN
8. Binning of contigs into MAGs: MetaBAT
9. Quality assessment of the MAGs: CheckM
10. Taxonomic assignments of assemblies: MetaPhlAn
11. BGC predictions: GECCO, AntiSMASH


## Dependencies

The primary dependencies of the SPOT-BGC pipeline are: 
 - Snakemake
 - Apptainer


## Running SPOT-BGC

Owing to a temporary bug in Snakemake at the time of this pipeline's creation, the programs used must be run out of containers, rather than via `conda` environments [Ref](https://github.com/snakemake/snakemake/issues/3163). All files necessary to generate the containers are included in this repository. 

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
# QC of MAGs
apptainer build --build-arg ENV_FILE=../envs/mag_assembly_qc.yml mag_assembly_qc.sif ../scripts/conda_environment_args_ubuntu.def
# taxonomy with MetaPhlAn
apptainer build --build-arg ENV_FILE=../envs/env-metaphlan.yml env-metaphlan.sif ../scripts/conda_environment_args_ubuntu-metaphlan.def
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
 - The COHORT_ID is intended to be the NCBI BioProject number, but can be designated by the user however you wish. However, a cohort **must** be provided for every sample.
 - The sample raw FASTQ files should be in directories with the sample name. This is the structure that results if the data is downloaded directly from the NCBI with SRA (Sequence Read Archive) `fetch`.
 - The REFERENCE should be a DNA reference genome. Modify the `config.yaml` file located in the `config/` directory with your reference genome name.
 - As is illustrated, the SPOT-BGC pipeline works with both PE and SE input FASTQ files. Note, however, that PE and SE reads from the same cohort ID will _not_ be assembled into one cohort assembly. The per-cohort assemblies use either SE or PE reads, so in the case that your cohort contains both PE and SE reads, the pipeline will attempt to create two separate per-cohort assemblies. This will likely result in errors!

Once you have organized your project as illustrated above, you will need to generate a data table that the `Snakefile` will take as input in order to handle wildcards in the file names. Please run the following in your terminal: 

```bash
# navigate to resources/RawData/
cd resources/RawData/
ls */*/*.fastq > FullFileNames.txt
# navigate back up to resources/
cd ..
# run the python script below
python ../workflow/scripts/create_input_target_db.py RawData/FullFileNames.txt

```

At this stage, you should be able to run the SPOT-BGC pipeline from the main directory (i.e., the directory where `config/`, `resources/` and `workflow/` are located), as follows: 

```bash
# activate your conda snakemake environment
conda activate snakemake
# and run the pipeline
snakemake --use-singularity --cores {NUMBER_OF_CORES}
# note that when working on a server, 
# you can specify the specific cores used with `taskset`

```
