'''
============================================================================
mKmer KmerCell - cell-by-kmer matrix construction
============================================================================

Main function: 
    This module takes fasta and fastq file as input. The fasta file is the output file of the "jellyfish count".The fastq 
    file is recommended to contain extracted barcode and UMI information adding to the read name . And then 
    this pipeline can generates cell-by-kmer matrix in a sample. 

'''

description = '''
Method:

    cell-by-kmer matrix construction:
        mKmer KmerCell --fasta [kmercountsdumpsfasta_file] --fastq [R2fastq_file] --topkmer [number of high count K-mers_value] --k [bestK_value] --output [out_folder]

    Note: Sample file is the R2 end file of fastq which contain extracted barcode and UMI information adding to the 
    read name. The name of the kmercount fasta file should be "kmer_counts_dumps.fa".
 
'''

import re
import os, sys
import argparse
from shlex import quote
import subprocess as sp

def main(argv):
    if argv is None:
        argv = sys.argv
    parser = argparse.ArgumentParser(
                                    usage = globals()["__doc__"],
                                    description = description,
                                    formatter_class=argparse.RawTextHelpFormatter)
    group = parser.add_argument_group("KmerCell-specific options")
    group.add_argument('-fa', '--fasta', type = str, default = None, help="kmer counts dumps fasta file path")
    group.add_argument('-fq', '--fastq', type = str, default = None, help="R2 end fastq file path")
    group.add_argument('-t', '--topkmer', type = str, default = None, help="Number of high count K-mers")
    group.add_argument('-k', '--bestK', type = str, default = None, help="The best K value")
    group.add_argument('-o', '--output', type = str, default = None, help="output folder name")
    args = parser.parse_args()
    fasta = quote(args.fasta)
    fastq = quote(args.fastq)
    topkmer = quote(args.topkmer)
    bestK = quote(args.bestK)
    output = quote(args.output)
    output_with_slash = output if output.endswith('/') else output + '/'
    if not os.path.exists(output):
        os.makedirs(output)

# KmerCell_01
    KmerCell_script = os.path.join(os.path.dirname(__file__), 'KmerCell_01.py')
    command_01 = [
        'python', KmerCell_script,
        '--kmercount', fasta,
        '--fastq', fastq,
        '--topkmer', topkmer,
        '--k', bestK,
        '--output', output_with_slash
    ]   
    result_01 = sp.run(command_01, capture_output=True, text=True)
    if result_01.returncode != 0:
        print(f"Error in KmerCell_01:\n{result_01.stderr}")
        raise RuntimeError("Command 1 failed")

# KmerCell_02
    run_KmerCell_r(output_with_slash)
def run_KmerCell_r(output_with_slash):
    KmerCell_r_script = os.path.join(os.path.dirname(__file__), 'KmerCell_02.R')
    command_02 = [
        'Rscript', KmerCell_r_script,
        '--folder', output_with_slash
    ]
    result_02 = sp.run(command_02, capture_output=True, text=True)
    if result_02.returncode != 0:
        print(f"Error in KmerCell_02:\n{result_02.stderr}")
        raise RuntimeError("Command 2 failed")

if __name__ == '__main__':
    sys.exit(main(sys.argv))