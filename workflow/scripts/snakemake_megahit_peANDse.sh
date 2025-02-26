#!/bin/bash

###
# Title: snakemake_megahit_peANDse.sh
# Date: 2025.01.16
# Author: Vi Varga
#
# Description: 
# This script will run MEGAHIT on cohorts that contain both paired-end and single-end 
# samples as part of the SPOT-BGC Snakemake pipeline, in order to perform per-cohort assembly.
# 
# Usage: 
# 	./snakemake_megahit_peANDse.sh threads
# 	OR
# 	bash snakemake_megahit_peANDse.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


# create the results directory if it doesn't exist
mkdir -p results/Assembly/PerCohort; 


# Creating tracking files
# get SE directory names
ls results/DataNonHuman/BBNorm_Reads/*/*.SE.fq | while read file; do
	# find the SE file cohorts
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	# write the paths to the input firectories to a file
	echo "results/DataNonHuman/BBNorm_Reads/${parentname}/" >> results/Assembly/PerCohort/MEGAHIT_Tracking_SE_tmp.txt;
done;

# get PE directory names
ls results/DataNonHuman/BBNorm_Reads/*/*.1.fq | while read file; do
	# find the SE file cohorts
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	# write the paths to the input firectories to a file
	echo "results/DataNonHuman/BBNorm_Reads/${parentname}/" >> results/Assembly/PerCohort/MEGAHIT_Tracking_PE_tmp.txt;
done;

# remove duplicate lines from the files
# ref: https://unix.stackexchange.com/questions/30173/how-to-remove-duplicate-lines-inside-a-text-file
# SE tracking
awk '!seen[$0]++' results/Assembly/PerCohort/MEGAHIT_Tracking_SE_tmp.txt > results/Assembly/PerCohort/MEGAHIT_Tracking_SE.txt;
# delete temporary file
rm results/Assembly/PerCohort/MEGAHIT_Tracking_SE_tmp.txt;
# PE tracking
awk '!seen[$0]++' results/Assembly/PerCohort/MEGAHIT_Tracking_PE_tmp.txt > results/Assembly/PerCohort/MEGAHIT_Tracking_PE.txt;
# delete temporary file
rm results/Assembly/PerCohort/MEGAHIT_Tracking_PE_tmp.txt;

# find overlap between both files
# ref: https://stackoverflow.com/questions/47116079/comparing-two-files-in-bash-line-by-line
awk 'NR == FNR { lines[NR] = $0 } NR != FNR && lines[FNR] == $0 { print }' \
results/Assembly/PerCohort/MEGAHIT_Tracking_SE.txt results/Assembly/PerCohort/MEGAHIT_Tracking_PE.txt \
> results/Assembly/PerCohort/MEGAHIT_Tracking_PEandSE.txt


### Running MEGAHIT
# run these in a while loop
while read line; do
	# designate variables
	parentname="$(echo "$line" | cut -d "/" -f 4)"; # this gets the parent/cohort directory name
	mkdir -p results/Assembly/PerCohort; # create the directory if it doesn't exist
	# identify files
	# ref: https://merenlab.org/tutorials/assembly-based-metagenomics/
	R1s=`ls ${line}*.1.fq | python -c 'import sys; print(",".join([x.strip() for x in sys.stdin.readlines()]))'`;
	R2s=`ls ${line}*.2.fq | python -c 'import sys; print(",".join([x.strip() for x in sys.stdin.readlines()]))'`;
	RSs=`ls ${line}*.SE.fq | python -c 'import sys; print(",".join([x.strip() for x in sys.stdin.readlines()]))'`;
	# now run the program
	apptainer exec workflow/containers/metagenome_assembly.sif megahit -1 $R1s -2 $R2s -r $RSs -t $1 \
	-o results/Assembly/PerCohort/${parentname}/;
	# finally copy the primary output file to a more specific filename
	cp results/Assembly/PerCohort/${parentname}/final.contigs.fa results/Assembly/PerCohort/${parentname}/${parentname}_final.contigs.fa;
done < results/Assembly/PerCohort/MEGAHIT_Tracking_PEandSE.txt;


# Notification of completion
echo "MEGAHIT PE run completed." > logs/MEGAHIT/MEGAHIT_PEandSE_completion.txt


# Refs: 
# Megahit manual: https://home.cc.umanitoba.ca/~psgendb/doc/spades/manual.html
# Usage: megahit [options] {-1 <pe1> -2 <pe2> | --12 <pe12> | -r <se>} [-o <out_dir>]
# -1 <pe1> comma-separated list of fasta/q paired-end #1 files, paired with files in <pe2>
# -2 <pe2> comma-separated list of fasta/q paired-end #2 files, paired with files in <pe1>
# -r/--read <se> comma-separated list of fasta/q single-end files
# -t/--num-cpu-threads <int> number of CPU threads [# of logical processors]
# -o/--out-dir <string> output directory [./megahit_out]
