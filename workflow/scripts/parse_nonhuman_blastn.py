#!/bin/python
# -*- coding: utf-8 -*-
"""

Title: parse_nonhuman_blastn.py
Date: 2024.11.09
Author: Vi Varga

Description:
	This program parses the result file of a command-line BLASTn run with the 
		-outfmt 6 argument, in order to remove contigs from an assembly which 
		have mapped to the human genome. It is intended to be used as part of
		blastn_perSample aand blastn_perCohort in the SPOT-BGC Snakemake pipeline.

List of functions:
	No functions are defined in this script.

List of standard and non-standard modules used:
	sys
	os
	pandas

Procedure:
	1. Loading required modules & assigning command line arguments.
	2. Loading BLASTN data into Pandas & filtering it.
	3. Creating FASTA dictionary.
	4. Filtering out the mapped sequences & writing out results.

Known bugs and limitations:
	- There is no quality-checking integrated into the code.
	- The output file names are not user-defined, but is standardized to match the
		Snakemake pipeline formatting, and therefore based on the input contig file name. 

Usage
	./parse_nonhuman_blastn.py blastn_outfile contigs_infile
	OR
	python parse_nonhuman_blastn.py blastn_outfile contigs_infile

This script was written for Python 3.9.19, in Spyder 5.5.5. 

"""


## Part 1: Import modules & assign command line arguments

# import necessary modules
import sys #allows execution of script from command line
import os #allows access to the operating system
import pandas as pd # enables the handling of dataframes in python


# load input and output files
# input files
blastn_outfile = sys.argv[1]
contigs_infile = sys.argv[2]

# output file
# remove the file path from the file name
infile_base = os.path.basename(contigs_infile)
# remove the file extension from the file name
output_base = os.path.splitext(infile_base)[0:-1]
# create the output file name
output_contigs = output_base + "_nonHuman.fasta"


## Part 2: Loading BLASTN data into Pandas & filter it

blastn_df_column_headers = ["qseqid", "sseqid", "pident", "length", "mismatch", "gapopen", 
							"qstart", "qend", "sstart", "send", "evalue", "bitscore"]

# import data into pandas dataframe
blastn_df = pd.read_csv(blastn_outfile, names=blastn_df_column_headers, sep='\t', engine='python')


# filter the blastn df to only include matches >= 100 bp in length
filt_df = blastn_df[blastn_df['length'] >= 100] 
# save the affected contigs to a list
human_seq_list = filt_df['qseqid'].tolist()


## Part 3: Create FASTA dictionary

# create an empty dectionary for sequences
fasta_dict = {}

with open(contigs_infile, "r") as infile: 
	# open the contig file for reading
	# ref: https://stackoverflow.com/questions/50856538/how-to-convert-multiline-fasta-files-to-singleline-fasta-files-without-biopython
	block = []
	# create an empty list to fill with the sequences
	for line in infile:
		# iterate over the contig file line by line
		if line.startswith('>'):
			# identify sequence header lines
			if block:
				# if the sequence list isn't empty when the FASTA header is found
				# save the sequence line to a variable
				fasta_seq = ''.join(block) + '\n'
				# write the previous FASTA header & sequence to the dictionary
				fasta_dict[fasta_header] = fasta_seq
				# empty the block list
				block = []
			# save the FASTA header to a variable
			fasta_header = line
		else:
			# for sequence lines
			# append to the block sequence list without the endline character
			block.append(line.strip())
	if block:
		# at the last line of the file
		# save the final sequence to a variable
		fasta_seq = ''.join(block) + '\n'
		# write the previous FASTA header & sequence to the dictionary
		fasta_dict[fasta_header] = fasta_seq


## Part 5: Filter out the mapped sequences & write out results

# filter out contigs that remain in the blastn database
with open(output_contigs, "w") as outfile:
	# open the outfile for writing
	for header_key in fasta_dict.keys():
		# iterate over the FASTA dictionary via its keys
		if not any(x in header_key for x in human_seq_list):
			# if this header doesn't match the list of bad IDs
			# write it out to the output FASTA file
			outfile.write(header_key + fasta_dict[header_key])
