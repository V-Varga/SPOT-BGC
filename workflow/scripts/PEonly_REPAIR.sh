#!/bin/bash

###
# 
# Title: PEonly_REPAIR.sh
# Date: 2026.01.28
# Author: Vi Varga
#
# Description: 
# This script will read mapping and normalization when only a paired-end cohort 
# is present in the dataset. It is intended as a temporary bug patch.
# 
# Script usage timing:
# This script should be used in between two "halves" of the full SPOT-BGC workflow:
# 	snakemake --use-singularity --omit-from filt_100k
# 	bash PEonly_REPAIR.sh threads reference_name
# 	snakemake --use-singularity
# 
# Usage: 
# 	./PEonly_REPAIR.sh threads reference_name mem_alloc [user_email]
# 	OR
# 	bash PEonly_REPAIR.sh threads reference_name mem_alloc [user_email]
# 
# 	Where: 
# 		threads = the number of threads to be used
# 		reference_name = the shortened reference name (config['reference_short'])
# 		mem_alloc = the memory allocation for BBNorm (config['bbnorm_memory'] without the '-' at the front)
# 		user_email = email address of the user to notify of completion (optional argument)
# 
# 	Note that this script is intended to be run from the parent SPOT-BGC/ directory!
#
###


# take thread count as positional argument
# ref: https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script
thread_count=$1;
reference_name=$2;
mem_alloc=$3;
user_email=$4


### Running Bowtie2
# run these in a while loop
ls results/Trimmomatic/*/*.1.fastq | while read file; do 
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fastq
	file_base2="${file_base%.*}"; #this line removes the file extension .1
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/DataNonHuman/NonHumanOG/${parentname};  #create an output directory
	apptainer exec workflow/containers/env-bowtie2.sif bowtie2 -q --end-to-end --sensitive \
	--met-file results/DataNonHuman/NonHumanOG/${parentname}/${file_base2}_Metrics.txt \
	--sam-no-qname-trunc --threads 30 --seed 7 --time -x resources/Ref/${reference_name} \
	-1 results/Trimmomatic/${parentname}/${file_base2}.1.fastq -2 results/Trimmomatic/${parentname}/${file_base2}.2.fastq \
	-S results/DataNonHuman/NonHumanOG/${parentname}/${file_base2}_human_map.sam \
	--un-conc results/DataNonHuman/NonHumanOG/${parentname}/${file_base2}_NON-human_map.fq; 
done > logs/Bowtie2_paired__REPAIR.out;


### Running BBNorm
# run these in a while loop
ls results/DataNonHuman/NonHumanOG/*/*.1.fq | while read file; do 
	full_file="${file##*/}"; #this line removes the path before the file name
	file_base="${full_file%.*}"; #this line removes the file extension .fq
	file_base2="${file_base%.*}"; #this line removes the file extension .1
	file_base3="${file_base2%_NON-human_map}"; # remove the _NON-human_map substring
	parentname="$(basename "$(dirname "$file")")"; # this gets the parent/cohort directory name
	mkdir -p results/DataNonHuman/BBNorm_Reads/${parentname};  #create an output directory
	apptainer exec workflow/containers/bbtools.sif /bbmap/bbnorm.sh -${mem_alloc} \
	in=results/DataNonHuman/NonHumanOG/${parentname}/${file_base2}.1.fq \
	in2=results/DataNonHuman/NonHumanOG/${parentname}/${file_base2}.2.fq \
	out=results/DataNonHuman/BBNorm_Reads/${parentname}/${file_base3}_norm.1.fq \
	out2=results/DataNonHuman/BBNorm_Reads/${parentname}/${file_base3}_norm.2.fq \
	target=80 min=3 threads=30 \
	hist=results/DataNonHuman/BBNorm_Reads/${parentname}/${file_base3}_NON-human_map_input_kmers.png \
	histout=results/DataNonHuman/BBNorm_Reads/${parentname}/${file_base3}_NON-human_map_output_kmers.png; 
done > logs/BBNorm_paired__REPAIR.out;


# Send user an email notifying of completion
# ref: https://askubuntu.com/questions/1401513/sendemail-with-text-in-one-line
if [[ -n "$user_email" ]]; then
    sendmail "$user_email" <<< "SPOT-BGC PE-only repair mapping and normalization complete"
fi;


# Refs: 
# Bowtie2 manual: https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml
# bowtie2-build for building the index
# Usage: bowtie2-build [options]* <reference_in> <bt2_base>
# -f The reference input files (specified as <reference_in>) are FASTA files
# --seed <int> Use <int> as the seed for pseudo-random number generator.
# --threads <int> By default bowtie2-build is using only one thread. Increasing the number of threads will speed up the index building considerably in most cases.
# bowtie2 alignment mapping
# Usage: bowtie2 [options]* -x <bt2-idx> {-1 <m1> -2 <m2> | -U <r> | --interleaved <i> | --sra-acc <acc> | b <bam>} -S [<sam>]
# -x <bt2-idx> The basename of the index for the reference genome. 
# The basename is the name of any of the index files up to but not including the final .1.bt2 / .rev.1.bt2 / etc. 
# bowtie2 looks for the specified index first in the current directory, then in the directory specified in the BOWTIE2_INDEXES environment variable.
# -1 <m1> Comma-separated list of files containing mate 1s (filename usually includes _1), e.g. -1 flyA_1.fq,flyB_1.fq. 
# Sequences specified with this option must correspond file-for-file and read-for-read with those specified in <m2>. 
# Reads may be a mix of different lengths. If - is specified, bowtie2 will read the mate 1s from the "standard in" or "stdin" filehandle.
# -2 <m2> Comma-separated list of files containing mate 2s (filename usually includes _2), e.g. -2 flyA_2.fq,flyB_2.fq. 
# Sequences specified with this option must correspond file-for-file and read-for-read with those specified in <m1>. 
# Reads may be a mix of different lengths. If - is specified, bowtie2 will read the mate 2s from the "standard in" or "stdin" filehandle.
# -U <r> Comma-separated list of files containing unpaired reads to be aligned, e.g. lane1.fq,lane2.fq,lane3.fq,lane4.fq. 
# Reads may be a mix of different lengths. If - is specified, bowtie2 gets the reads from the "standard in" or "stdin" filehandle.
# -S <sam> File to write SAM alignments to. By default, alignments are written to the "standard out" or "stdout" filehandle (i.e. the console).
# -q Reads (specified with <m1>, <m2>, <s>) are FASTQ files. FASTQ files usually have extension .fq or .fastq. 
# FASTQ is the default format. See also: --solexa-quals and --int-quals.
# --end-to-end
# In this mode, Bowtie 2 requires that the entire read align from one end to the other, without any trimming (or "soft clipping") 
# of characters from either end. The match bonus --ma always equals 0 in this mode, so all alignment scores are less than or equal to 0, 
# and the greatest possible alignment score is 0. This is mutually exclusive with --local. --end-to-end is the default mode.
# --sensitive Same as: -D 15 -R 2 -N 0 -L 22 -i S,1,1.15 (default in --end-to-end mode)
# --met-file <path> Write bowtie2 metrics to file <path>. Having alignment metric can be useful for debugging certain problems, 
# especially performance issues. See also: --met. Default: metrics disabled.
# --al <path> Write unpaired reads that align at least once to file at <path>. These reads correspond to the SAM records with the 
# FLAGS 0x4, 0x40, and 0x80 bits unset. If --al-gz is specified, output will be gzip compressed. If --al-bz2 is specified, output will be bzip2 compressed. 
# Similarly if --al-lz4 is specified, output will be lz4 compressed. Reads written in this way will appear exactly as they did in the input file, 
# without any modification (same sequence, same name, same quality string, same quality encoding). Reads will not necessarily appear in the same order as they did in the input.
# --un-conc <path> Write paired-end reads that fail to align concordantly to file(s) at <path>. 
# These reads correspond to the SAM records with the FLAGS 0x4 bit set and either the 0x40 or 0x80 bit set 
# (depending on whether it's mate #1 or #2). .1 and .2 strings are added to the filename to distinguish which file contains mate #1 and mate #2. 
# If a percent symbol, %, is used in <path>, the percent symbol is replaced with 1 or 2 to make the per-mate filenames. 
# Otherwise, .1 or .2 are added before the final dot in <path> to make the per-mate filenames. 
# Reads written in this way will appear exactly as they did in the input files, without any modification (same sequence, same name, same quality string, same quality encoding). 
# Reads will not necessarily appear in the same order as they did in the inputs.
# --al-conc <path> Write paired-end reads that align concordantly at least once to file(s) at <path>. 
# These reads correspond to the SAM records with the FLAGS 0x4 bit unset and either the 0x40 or 0x80 bit set (depending on whether it's mate #1 or #2). .1 and .2 strings 
# are added to the filename to distinguish which file contains mate #1 and mate #2. If a percent symbol, %, is used in <path>, the percent symbol is replaced with 1 or 2 to make the per-mate filenames. 
# Otherwise, .1 or .2 are added before the final dot in <path> to make the per-mate filenames. Reads written in this way will appear exactly as they did in the input files, 
# without any modification (same sequence, same name, same quality string, same quality encoding). Reads will not necessarily appear in the same order as they did in the inputs.
# --sam-no-qname-trunc Suppress standard behavior of truncating readname at first whitespace at the expense of generating non-standard SAM
# --threads NTHREADS Launch NTHREADS parallel search threads (default: 1)
# --seed <int> Use <int> as the seed for pseudo-random number generator. Default: 0.
# -t/--time Print the wall-clock time required to load the index files and align the reads. This is printed to the "standard error" ("stderr") filehandle. Default: off.
# --un-conc <path> Write paired-end reads that fail to align concordantly to file(s) at <path>. These reads correspond to the SAM records with the FLAGS 0x4 bit set 
# and either the 0x40 or 0x80 bit set (depending on whether it's mate #1 or #2).
# --un <path> Write unpaired reads that fail to align to file at <path>.

# BBMap manual: https://jgi.doe.gov/data-and-tools/software-tools/bbtools/bb-tools-user-guide/bbnorm-guide/
# target=100 (tgt) Target normalization depth. 
# if kmers are there more than 80 times, rarefy to 80
# mindepth=5 (min) Kmers with depth below this number will not be included when calculating the depth of a read.
# hist=<file> Specify a file to write the input kmer depth histogram.
# histout=<file> Specify a file to write the output kmer depth histogram.
