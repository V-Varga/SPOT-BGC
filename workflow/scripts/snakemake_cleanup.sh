#!/bin/bash

###
# Title: snakemake_cleanup.sh
# Date: 2025.10.13
# Author: Vi Varga
#
# Description: 
# This script will clean the SPOT-BGC directory of results and log 
# files created after a run, prior to a new one.
# 
# Usage: 
# 	./snakemake_cleanup.sh
# 	OR
# 	bash snakemake_cleanup.sh
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# Remove all log and results files
rm -r logs/;
rm -r results/;
rm -r resources/RawData/;
rm -r resources/kraken2_human_db/;
rm resources/Ref/*.bt2;
rm resources/*.txt;
rm config/*.txt;

# Recreate the RawData/ directory
mkdir -p resources/RawData/;
