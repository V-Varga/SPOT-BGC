#!/bin/bash

###
# Title: snakemake_metaspades_se.sh
# Date: 2024.11.03
# Author: Vi Varga
#
# Description: 
# This script will run Metaspades on single-end samples as part of the SPOT-BGC
# Snakemake pipeline, in order to perform per-sample assembly.
# 
# Usage: 
# 	./snakemake_metaspades_se.sh threads
# 	OR
# 	bash snakemake_metaspades_se.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running Metaspades
# run these in a while loop
ls results/DataNonHuman/100k_Filt/*/*.SE.fq | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/Assembly/PerSample/${parentname}; # create the directory if it doesn't exist
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fq
	file_base2="${file_base%.*}"; #this line removes the file extension .SE
	file_base_id="${file_base2%_norm}"; #this removes the "_norm" substring
	mkdir -p results/Assembly/PerSample/${parentname}/${file_base_id}; #create an output directory
	# now run the program
	apptainer exec workflow/containers/metagenome_assembly.sif spades.py \
	-s $file --checkpoints all --threads $thread_count \
	-o results/Assembly/PerSample/${parentname}/${file_base_id};
	# finally copy the primary output file to a more specific filename
	cp results/Assembly/PerSample/${parentname}/${file_base_id}/scaffolds.fasta \
	results/Assembly/PerSample/${parentname}/${file_base_id}/${file_base_id}_scaffolds.fasta;
done;


# Refs: 
# Metaspades manual: https://home.cc.umanitoba.ca/~psgendb/doc/spades/manual.html
# Usage: spades.py [options] -o <output_dir>
# -o <output_dir> directory to store all the resulting files (required)
# -1 <filename> file with forward paired-end reads
# -2 <filename> file with reverse paired-end reads
# -s <filename> file with unpaired reads
# --checkpoints <last or all> ave intermediate check-points ('last', 'all')
# -t <int>, --threads <int> number of threads. [default: 16]
# --meta this flag is required for metagenomic data
# metaspades proper doesn't work on SE reads: 
# ref: https://github.com/ablab/spades/discussions/1009
# some recommend simply using SPAdes
# ref: https://www.biostars.org/p/432620/
