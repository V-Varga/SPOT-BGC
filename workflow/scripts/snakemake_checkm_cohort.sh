#!/bin/bash

###
# 
# Title: snakemake_checkm_cohort.sh
# Date: 2024.11.09
# Author: Vi Varga
#
# Description: 
# This script will run CheckM on the non-human per-cohort assembled MAGs in order to 
# perform quality assessment of the MAGs. 
# 
# Usage: 
# 	./snakemake_checkm_cohort.sh threads
# 	OR
# 	bash snakemake_checkm_cohort.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC-working/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running CheckM
# run these in a while loop
ls results/MAGs/PerCohort/*/*_metabat2_minContig1500.1.fa | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/MAG_QC/PerCohort/${parentname}; #create an output directory
	# now run CheckM
	apptainer exec workflow/containers/mag_assembly_qc.sif checkm lineage_wf --nt \
	-f results/MAG_QC/PerCohort/${parentname}/${parentname}_CheckM_results.txt \
	--tab_table -x fa -t $1 results/MAGs/PerCohort/${parentname} \
	results/MAG_QC/PerCohort/${parentname}; 
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
