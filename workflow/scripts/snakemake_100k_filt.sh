#!/bin/bash

###
# Title: snakemake_100k_filt.sh
# Date: 2024.11.02
# Author: Vi Varga
#
# Description: 
# This script will perform the 100k reads filtration of normalized samples
# as part of the SPOT-BGC pipeline. 
# 
# Usage: 
# 	./snakemake_100k_filt.sh
# 	OR
# 	bash snakemake_100k_filt.sh
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
# 
###


# run the filtration in a loop
ls results/DataNonHuman/BBNorm_Reads/*/*.fq | while read file; do 
	parentname="$(basename "$(dirname "$file")")";
	# ref: https://superuser.com/questions/538877/get-the-parent-directory-for-a-file
	# ref: https://stackoverflow.com/questions/10992814/passing-grep-into-a-variable-in-bash
	# and check that it's >= 100k
	# ref: https://askubuntu.com/questions/1042659/how-to-check-if-a-value-is-greater-than-or-equal-to-another
	# ref: https://stackoverflow.com/questions/20360151/using-if-within-a-while-loop-in-bash
	# ref: https://askubuntu.com/questions/1096849/cant-make-new-dir-with-mkdir
	mkdir -p results/DataNonHuman/100k_Filt/${parentname};
	read_count=$(grep -c "@" $file); 
	if [[ $read_count -ge 100000 ]]; then 
		cp $file results/DataNonHuman/100k_Filt/${parentname}; 
		echo $file >> logs/100k_filt.txt;
	fi; 
done;

# for the toy dataset testing, used: 
# if [[ $read_count -ge 1 ]]; then


# after completion of the above, need to generate a new target DB
# which includes only the files that successfully passed filtration

# new full file path file
cd results/DataNonHuman/100k_Filt/;
ls */*.fq > FullFileNamesTrimmed.txt;
# get the file paths in a file
# and parse them with the python script
python ../../../workflow/scripts/create_target_db.py ../../../resources/SPOT-BGC__sample-target_info_100k.txt \
FullFileNamesTrimmed.txt noexclusion,noneexcluded;


# navigate back up to the main directory
cd ../../..;
# create an output file that marks script completion
mkdir logs/completion;
touch logs/completion/100k_filt__COMPLETE.txt;
