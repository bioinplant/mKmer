'''
============================================================================
mKmer KmerRank - pipeline for selection of optimal number of high count K-mers
============================================================================

Main function: 
    This module takes a histo-file as input, which are the output-file of the "jellyfish histo".And then 
    this pipeline can generates "KmerRank.png", which shows the selection of optimal number of 
    high count K-mers. 

'''


description = '''
Method:

    pipeline for selection of optimal number of high count K-mers:
#     Rscript KmerRank.R --input 13mer_counts.histo --out frequency_rank/
        mKmer KmerRank --input [histo_file] --output [output_folder]

    Note: The input must be the histo file.
 
'''

import re
import os
import sys
import argparse
from shlex import quote
import subprocess as sp
import random
random.seed(42)

def main(argv):
    if argv is None:
        argv = sys.argv
    parser = argparse.ArgumentParser(
                                    usage = globals()["__doc__"],
                                    description = description,
                                    formatter_class=argparse.RawTextHelpFormatter)
    
    group = parser.add_argument_group("KmerRank-specific options")
    group.add_argument('-i', '--input', type=str, help="histo files of best K")
    group.add_argument('-o', '--output', type=str, help="output path")
    args = parser.parse_args()
    input = quote(args.input)
    output = quote(args.output) + '/'
    if not os.path.exists(output):
        os.makedirs(output)
    run_KmerRank_r(input, output)

def run_KmerRank_r(input, output):
    KmerRank_r_script = os.path.join(os.path.dirname(__file__), 'KmerRank.R')
    command = [
        'Rscript', KmerRank_r_script,
        '--input', input,
        '--out', output
    ]
    result = sp.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error in KmerRank:\n{result.stderr}")
        raise RuntimeError("Command failed")

if __name__ == '__main__':
    sys.exit(main(sys.argv))