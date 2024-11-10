#!/bin/python
# -*- coding: utf-8 -*-
"""

Title: create_target_db.py
Date: 2024.11.02
Author: Vi Varga

Description:
	This program parses a list of target files created by Snakemake, in order
		to compile them into a database which can be used to glob wildcards in the
		SPOT-BGC Snakemake pipeline.

List of functions:
	No functions are defined in this script.

List of standard and non-standard modules used:
	sys
	re

Procedure:
	1. Loading required module & assigning command line arguments.
	2. Parse the list of file names and extract relevant information. Print out
		parsed results. 

Known bugs and limitations:
	- There is no quality-checking integrated into the code.
	- The output file name should match one of the target file creation rules 
		required by Snakemake for the SPOT-BGC workflow.

Usage
	./create_target_db.py outfile_name [list of target file paths]
	OR
	python create_target_db.py outfile_name [list of target file paths]
	
	Where outfile_name is the target file database required by some rule of the 
		Snakemake SPOT-BGC pipeline. 
	Where the [list of target file paths] is a list of paths to files that should 
		be parsed into the output database. 

This script was written for Python 3.9.19, in Spyder 5.5.5. 

"""


# Part 1: Import modules & assign command line arguments

# import necessary modules
import sys # allows execution of script from command line
import re # enables regex handling


# load input and output files
# output file name
output_file = sys.argv[1]
# input file
input_target_file = sys.argv[2]
# exclusion terms split into a list at commas
exclusion_terms_list = sys.argv[3].split(',')


# Part 2: Parse the input data & write out the dataframe

# read the input file into a list
with open(input_target_file, "r") as infile:
	lines = [line.rstrip() for line in infile]

# remove files from the list based on exlusion criteria
if len(exclusion_terms_list) >= 1:
	# assuming that there are exclusion terms provided
	lines = [word for word in lines if not any(bad in word for bad in exclusion_terms_list)]


with open(output_file, "w") as outfile: 
	# open the output file for writing
	# create the column headers for the file
	outfile.write("Cohort\tSample\tLocation\tCohortSample\tFileBase\tCohortBase\tReadNum\n")
	for line in lines: 
		# iterate over the elements in the list
		line = line.strip()
		# strip the end-line character from the line
		file_loc = line
		# save the file location to a variable
		new_target_list = line.split('/')
		# save the file path to a list based on forwardslash placement
		cohort_id = new_target_list[-2]
		# save the cohort ID to a variable
		sample_id = new_target_list[-1]
		sample_id = re.split('. |- |_', sample_id)[0]
		#sample_id = sample_id.split('.')[0]
		# save the sample ID to a variable
		cohort_sample = cohort_id + '/' + sample_id
		# create a base with the cohort_id/sample_id
		file_base = new_target_list[-1].rpartition(".")[0]
		# save the name of the file to a variable
		cohort_base = new_target_list[-2] + "/" + file_base
		# save the basename including the cohort to a variable
		# next save the read type to a variable
		if ".1" in new_target_list[-1]: 
			# designate the ending type of forward PE reads
			read_id = "1"
		elif ".2" in new_target_list[-1]: 
			# designate the ending type of reverse PE reads
			read_id = "2"
		else: 
			# designate if SE instead of PE
			read_id = "SE"
		# put the variables that will be written out into a list
		outfile_content_list = [cohort_id, sample_id, file_loc, cohort_sample, file_base, cohort_base, read_id]
		# finally write variables out to output file in a loop
		for i in outfile_content_list[0:-1]: 
			# iterated over the elements in the list and write them out in tab-separated format
			outfile.write(i + '\t')
		# write the last element of the list out to the outfile
		outfile.write(outfile_content_list[-1] + '\n')
