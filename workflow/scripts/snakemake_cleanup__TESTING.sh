#!/bin/bash

###
# Title: snakemake_cleanup__TESTING.sh
# Date: 2026.01.06
# Author: Vi Varga
#
# Description: 
# This script will clean the SPOT-BGC directory of results and log 
# files created after a run, prior to a new one.
# Note that this is a developer testing script! Unlike the regular 
# snakemake_cleanup.sh script, it will not delete raw data files!
# 
# Usage: 
# 	./snakemake_cleanup__TESTING.sh
# 	OR
# 	bash snakemake_cleanup__TESTING.sh
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# Remove all log and results files
rm -r logs/;
rm -r results/;
rm -r resources/RawData/FullFileNames.txt;
rm -r resources/kraken2_human_db/;
rm resources/Ref/*.bt2;
rm resources/*.txt;
rm config/*.txt;

# Recreate the RawData/ directory
mkdir -p resources/RawData/;
