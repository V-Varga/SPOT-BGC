#!/bin/bash

###
# 
# Title: snakemake_metaphlan_cohort_se.sh
# Date: 2024.11.12
# Author: Vi Varga
#
# Description: 
# This script will run MetaPhlAn per cohort on the non-human single-end reads in order to 
# perform taxonomic profiling of the reads. 
# 
# Usage: 
# 	./snakemake_metaphlan_cohort_se.sh threads
# 	OR
# 	bash snakemake_metaphlan_cohort_se.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC-working/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running MetaPhlAn
# run these in a while loop
ls results/DataNonHuman/BBNorm_Reads/*/*.SE.fq | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/Taxonomy/PerCohort/${parentname}; #create an output directory
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fq
	file_base2="${file_base%.*}"; #this line removes the file extension .SE
	file_base_id="${file_base2%_norm}"; #this removes the "_norm" substring
	# now run MetaPhlAn
	apptainer exec workflow/containers/env-metaphlan.sif metaphlan $file \
	--input_type fastq --bowtie2db /opt/conda/envs/env-metaphlan/lib/python3.7/site-packages/metaphlan/metaphlan_databases/ \
	--nproc $thread_count \
	-o results/Taxonomy/PerCohort/${parentname}/${file_base_id}__SampleTaxa.txt;
done;


# Refs: 
# MetaPhlan github: https://github.com/biobakery/MetaPhlAn
# --input_type {fastq,fasta,bowtie2out,sam}
# --nproc N The number of CPUs to use for parallelizing the mapping [default 4]
# --bowtie2db METAPHLAN_BOWTIE2_DB Folder containing the MetaPhlAn database. 
# You can specify the location by exporting the DEFAULT_DB_FOLDER variable in the shell.
