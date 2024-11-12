#!/bin/python
# -*- coding: utf-8 -*-
"""

Title: hard_mask_genome.py
Date: 2024.03.12
Author: Vi Varga

Description:
	This program parses a soft-masked FASTA file and hard-masks the soft-masked 
		portions by replacing all lowercase characters in sequence lines with 'N'.

List of functions:
	No functions are defined in this script.

List of standard and non-standard modules used:
	sys
	os
	re

Procedure:
	1. Loading required modules & assigning command line arguments.
    2. Parsing FASTA file & writing out hard-masked version.

Known bugs and limitations:
	- There is no quality-checking integrated into the code.
	- The output file name is not user-defined, but is instead simply the input
		file basename with a "_hardMask.fasta" file extension. 

Usage
	./hard_mask_genome.py input_fasta
	OR
	python hard_mask_genome.py input_fasta

This script was written for Python 3.9.18, in Spyder 5.4.5. 

"""


# Part 1: Import modules & assign command line arguments

# import necessary modules
import sys # allows execution of script from command line
import os # allows access to the operating system
import re # enable regex pattern matching in Python


# load input file
input_fasta = sys.argv[1]

# load output file
base = os.path.basename(input_fasta)
output_base = os.path.splitext(base)[0]
output_fasta = output_base + '_hardMask.fasta'


# Part 2: Parse FASTA file & write out hard-masked version

with open(input_fasta, "r") as infile, open(output_fasta, "w") as outfile:
	# open the input file for reading & output file for writing
	for line in infile: 
		# parse through the input file line by line
		if not line.startswith(">"): 
			# identify lines that aren't headers
			sequence = line
			# save the line to a variable
			sequence_edit = re.sub('[a-z]', 'N', sequence)
			# replace all lowercase characters with N characters
			# and write out to the output file
			outfile.write(sequence_edit)
		else: 
			# for the sequence header lines
			header = line
			# save the line content to a variable 
			# and write it out to the outfile
			outfile.write(header)
