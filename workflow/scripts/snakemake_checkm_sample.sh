#!/bin/bash

###
# 
# Title: snakemake_checkm_sample.sh
# Date: 2024.11.09
# Author: Vi Varga
#
# Description: 
# This script will run CheckM on the non-human per-sample assembled MAGs in order to 
# perform quality assessment of the MAGs. 
# 
# Usage: 
# 	./snakemake_checkm_sample.sh threads
# 	OR
# 	bash snakemake_checkm_sample.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running CheckM
# run these in a while loop
ls results/MAGs/PerSample/*/*/*_metabat2_minContig1500.1.fa | while read file; do
	# first designate variables & directories
	parentname="$(dirname "$(dirname "$file")")"; 
	grandparent_dir="${parentname##*/}"; # this gets the grandparent/cohort directory name
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fa
	file_base2="${file_base%.*}"; #this line removes the file extension .1
	file_base_id="${file_base2%_metabat2_minContig1500}"; #this removes the "_metabat2_minContig1500" substring
	mkdir -p results/MAG_QC/PerSample/${grandparent_dir}/${file_base_id}; #create an output directory
	# now run CheckM
	apptainer exec workflow/containers/mag_assembly_qc.sif checkm lineage_wf --nt \
	-f results/MAG_QC/PerSample/${grandparent_dir}/${file_base_id}/${file_base_id}_CheckM_results.txt \
	--tab_table -x fa -t $1 \
	results/MAGs/PerSample/${grandparent_dir}/${file_base_id} \
	results/MAG_QC/PerSample/${grandparent_dir}/${file_base_id}; 
done;


# Refs: 
# CheckM workflows: https://github.com/Ecogenomics/CheckM/wiki/Workflows
# tree         -> Place bins in the reference genome tree
# tree_qa      -> Assess phylogenetic markers found in each bin
# lineage_set  -> Infer lineage-specific marker sets for each bin
# analyze      -> Identify marker genes in bins
# qa           -> Assess bins for contamination and completeness
# For convenience, the 4 mandatory steps can be executed using:
# checkm lineage_wf <bin folder> <output folder>
# lineage_wf   -> Runs tree, lineage_set, analyze, qa
# --nt generate nucleotide gene sequences for each bin
# -f, --file FILE print results to file (default: stdout)
# --tab_table print tab-separated values table
# -x, --extension EXTENSION extension of bins (other files in directory are ignored) (default: fna)
# -t, --threads THREADS number of threads (default: 1)
# bin_input directory containing bins (fasta format) or path to file describing genomes/genes - 
# tab separated in 2 or 3 columns [genome ID, genome fna, genome translation file (pep)]
# output_dir directory to write output files
