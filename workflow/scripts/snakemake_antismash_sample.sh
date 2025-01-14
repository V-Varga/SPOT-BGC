#!/bin/bash

###
# 
# Title: snakemake_antismash_sample.sh
# Date: 2024.11.10
# Author: Vi Varga
#
# Description: 
# This script will run AntiSMASH on the non-human per-sample assemblies in order to 
# predict biosynthetic gene clusters. 
# 
# Usage: 
# 	./snakemake_antismash_sample.sh threads
# 	OR
# 	bash snakemake_antismash_sample.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running AntiSMASH
# run these in a while loop
ls results/AssemblyNonHuman/PerSample/*/*/*_minContig1500.*.fa | while read file; do
	# first designate variables & directories
	parentname="$(dirname "$(dirname "$file")")"; 
	grandparent_dir="${parentname##*/}"; # this gets the grandparent/cohort directory name
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fa
	file_base2="${file_base%.*}"; #this line removes the file extension .1
	file_base_id="${file_base2%_metabat2_minContig1500}"; #this removes the "_metabat2_minContig1500" substring
	mkdir -p results/BGCs/AntiSMASH/PerSample/${grandparent_dir}/${file_base_id}; #create an output directory
	# now run AntiSMASH
	apptainer exec workflow/containers/env-antismash.sif antismash --taxon bacteria --cpus $thread_count \
	--minlength 30 --no-abort-on-invalid-records --genefinding-tool prodigal-m \
	--output-dir results/BGCs/AntiSMASH/PerSample/${grandparent_dir}/${file_base_id} \
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
