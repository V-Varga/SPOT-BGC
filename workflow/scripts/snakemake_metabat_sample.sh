#!/bin/bash

###
# 
# Title: snakemake_metabat_sample.sh
# Date: 2024.11.09
# Author: Vi Varga
#
# Description: 
# This script will run MetaBAT on the non-human per-sample assemblies in order to 
# assemble the contigs into MAGs. 
# 
# Usage: 
# 	./snakemake_metabat_sample.sh threads
# 	OR
# 	bash snakemake_metabat_sample.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


### Running MetaBAT
# run these in a while loop
ls results/AssemblyNonHuman/PerSample/*/[[:upper:]]*/*_nonHuman.fasta | while read file; do
	# first designate variables & directories
	parentname="$(dirname "$(dirname "$file")")"; 
	grandparent_dir="${parentname##*/}"; # this gets the grandparent/cohort directory name
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fasta
 	# ref: https://unix.stackexchange.com/questions/53310/splitting-string-by-the-first-occurrence-of-a-delimiter
	file_base_id="$( cut -d "_" -f 1 <<< "$file_base" )"; #this selects only the sample ID from the name
	mkdir -p results/MAGs/PerSample/${grandparent_dir}/${file_base_id}; #create an output directory
	# now run MetaBAT
	apptainer exec workflow/containers/metagenome_assembly.sif metabat2 -i $file -m 1500 -t $thread_count \
	-o results/MAGs/PerSample/${grandparent_dir}/${file_base_id}/${file_base_id}_metabat2_minContig1500; 
done;


# create an output file to mark program completion
touch logs/completion/metabat_perSample__COMPLETE.txt;


# Refs: 
# MetaBAT manual: https://gensoft.pasteur.fr/docs/MetaBAT/2.15/
# -i [ --inFile ] arg Contigs in (gzipped) fasta file format [Mandatory]
# -o [ --outFile ] arg Base file name and path for each bin. The default output is fasta format.
# Use -l option to output only contig names [Mandatory].
# -m [ --minContig ] arg (=2500) Minimum size of a contig for binning (should be >=1500)
# -t [ --numThreads ] arg (=0) Number of threads to use (0: use all cores)
