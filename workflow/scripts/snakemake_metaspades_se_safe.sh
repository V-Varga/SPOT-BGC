#!/bin/bash

###
# Title: snakemake_metaspades_se_safe.sh
# Date: 2025.01.09
# Author: Vi Varga
#
# Description: 
# This script will run Metaspades on single-end samples as part of the SPOT-BGC
# Snakemake pipeline, in order to perform per-sample assembly.
# As a backup, if MetaSPAdes runs for too long (3 days or 72 hours), the MetaSPAdes
# run will be cancelled, and MEGAHIT will be run on the sample, instead.
# 
# Usage: 
# 	./snakemake_metaspades_se_safe.sh threads
# 	OR
# 	bash snakemake_metaspades_se_safe.sh threads
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;


# creating the completion tracking file
# ref: https://unix.stackexchange.com/questions/404822/shell-script-to-create-a-file-if-it-doesnt-exist
# check if the incomplete assembly tracking file exists
if [[ ! -f results/Assembly/PerSample/Assembly_INCOMPLETE_SE.TXT ]]; then
	# if the files does not exist
	# first create the directory the file will go in
	mkdir -p results/Assembly/PerSample/;
	# then create the file to track the per-sample assemblies
    ls results/DataNonHuman/100k_Filt/*/*.SE.fq > results/Assembly/PerSample/Assembly_INCOMPLETE_SE.TXT;
fi;


### Running Metaspades
# run these in a while loop
# check if the incomplete sample tracking file exists & is not empty
if [ -s results/Assembly/PerSample/Assembly_INCOMPLETE_SE.TXT ]; then
	# read through the file line by line, i.e., file by file
	while read file; do
		# first designate variables & directories
		parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
		mkdir -p results/Assembly/PerSample/${parentname}; # create the directory if it doesn't exist
		full_file="${file##*/}"; #this line removes the path before the file name
		file_base="${full_file%.*}"; #this line removes the file extension .fq
		file_base2="${file_base%.*}"; #this line removes the file extension .SE
		file_base_id="${file_base2%_norm}"; #this removes the "_norm" substring
		mkdir -p results/Assembly/PerSample/${parentname}/${file_base_id}; #create an output directory
		# now run the program
		timeout 6h apptainer exec workflow/containers/metagenome_assembly.sif spades.py \
		-s $file --checkpoints all --threads $thread_count \
		-o results/Assembly/PerSample/${parentname}/${file_base_id};
		# check exit status of each sample
		exit_status=$?;
		# remove the file name from the tracking file
		# ref: https://askubuntu.com/questions/76808/how-do-i-use-variables-in-a-sed-command
		# ref: https://phoenixnap.com/kb/sed-delete-line
		sed -i /"$file_base_id"/d results/Assembly/PerSample/Assembly_INCOMPLETE_SE.TXT;
		# only copy the file if the exit status was successful
		if [[ $exit_status -eq 124 ]]; then
			# if the exit status of MetaSPAdes was 124, this means the process timed out
			# in this case, copy the file name to a different file tracking overly complex files
			echo "$file\n" >> results/Assembly/PerSample/Complex_files_SE.txt;
		else 
			# if MetaSPAdes completed successfully
			# copy the primary output file to a more specific filename
			cp results/Assembly/PerSample/${parentname}/${file_base_id}/scaffolds.fasta \
		results/Assembly/PerSample/${parentname}/${file_base_id}/${file_base_id}_scaffolds.fasta;
		fi;
	done < results/Assembly/PerSample/Assembly_INCOMPLETE_SE.TXT;
fi;


### Running MEGAHIT on failed samples
if [ -s Complex_files_SE.txt ]; then
# if the complex file tracking file is not empty
# ref: https://stackoverflow.com/questions/9964823/how-to-check-if-a-file-is-empty-in-bash
	while read sample_id_r1; do
		# go through the file line by line, i.e., file by file
		# designate variables
		parentname="$(basename "$(dirname "$sample_id_r1")")"; # this gets the parent/cohort directory name
		full_file="${sample_id_r1##*/}"; #this line removes the path before the file name
		file_base="${full_file%.*}"; #this line removes the file extension .fq
		file_base2="${file_base%.*}"; #this line removes the file extension .SE
		file_base_id="${file_base2%_norm}"; #this removes the "_norm" substring
		# delete the earlier-created directory
		# MEGAHIT will not run if the directory already exists
		rm -r results/Assembly/PerSample/${parentname}/${file_base_id}/;
		# now run the program
		apptainer exec workflow/containers/metagenome_assembly.sif megahit -1 $sample_id_r1 \
		-t $1 -o results/Assembly/PerSample/${parentname}/${file_base_id}/;
		# finally copy the primary output file to a more specific filename
		cp results/Assembly/PerSample/${parentname}/${file_base_id}/final.contigs.fa \
		results/Assembly/PerSample/${parentname}/${file_base_id}/${file_base_id}_final.contigs.fasta;
	done < results/Assembly/PerSample/Complex_files_SE.txt;
fi;


# Notification of completion
echo "MetaSPAdes SE run completed." > logs/MetaSPAdes/MetaSPAdes_SE_completion.txt


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
# Megahit manual: https://home.cc.umanitoba.ca/~psgendb/doc/spades/manual.html
# Usage: megahit [options] {-1 <pe1> -2 <pe2> | --12 <pe12> | -r <se>} [-o <out_dir>]
# -1 <pe1> comma-separated list of fasta/q paired-end #1 files, paired with files in <pe2>
# -2 <pe2> comma-separated list of fasta/q paired-end #2 files, paired with files in <pe1>
# -r/--read <se> comma-separated list of fasta/q single-end files
# -t/--num-cpu-threads <int> number of CPU threads [# of logical processors]
# -o/--out-dir <string> output directory [./megahit_out]
