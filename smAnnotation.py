'''
============================================================================
mKmer smAnnotation - taxonomic annotation for each microbe in genus or species level
============================================================================

Main function: 
    This module takes a R2 fastq-file as input, which is recommended to contain extracted
    barcode and UMI information adding to the read name (Using the removed fastq-file
    may result in more accurate results). Reference datasets recommends the corresponding
    kracken2 datasets (like ncbi_standard at https://benlangmead.github.io/aws-indexes/k2).

'''

#   bash smAnnotation.sh --input R2_extracted_duplicate.fq --db /path/to/kracken2_db --K2Rtool /path/to/kraken2-report --output smAnnotation

description = '''
Method:

    taxonomic annotation for each microbe in genus or species level:
        mKmer smAnnotation --input [fastq.gz_file] --db [kracken2_databases] --K2Rtool [kraken2-report_tool] --output [out_folder]

    Note:  Sample file is the R2 end file of fastq which contain extracted barcode and UMI information adding to the 
    read name. And the databases (db) folder is the datasets collected by kracken2. The K2Rtool is the "kraken2-report"
    file in the "kraken2-report" folder.
'''

import os
import sys
import argparse
import subprocess as sp

def main(argv):
    if argv is None:
        argv = sys.argv

    parser = argparse.ArgumentParser(
                                    usage = globals()["__doc__"],
                                    description = description,
                                    formatter_class=argparse.RawTextHelpFormatter)
    
    group = parser.add_argument_group("smAnnotation-specific options")
    group.add_argument('-i', '--input', type=str, help="fastq.gz file")
    group.add_argument('-o', '--output', type=str, help="output filename")
    group.add_argument('-d', '--db', type=str, help="kracken2_databases")
    group.add_argument('-k', '--K2Rtool', type=str, help="kraken2-report_tool (default: kraken2-report in the script's directory)")

    args = parser.parse_args()
    input_file = args.input
    output_file = args.output
    db = args.db
    K2Rtool = args.K2Rtool

    run_smAnnotation_sh(input_file, db, K2Rtool, output_file)

def run_smAnnotation_sh(input_file, db, K2Rtool, output_file):
    smAnnotation_sh_script = os.path.join(os.path.dirname(__file__), 'smAnnotation.sh')

    command = [
        'bash', smAnnotation_sh_script,
        '--input', input_file,
        '--db', db,
        '--K2Rtool', K2Rtool,
        '--output', output_file
    ]

    result = sp.run(command, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"Error in smAnnotation:\n{result.stderr}")
        print(f"Command Output:\n{result.stdout}")
        raise RuntimeError("Command failed")

if __name__ == '__main__':
    sys.exit(main(sys.argv))