'''
============================================================================
mKmer KmerFrequency - pipeline for choice of the best K value
============================================================================

Main function: 
    This module takes three histo-files as input, which are the output-file of the "jellyfish histo".And then 
    this pipeline can generates "KmerFrequency.png", which shows the distribution of K-mer for different 
    K values. 

'''

description = '''
Method:

    pipeline for choice of the best K value:
#     Rscript KmerFrequency.R --input 11mer_counts.histo,12mer_counts.histo,13mer_counts.histo --out frequency_rank/
        mKmer KmerFrequency --input [histo_file1] [histo_file2] [histo_file3] --output [output_folder]

    Note: The input must be three histo files.
 
'''

import re
import os
import sys
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
    
    group = parser.add_argument_group("KmerFrequency-specific options")
    group.add_argument('-i', '--input', type=str, nargs='+', help="list of histo files")
    group.add_argument('-o', '--output', type=str, help="output folder")
    args = parser.parse_args()
    input = ','.join(args.input)
    output = quote(args.output) + '/'
    if not os.path.exists(output):
        os.makedirs(output)
    run_KmerFrequency_r(input, output)

def run_KmerFrequency_r(input, output):
    KmerFrequency_r_script = os.path.join(os.path.dirname(__file__), 'KmerFrequency.R')
    command = [
        'Rscript', KmerFrequency_r_script,
        '--input', input,
        '--out', output
    ]
    result = sp.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error in KmerFrequency:\n{result.stderr}")
        raise RuntimeError("Command failed")

if __name__ == '__main__':
    sys.exit(main(sys.argv))