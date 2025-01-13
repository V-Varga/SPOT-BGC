#!/bin/bash

###
# 
# Title: snakemake_antismash_cohort.sh
# Date: 2024.11.10
# Author: Vi Varga
#
# Description: 
# This script will run AntiSMASH on the non-human per-cohort assemblies in order to 
# predict biosynthetic gene clusters. 
# 
# Usage: 
# 	./snakemake_antismash_cohort.sh threads
# 	OR
# 	bash snakemake_antismash_cohort.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC-working/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running AntiSMASH
# run these in a while loop
ls results/AssemblyNonHuman/PerCohort/*/*_minContig1500.1.fa | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/BGCs/AntiSMASH/PerCohort/${parentname}; #create an output directory
	# now run AntiSMASH
	apptainer exec workflow/containers/env-antismash.sif antismash --taxon bacteria --cpus $thread_count \
	--minlength 30 --no-abort-on-invalid-records --genefinding-tool prodigal-m \
	--output-dir results/BGCs/AntiSMASH/PerCohort/${parentname} \
	--fullhmmer --pfam2go $file;
done;


# Refs: 
# C3SE container use: https://www.c3se.chalmers.se/documentation/applications/containers/
# Command line usage: https://docs.antismash.secondarymetabolites.org/command_line/
# -t {bacteria,fungi}, --taxon {bacteria,fungi} Taxonomic classification of input sequence. (default: bacteria)
# -c CPUS, --cpus CPUS  How many CPUs to use in parallel. (default for this machine: 80)
# -databases PATH  Root directory of the databases (default: /opt/conda/envs/env-antismash/lib/python3.10/site-packages/antismash/databases).
# --output-dir OUTPUT_DIR  Directory to write results to.
# --fullhmmer  Run a whole-genome HMMer analysis using Pfam profiles.
# --pfam2go  Run Pfam to Gene Ontology mapping module.
# --genefinding-tool {glimmerhmm,prodigal,prodigal-m,none,error}
# Specify algorithm used for gene finding: GlimmerHMM, Prodigal, Prodigal Metagenomic/Anonymous mode, or none. 
# The 'error' option will raise an error if genefinding is attempted. The 'none' option will not run genefinding. (default: error).
# --minlength MINLENGTH  Only process sequences larger than <minlength> (default: 1000).
# --abort-on-invalid-records, --no-abort-on-invalid-records  Abort runs when encountering invalid records instead of skipping them (default: True)
