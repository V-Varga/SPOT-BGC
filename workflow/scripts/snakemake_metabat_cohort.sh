#!/bin/bash

###
# 
# Title: snakemake_metabat_cohort.sh
# Date: 2024.11.09
# Author: Vi Varga
#
# Description: 
# This script will run MetaBAT on the non-human per-cohort assemblies in order to 
# assemble the contigs into MAGs. 
# 
# Usage: 
# 	./snakemake_metabat_cohort.sh threads
# 	OR
# 	bash snakemake_metabat_cohort.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC-working/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running MetaBAT
# run these in a while loop
ls results/AssemblyNonHuman/PerCohort/[[:upper:]]*/*_nonHuman.fasta | while read file; do
	# first designate variables & directories
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/MAGs/PerCohort/${parentname}; #create an output directory
	# now run MetaBAT
	apptainer exec workflow/containers/metagenome_assembly.sif metabat2 -i $file -m 1500 -t $thread_count \
	-o results/MAGs/PerCohort/${parentname}/${parentname}_metabat2_minContig1500; 
done;


# create an output file to mark program completion
touch logs/completion/metabat_perCohort__COMPLETE.txt;

# Refs: 
# MetaBAT manual: https://gensoft.pasteur.fr/docs/MetaBAT/2.15/
# -i [ --inFile ] arg Contigs in (gzipped) fasta file format [Mandatory]
# -o [ --outFile ] arg Base file name and path for each bin. The default output is fasta format.
# Use -l option to output only contig names [Mandatory].
# -m [ --minContig ] arg (=2500) Minimum size of a contig for binning (should be >=1500)
# -t [ --numThreads ] arg (=0) Number of threads to use (0: use all cores)
