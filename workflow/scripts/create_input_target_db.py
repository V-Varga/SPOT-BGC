#!/bin/python
# -*- coding: utf-8 -*-
"""

Title: create_input_target_db.py
Date: 2024.11.03
Author: Vi Varga

Description:
	This program parses a file containing a list of sample files names, in order
		to compile them into a database which can be used to glob wildcards in the
		SPOT-BGC Snakemake pipeline. This process includes the designation of 
		intermediate and final target file names.

List of functions:
	No functions are defined in this script.

List of standard and non-standard modules used:
	sys
	shutil
	pandas

Procedure:
	1. Loading required modules & assigning command line arguments.
	2. Setting up the formatting for the output dataframes. 
	3. Parsing the FullFileNames.txt file and extracting relevant information, 
		which is compiled into dataframes.
	4. Writing out the dataframes to tab-separated text files. 

Known bugs and limitations:
	- There is no quality-checking integrated into the code.
	- The output file names are not user-defined, but is standardized to match the
		Snakemake pipeline formatting. 
	- Note that the output files are automatically copied into the config/
		directory of the Snakemake pipeline. The script may therefore raise an error
		if that directory does not exist. 
	- This script assumes that it is run from the resources/ directory, so the copying
		process of the output file will not work if run from somewhere else.

Usage
	./create_input_target_db.py FullFileNames.txt
	OR
	python create_input_target_db.py FullFileNames.txt
	
	Where the FullFileNames.txt file should be created in the reseources/RawData directory 
		by running the following from a bash terminal command line: 
			`ls */*/* > FullFileNames.txt`
	Note that while the FullFileNames.txt file can have a different name or location than
		recommended, the internal format of the file must be as above!

This script was written for Python 3.9.19, in Spyder 5.5.5. 

"""


## Part 1: Import modules & assign command line arguments

# import necessary modules
import sys #allows execution of script from command line
import shutil # enables some bash utilities
import pandas as pd # enables the handling of dataframes in python


# load input and output files
# input file
sample_name_file = sys.argv[1]
sample_name_file = "RawData/FullFileNames.txt"

# output files
output_file_sample = "SPOT-BGC__sample-target_info.txt"
output_file_cohort = "SPOT-BGC__cohort-target_info.txt"


## Part 2: Setting up the database formats

reads_df_column_headers = ["Cohort", "Sample", "CohortSample", "CohortSampleSample",
						 # Cohort is the cohort ID, Sample is the sample ID
						 # CohortSample is Cohort/Sample, CohortSampleSample is Cohort/Sample/Sample
						 
						 "Location_Raw", "FileBase_Raw", "CohortBase_Raw", 
						 # Location_Raw is the PATH to the raw reads
						 # FileBase is the file basename without the file extension
						 # CohortBase is Cohort/FileBase
						 
						 "Location_Trim", "FileBase_Trim", "CohortBase_Trim",
						 # Location_Trim is the PATH to the trimmed reads
						 # FileBase_Trim is the file basename without the file extension for the trimmed reads
						 # CohortBase_Trim is Cohort/FileBase for the trimmed reads
						 
						 "Location_NonHuman", "FileBase_NonHuman", "CohortBase_NonHuman",
						 # Location_NonHuman is the PATH to the nonhuman reads
						 # FileBase_NonHuman is the file basename without the file extension for the nonhuman reads
						 # CohortBase_NonHuman is Cohort/FileBase for the nonhuman reads
						 
 						 "Location_Norm", "FileBase_Norm", "CohortBase_Norm",
						 # Location_Norm is the PATH to the normalized reads
						 # FileBase_Norm is the file basename without the file extension for the normalized reads
						 # CohortBase_Norm is Cohort/FileBase for the normalized reads
						 
						 "Location_100k", "FileBase_100k", "CohortBase_100k",
						 # Location_100k is the PATH to the 100k size-filtered reads
						 # FileBase_100k is the file basename without the file extension for the 100k size-filtered reads
						 # CohortBase_100k is Cohort/FileBase for the 100k size-filtered reads
						 
						 "AssemblySample_Location", "AssemblySample_FileBase", "AssemblySample_CohortBase",
						 # AssemblyCohort_Location is the location of the per-sample assembly
 						 # AssemblyCohort_FileBase is the basename of the per-sample assembly
  						 # AssemblyCohort_CohortBase is the name of the Cohort/Basename for the per-sample assembly
						 						  
						 "FiltAssemblySample_Location", "FiltAssemblySample_FileBase", "FiltAssemblySample_CohortBase",
						 # FiltAssemblyCohort_Location is the location of the nonhuman per-sample assembly
 						 # FiltAssemblyCohort_FileBase is the basename of the nonhuman per-sample assembly
  						 # FiltAssemblyCohort_CohortBase is the name of the Cohort/Basename for the nonhuman per-sample assembly
						   
						 "TaxaSample_Location", "TaxaSample_FileBase", "TaxaSample_CohortBase", 
						 # TaxaCohort_Location is the location of the taxa assignments for the per-sample assembly
 						 # TaxaCohort_FileBase is the basename of the taxa assignments for the per-sample assembly
  						 # TaxaCohort_CohortBase is the name of the Cohort/Basename of the taxa assignments for the per-sample assembly
						 
						 "GECCOSample_Location", "GECCOSample_FileBase", "GECCO_CohortBase", 
						 # AssemblyCohort_Location is the location of the GECCO assignments for the per-sample assembly
 						 # AssemblyCohort_FileBase is the basename of the GECCO assignments for the per-sample assembly
  						 # AssemblyCohort_CohortBase is the name of the GECCO assignments for the Cohort/Basename for the per-sample assembly
						 
						 "AntiSMASH_Location", "AntiSMASH_Base", "AntiSMASH_CohortBase", 
						 # AssemblyCohort_Location is the location of the AntiSMASH assignments for the per-sample assembly
 						 # AssemblyCohort_FileBase is the basename of the AntiSMASH assignments for the per-sample assembly
  						 # AssemblyCohort_CohortBase is the name of the Cohort/Basename of the AntiSMASH assignments for the per-sample assembly						 
						 
						 # the ReadNum column is 1, 2, or SE, based on the read file type
						 # this column MUST remain the last column in the dataframe
						 "ReadNum"]

assembly_df_column_headers = ["Cohort", # Cohort is the cohort ID
							  
							  "AssemblyCohort_Name", "AssemblyCohort_Location",
							   # AssemblyCohort_Name is the name of the Cohort/Basename for the per-cohort assembly
							   # AssemblyCohort_Location is the location of the per-cohort assembly
							   
							   "FiltAssemblyCohort_Name", "FiltAssemblyCohort_Location",
							   # FiltAssemblyCohort_Name is the name of the Cohort/Basename for the nonhuman per-cohort assembly
							   # FiltAssemblyCohort_Location is the location of the nonhuman per-cohort assembly

							   "TaxaCohort_Name", "TaxaCohort_Location",
							   # TaxaCohort_Name is the name of the Cohort/Basename of the taxa assignments for the per-cohort assembly
							   # TaxaCohort_Location is the location of the taxa assignments for the per-cohort assembly
							   
							   "GECCOCohort_Name", "GECCOCohort_Location",
							   # GECCOCohort_Name is the name of the Cohort/Basename of the GECCO results for the per-cohort assembly
							   # GECCOCohort_Location is the location of the GECCO results for the per-cohort assembly
							   
							   # AntiSMASHCohort_Name is the name of the Cohort/Basename  of the AntiSMASH results for the per-cohort assembly
							   # AntiSMASHCohort_Location is the location of the AntiSMASH results for the per-cohort assembly
							   "AntiSMASHCohort_Name", "AntiSMASHCohort_Location"]

# create empty dataframes with the above lists for headers
# the per-sample dataframe
target_sample_df = pd.DataFrame(columns=reads_df_column_headers)
# per-cohort assembly df
target_cohort_df = pd.DataFrame(columns=assembly_df_column_headers)


## Part 3: Parse the input data & build dataframes

with open(sample_name_file, "r") as infile: 
	# open the file for reading
	for line in infile: 
		# read through the file line by line
		line = line.strip()
		# remove the end-line character
		string_split_list = line.split('/')
		# split the string into a list based on forwardslash placement
		
		# first, get the basic information
		cohort_id = string_split_list[0]
		# save the cohort ID to a variable		
		sample_id = string_split_list[2].replace('_', '.')
		sample_id = sample_id.split('.')[0]
		# save the sample ID to a variable		
		file_base = string_split_list[2].split(".")[0]
		# save the name of the file to a variable		
		cohort_base = string_split_list[0] + "/" + file_base
		# save the basename including the cohort to a variable		
		cohort_sample = cohort_id + '/' + sample_id
		# create a base with the cohort_id/sample_id
		cohort_sample_sample = cohort_id + '/' + sample_id + '/' + sample_id
		# create a path cohort/sample/sample
		file_loc = "resources/RawData/" + line
		# save the relative file location to a variable		
		# next save the read type to a variable
		if "_1" in string_split_list[2]: 
			# designate the ending type of forward PE reads
			read_id = "1"
		elif "_2" in string_split_list[2]: 
			# designate the ending type of reverse PE reads
			read_id = "2"
		else: 
			# designate if SE instead of PE
			read_id = "SE"
		
		# target data
		
		# data for the trimmed files		
		trim_loc = "results/Trimmomatic/" + cohort_id + "/" + sample_id + "." + read_id + ".fastq"
		# location of the trimmed file		
		trim_file_base = sample_id + "." + read_id
		# basefile name of the trimmed file		
		trim_cohort_base = cohort_id + "/" + sample_id + "." + read_id
		# cohort/filebase for the trimmed sample
		
		# data for the nonhuman files		
		nonhuman_loc = "results/DataNonHuman/NonHumanOG/" + cohort_id + "/" + sample_id + "_NON-human_map." + read_id + ".fq"
		# location of nonhuman fastq file		
		nonhuman_file_base = sample_id + "_NON-human_map." + read_id
		# file basename of the nonhuman fastq		
		nonhuman_cohort_base = cohort_id + "/" + sample_id + "_NON-human_map." + read_id
		# cohort/filebase for the nonhuman fastq
		
		# data for normalization		
		norm_loc = "results/DataNonHuman/BBNorm_Reads/" + cohort_id + "/" + sample_id + "_norm." + read_id + ".fq"
		# location of the normalized file
		norm_file_base = sample_id + "_norm." + read_id
		# file basename of the normalized file
		norm_cohort_base = cohort_id + "/" + sample_id + "_norm." + read_id
		# cohort/filebase for the normalized file
		
		# data for 100k filt		
		filt_loc = "results/DataNonHuman/100k_Filt/" + cohort_id + "/" + sample_id + "_norm." + read_id + ".fq"
		# location of the 100k filt files
		filt_file_base = sample_id + "_norm." + read_id
		# file basename for the 100k file files
		filt_cohort_base = cohort_id + "/" + sample_id + "_norm." + read_id
		# cohort/basename for the 100k filt files
		
		# assembly data
		
		# per-sample assembly information		
		# data for assembly		
		assembly_sample_loc = "results/Assembly/PerSample/" + cohort_id + "/" + sample_id + "/" + sample_id + "_scaffolds.fasta"
		# location of the per-sample assembly		
		assembly_sample_base = sample_id + "_scaffolds"
		# basename for the per-sample assembly		
		assembly_cohort_base = cohort_id + "/" + sample_id + "/" + sample_id + "_scaffolds"
		# basename including cohort information
		
		# data for non-human per-sample assembly filtration
		filtassembly_sample_loc = "results/AssemblyNonHuman/PerSample/" + cohort_id + "/" + sample_id + "/" + sample_id + "_assemblySample_NON-human_map.fasta"
		# location of the nonhuman per-sample assembly
		filtassembly_sample_base = sample_id + "_assemblySample_NON-human_map"
		# basename of the nonhuman assembly
		filtassembly_cohort_base = cohort_id + "/" + sample_id + "/" + sample_id + "_assemblySample_NON-human_map"
		# cohort/filebase for the assembly
		
		# data for taxonomic assignment of the per-sample assembly
		taxa_sample_loc = "results/Taxonomy/PerSample/" + cohort_id + "/" + sample_id + "/" + sample_id + "__SampleTaxa.txt"
		# location of the taxonomy file
		taxa_sample_base = sample_id + "__SampleTaxa"
		# taxonomy report file basename
		taxa_cohort_base = cohort_id + "/" + sample_id + "/" + sample_id + "__SampleTaxa"
		# cohort/filebase for the taxonomy report
		
		# data for the GECCO assingnment of the per-sample assembly		
		gecco_sample_loc = "results/BGC_Prediction/GECCO_Results/PerSample/" + cohort_id + "/" + sample_id + "/" + sample_id + "_contigs.clusters.gff"
		# gecco report location for sample
		gecco_sample_base = sample_id + "_contigs.clusters"
		# gecco report basename for file
		gecco_cohort_base = cohort_id + "/" + sample_id + "/" + sample_id + "_contigs.clusters"
		# gecco cohort/filebase
		
		# data for the AntiSMASH assignment of the per-sample assembly		
		antis_sample_loc = "results/BGC_Prediction/AntiSMASH_Results/PerSample/" + cohort_id + "/" + sample_id + "/" + sample_id + "_persample_AntiSMASH.json"
		# location of AntiSMASH output
		antis_sample_base = sample_id + "_persample_AntiSMASH"
		# file basename for the AntiSMASH output file
		antis_cohort_base = cohort_id + "/" + sample_id + "/" + sample_id + "_persample_AntiSMASH"
		# cohort/filebasename for the AntiSMASH output
		
		# per-cohort assembly information
		
		# data for the per-cohort assembly
		cohortassembly_name = cohort_id + "_final.contigs"
		# file basename of per-cohort assembly
		cohortassembly_loc = "results/Assembly/PerCohort/" + cohort_id + "/" + cohort_id + "_final.contigs.fa"
		# location of per-cohort assembly
		
		# data for non-human per-cohort assembly filtration		
		filtcohortassembly_name = cohort_id + "_assemblyCohort_NON-human_map"
		# file basename for non-human assembly
		filtcohortassembly_loc = "results/AssemblyNonHuman/PerCohort/" + cohort_id + "/" + cohort_id + "_assemblyCohort_NON-human_map.fasta"
		# location of non-human per-cohort assembly
		
		# data for taxonomic assignment of the per-cohort assembly		
		cohorttaxa_name = cohort_id + "__CohortTaxa"
		# basename for taxanomic results file
		cohorttaxa_loc = "results/Taxonomy/PerCohort/" + cohort_id + "/" + cohort_id + "__CohortTaxa.txt"
		# location of the taxanomic profiling results file
		
		# data for the GECCO assignment of the per-cohort assembly		
		cohortgecco_name = cohort_id + "_contigs.clusters"
		# file basename for GECCO results
		cohortgecco_loc = "results/BGC_Prediction/GECCO_Results/PerCohort/" + cohort_id + "/" + cohort_id + "_contigs.clusters.gff"
		# location of the GECCO results file
		
		# data for the AntiSMASH assignment of the per-cohort assembly		
		cohortantis_name = cohort_id + "_percohort_AntiSMASH"
		# basename for the AntiSMASH results
		cohortantis_loc = "results/BGC_Prediction/AntiSMASH_Results/PerCohort/" + cohort_id + "/" + cohort_id + "_percohort_AntiSMASH.json"
		# location of the main AntiSMASH results file
		
		# summarize the information
		# put the variables that will be written out into a list
		# per-sample list
		outfile_sample_content_list = [cohort_id, sample_id, cohort_sample, cohort_sample_sample, # "Cohort", "Sample", "CohortSample", "CohortSampleSample"
						  
						  file_loc, file_base, cohort_base, # "Location_Raw", "FileBase_Raw", "CohortBase_Raw"
						  
						  trim_loc, trim_file_base, trim_cohort_base, # "Location_Trim", "FileBase_Trim", "CohortBase_Trim"
						  
						  nonhuman_loc, nonhuman_file_base, nonhuman_cohort_base, # "Location_NonHuman", "FileBase_NonHuman", "CohortBase_NonHuman"
						  
						  norm_loc, norm_file_base, norm_cohort_base, # "Location_Norm", "FileBase_Norm", "CohortBase_Norm"
						  
						  filt_loc, filt_file_base, filt_cohort_base, # "Location_100k", "FileBase_100k", "CohortBase_100k"
						  
						  assembly_sample_loc, assembly_sample_base, assembly_cohort_base, # "AssemblySample_Location", "AssemblySample_FileBase", "AssemblySample_CohortBase"
						  
						  filtassembly_sample_loc, filtassembly_sample_base, filtassembly_cohort_base, # "FiltAssemblySample_Location", "FiltAssemblySample_FileBase", "FiltAssemblySample_CohortBase"
						  
						  taxa_sample_loc, taxa_sample_base, taxa_cohort_base, # "TaxaSample_Location", "TaxaSample_FileBase", "TaxaSample_CohortBase"
						  
						  gecco_sample_loc, gecco_sample_base, gecco_cohort_base,# "GECCOSample_Location", "GECCOSample_FileBase", "GECCO_CohortBase"
						  
						  antis_sample_loc, antis_sample_base, antis_cohort_base,# "AntiSMASH_Location", "AntiSMASH_Base", "AntiSMASH_CohortBase"
						  
						  # "ReadNum"
						  read_id]
		# per-cohort list
		outfile_cohort_content_list = [cohort_id, # "Cohort"
								 
								 cohortassembly_name, cohortassembly_loc, # "AssemblyCohort_Name", "AssemblyCohort_Location"
								 
								 filtcohortassembly_name, filtcohortassembly_loc, # "FiltAssemblyCohort_Name", "FiltAssemblyCohort_Location"
								 
								 cohorttaxa_name, cohorttaxa_loc, # "TaxaCohort_Name", "TaxaCohort_Location" 
								 
								 cohortgecco_name, cohortgecco_loc, # "GECCOCohort_Name", "GECCOCohort_Location"
								 
								 # "AntiSMASHCohort_Name", "AntiSMASHCohort_Location"
								 cohortantis_name, cohortantis_loc]

		# FINALLY compile into dataframes! 
		# first the per-sample list
		target_sample_df.loc[len(target_sample_df)] = outfile_sample_content_list
		# then the per-cohort assembly df list
		target_cohort_df.loc[len(target_cohort_df)] = outfile_cohort_content_list


## Part 4: Writing out the output files

#write out to tab-separated text files
# first the per-sample file
target_sample_df.to_csv(output_file_sample, sep='\t', index=False)
# then the per-cohort assembly file
target_cohort_df.to_csv(output_file_cohort, sep='\t', index=False)

# ref: https://stackoverflow.com/questions/123198/how-to-copy-files
shutil.copyfile(output_file_sample, "../config/SPOT-BGC__sample-target_info.txt")
shutil.copyfile(output_file_cohort, "../config/SPOT-BGC__cohort-target_info.txt")
