#!/bin/bash

###
# 
# Title: snakemake_checkm_taxa_cohort.sh
# Date: 2025.01.09
# Author: Vi Varga
#
# Description: 
# This script will run CheckM on the non-human per-cohort assembled MAGs in order to 
# perform taxonomic profiling. 
# 
# Usage: 
# 	./snakemake_checkm_taxa_cohort.sh threads
# 	OR
# 	bash snakemake_checkm_taxa_cohort.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC-working/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running CheckM

# download the taxonomy list 
apptainer exec workflow/containers/mag_assembly_qc.sif checkm taxon_list;


# run these in a while loop
ls results/MAGs/PerCohort/*/*_metabat2_minContig1500.1.fa | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/MAG_QC/PerCohort/${parentname}; #create an output directory
	# now run CheckM
	apptainer exec workflow/containers/mag_assembly_qc.sif checkm taxonomy_wf \
	-x fa -t $1 domain Bacteria results/MAGs/PerCohort/${parentname} \
	results/Taxonomy/PerCohort/${parentname}; 
done;


# Refs: 
# CheckM workflows: https://github.com/Ecogenomics/CheckM/wiki/Workflows
# checkm taxonomy_wf <rank> <taxon> <bin folder> <output folder>
# taxonomy_wf   -> Generate taxonomic-specific marker set
# -x, --extension EXTENSION extension of bins (other files in directory are ignored) (default: fna)
# -t, --threads THREADS number of threads (default: 1)
# bin_input directory containing bins (fasta format) or path to file describing genomes/genes - 
# tab separated in 2 or 3 columns [genome ID, genome fna, genome translation file (pep)]
# output_dir directory to write output files
