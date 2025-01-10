'''
============================================================================
mKmer RemoveDuplicates - pipeline for removal of repeat sequence of single-microbe RNA-seq datasets
============================================================================

Main function: 
    This module takes a fastq-file as input, which is recommended to contain extracted
    barcode and UMI information adding to the read name.

'''

#   perl RemoveDuplicates.pl -i R1_extracted.fq.gz -o R1_extracted_duplicate.fq

description = '''
Method:

    pipeline for removal of repeat sequence of single-microbe RNA-seq datasets:
        mKmer RemoveDuplicates --input [fastq.gz_file] --output [extracted_fastq.gz_filename]

    Note: The pipeline is carried out with the last 29 characters (20barcode+_+8umi) of the identifier line (the first row of 
               each four rows) as the identification. If you want to change the standard of recognized identifiers, you need to 
               change the location of "29" in the RemoveDuplicates.pl file.
 
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
    
    group = parser.add_argument_group("RemoveDuplicates-specific options")

    group.add_argument('-i', '--input', type=str, help="fastq.gz file")
    group.add_argument('-o', '--output', type=str, help="output filename")
    
    args = parser.parse_args()

    input = quote(args.input)
    output = quote(args.output)

    run_RemoveDuplicates_pl(input, output)

def run_RemoveDuplicates_pl(input, output):
    RemoveDuplicates_pl_script = os.path.join(os.path.dirname(__file__), 'RemoveDuplicates.pl')

    command = [
        'perl', RemoveDuplicates_pl_script,
        '--i', input,
        '--o', output
    ]

    result = sp.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error in RemoveDuplicates:\n{result.stderr}")
        raise RuntimeError("Command failed")

if __name__ == '__main__':
    sys.exit(main(sys.argv))