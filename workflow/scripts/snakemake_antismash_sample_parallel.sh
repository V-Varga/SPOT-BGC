#!/bin/bash

###
# 
# Title: snakemake_antismash_sample_parallel.sh
# Date: 2025.04.28
# Author: Vi Varga
#
# Description: 
# This script will run AntiSMASH on the non-human per-sample assemblies in order to 
# predict biosynthetic gene clusters using GNU parallel. 
# 
# Usage: 
# 	./snakemake_antismash_sample_parallel.sh threads
# 	OR
# 	bash snakemake_antismash_sample_parallel.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;
# take the number of processes to execute simultaneously as a positional argument
process_num=$2;


### Running AntiSMASH
# first, create file with input file information
ls results/MAGs/PerSample/*/*/*_minContig1500.*.fa | while read file; do
	# first designate variables & directories
	parentname="$(dirname "$(dirname "$file")")"; 
	grandparent_dir="${parentname##*/}"; # this gets the grandparent/cohort directory name
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fa
	file_base2="${file_base//./_}"; # replace periods with underscores
	# ref: https://stackoverflow.com/questions/54964666/bash-shell-reworking-variable-replace-dots-by-underscore
	mkdir -p results/BGCs/AntiSMASH/PerSample/${grandparent_dir}/${file_base2}; #create an output directory
	# create input file for GNU parallel
	# ref: https://unix.stackexchange.com/questions/690160/write-two-variables-in-a-two-column-file-tab-separated
	printf "%s\t%s\t%s\t%s\n" "$file" "$file_base2" "$parentname" "$grandparent_dir" >> "results/BGCs/AntiSMASH/PerSample/GNU_parallel_files.txt";
done;

# Use GNU Parallel to parallelize AntiSMASH processing
parallel --jobs $process_num --colsep '\t' "apptainer exec workflow/containers/env-antismash.sif antismash --taxon bacteria \
--cpus $thread_count --minlength 30 --no-abort-on-invalid-records --genefinding-tool prodigal-m \
--output-dir results/BGCs/AntiSMASH/PerSample/{4}/{2} \
--fullhmmer --pfam2go {1}" ::::: results/BGCs/AntiSMASH/PerSample/GNU_parallel_files.txt


# Refs: 
# C3SE container use: https://www.c3se.chalmers.se/documentation/applications/containers/
# GNU parallel program ref: https://www.gnu.org/software/parallel/sphinx.html
# ref: https://www.gnu.org/software/parallel/parallel_examples.html
# also setting specific threads to use with `taskset`
# ref: https://unix.stackexchange.com/questions/522765/parallel-running-with-only-limited-cpu-cores
# ls results editing refs: 
# cut ref: https://stackoverflow.com/questions/10986794/remove-part-of-path-on-unix
# sed ref: https://stackoverflow.com/questions/9018723/what-is-the-simplest-way-to-remove-a-trailing-slash-from-each-parameter
# AntiSMASH Command line usage: https://docs.antismash.secondarymetabolites.org/command_line/
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
