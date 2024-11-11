#!/bin/bash

###
# Title: snakemake_human_blast_cohort.sh
# Date: 2024.11.08
# Author: Vi Varga
#
# Description: 
# This script will run BLASTN on the per-cohort assemblies in order to remove
# human contigs as part of the SPOT-BGC  Snakemake pipeline.
# 
# Usage: 
# 	./snakemake_human_blast_cohort.sh threads log_file
# 	OR
# 	bash snakemake_human_blast_cohort.sh threads log_file
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC-working/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;
# take logfile name as positional argument
LOGFILENAME=$2;


### Running BLASTN
# run these in a while loop
ls results/Assembly/PerCohort/*/*_final.contigs.fa | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fa
	file_base_id="${file_base%_final.contigs}"; #this removes the "_final.contigs" substring
	mkdir -p results/AssemblyNonHuman/PerCohort/${parentname}; #create an output directory
	# now run BLASTN
	apptainer exec workflow/containers/mag_assembly_qc.sif blastn -query $file -task blastn \
	-db resources/Ref/GCA_000001405.29_GRCh38.p14_genomic_hardMask.fasta \
	-out results/AssemblyNonHuman/PerCohort/${parentname}/${file_base_id}__blast_table.txt \
	-perc_identity 90 -num_threads $thread_count -outfmt 6;
	# then parse the output results file
	python workflow/scripts/parse_nonhuman_blastn.py \
	results/AssemblyNonHuman/PerCohort/${parentname}/${file_base_id}__blast_table.txt \
	$file $LOGFILENAME;
	mv ${file_base_id}_final.contigs_nonHuman.fasta results/AssemblyNonHuman/PerCohort/${parentname};
done;


# Refs: 
# BLAST arguments: https://www.ncbi.nlm.nih.gov/books/NBK279690/
# -query <File_In> Input file name
# -task <String, Permissible values: 'blastn' 'blastn-short' 'dc-megablast' 'megablast' 'rmblastn'
# -db <String> BLAST database name
# -out <File_Out, file name length < 256> Output file name
# -outfmt <String> 6 = Tabular
# -perc_identity <Real, 0..100> Percent identity
# -num_threads <Integer, >=1> Number of threads (CPUs) to use in the BLAST search
