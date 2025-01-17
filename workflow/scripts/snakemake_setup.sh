#!/bin/bash

###
# Title: snakemake_setup.sh
# Date: 2025.01.16
# Author: Vi Varga
#
# Description: 
# This script will generate the files needed to begin running the 
# SPOT-BGC pipeline.
# 
# Usage: 
# 	./snakemake_setup.sh
# 	OR
# 	bash snakemake_setup.sh
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# Navigate to the correct directory
cd resources/RawData/
# generate the file names file
ls */*/*.fastq > FullFileNames.txt
# navigate back up to resources/
cd ..

# run the python script below
python ../workflow/scripts/create_input_target_db.py RawData/FullFileNames.txt
# and navigate back up to the main directory
cd ..
