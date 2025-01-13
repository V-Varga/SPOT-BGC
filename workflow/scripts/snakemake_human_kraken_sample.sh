#!/bin/bash

###
# Title: snakemake_human_kraken_sample.sh
# Date: 2025.01.08
# Author: Vi Varga
#
# Description: 
# This script will run Kraken2 on the per-sample assemblies in order to remove
# human contigs as part of the SPOT-BGC  Snakemake pipeline.
# 
# Usage: 
# 	./snakemake_human_kraken_sample.sh threads log_file
# 	OR
# 	bash snakemake_human_kraken_sample.sh threads log_file
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running Kraken2
# run these in a while loop
ls results/Assembly/PerSample/*/*/*_*.fasta | while read file; do
	# first designate variables & directories
	parentname="$(dirname "$(dirname "$file")")"; 
	#grandparent_dir="$(cut -d"/" -f3)"; # this gets the grandparent/cohort directory name
	grandparent_dir="${parentname##*/}"
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fasta
	file_base_id="${file_base%_scaffolds}"; #this removes the "_scaffolds" substring
	mkdir -p results/AssemblyNonHuman/PerSample/${grandparent_dir}/${file_base_id}; #create an output directory
	# now run Kraken2
	apptainer exec workflow/containers/env-kraken.sif kraken2 \
	--db resources/kraken2_human_db/ --threads $thread_count \
	--output results/AssemblyNonHuman/PerSample/${grandparent_dir}/${file_base_id}/${file_base_id}__kraken2_out.txt \
    --report results/AssemblyNonHuman/PerSample/${grandparent_dir}/${file_base_id}/${file_base_id}__kraken2_report.txt \
	--unclassified-out results/AssemblyNonHuman/PerSample/${grandparent_dir}/${file_base_id}/${file_base_id}_final.contigs_nonHuman.fasta \
    $file;
done;


# Refs: 
# Kraken2 example usage: https://hackmd.io/@AstrobioMike/kraken2-human-read-removal#Human-read-removal-with-kraken2
# Kraken2 arguments: https://software.cqls.oregonstate.edu/updates/docs/kraken2/MANUAL.html
# --db NAME Name for Kraken 2 DB
# --threads NUM Number of threads (default: 1)
# --output FILENAME Print output to filename (default: stdout); "-" will suppress normal output
# --report FILENAME Print a report with aggregrate counts/clade to file
# --unclassified-out FILENAME Print unclassified sequences to filename
