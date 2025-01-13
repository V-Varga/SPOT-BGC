#!/bin/bash

###
# 
# Title: snakemake_gecco_sample.sh
# Date: 2024.11.10
# Author: Vi Varga
#
# Description: 
# This script will run GECCO on the non-human per-sample assemblies in order to 
# predict biosynthetic gene clusters. 
# 
# Usage: 
# 	./snakemake_gecco_sample.sh threads
# 	OR
# 	bash snakemake_gecco_sample.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running GECCO
# run these in a while loop
ls results/AssemblyNonHuman/PerSample/*/*/*_minContig1500.1.fa | while read file; do
	# first designate variables & directories
	parentname="$(dirname "$(dirname "$file")")"; 
	grandparent_dir="${parentname##*/}"; # this gets the grandparent/cohort directory name
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fasta
	file_base_id="${file_base%_scaffolds_nonHuman}"; #this removes the "_scaffolds_nonHuman" substring
	mkdir -p results/BGCs/GECCO/PerSample/${grandparent_dir}/${file_base_id}; #create an output directory
	# now run GECCO
	apptainer exec workflow/containers/env-gecco.sif gecco run --genome $file \
	-o results/BGCs/GECCO/PerSample/${grandparent_dir}/${file_base_id} --jobs $thread_count -m 0.3;
done;


# Refs: 
# GECCO GitHub with manual: https://github.com/zellerlab/GECCO
# Usage: 
# gecco run --genome some_genome.fna -o some_output_dir
# --jobs, which controls the number of threads that will be spawned by GECCO whenever a step can be parallelized. 
# The default, 0, will autodetect the number of CPUs on the machine using os.cpu_count.
# -p <p>, --p-filter <p> the p-value cutoff for protein domains to be included. [default: 1e-9]
# -m <m>, --threshold <m> the probability threshold for cluster detection. Default depends on the
# post-processing method (0.8 for gecco, 0.6 for antismash).
