'''
============================================================================
mKmer KmerGOp - pipeline for identifying clusters with motif database (protein)
============================================================================

Main function: 
    This module takes a marker K-mer list as input, which is the output file of 
    the "FindAllMarkers" at Seurat, the number of the cluster you want to analyze.
    And this pipline requires interproscan tool (at https://ftp.ebi.ac.uk/pub/software
    /unix/iprscan/5/5.47-82.0/interproscan-5.47-82.0-64-bit.tar.gz). 

'''

description = '''
Method:

    pipeline for identifying clusters with motif database (protein):
#      bash KmerGOp.sh --cluster "$cluster_id" --input markerkmer.txt --out /path/to/output/ --interproscan /path/to/interproscan-5.47-82.0/interproscan.sh
        mKmer KmerGOp --cluster [target_cluster_number] --input [marker_K-mer_list] --output [output_folder] --interproscan [interproscan_tool]

    Note: It is recommended that the marker K-mer list contain the 
               "gene/p_val/avg_log2FC/pct.1/pct.2/p_val_adj/cluster" column.
 
'''

import re
import os
import sys
import argparse
from shlex import quote
import subprocess as sp
import shutil

# Main function to parse arguments and run the pipeline
def main(argv):
    if argv is None:
        argv = sys.argv
    parser = argparse.ArgumentParser(
        usage=globals()["__doc__"],
        description=description,
        formatter_class=argparse.RawTextHelpFormatter
    )
    group = parser.add_argument_group("KmerGOp-specific options")
    group.add_argument('-i', '--input', type=str, help="Marker K-mer list")
    group.add_argument('-o', '--output', type=str, help="Output path")
    group.add_argument('-c', '--cluster', type=str, help="Target cluster number")
    group.add_argument('-interpro', '--interproscan', type=str, help="interproscan tool")
    args = parser.parse_args()
    input = quote(args.input)
    output = quote(args.output) + '/'
    cluster = quote(args.cluster)
    interproscan = quote(args.interproscan)

    if not os.path.exists(output):
        os.makedirs(output)

    command_01_sh(cluster, input, output, interproscan)
    pep_file = f'{output.rstrip("/")}/pep.txt'
    command_02_r(cluster, input, pep_file, output, interproscan)
    fasta_file = f'{output.rstrip("/")}/cluster{cluster}_AAseq.fasta'
    interproscan_tool(interproscan, fasta_file)
    fasta_tsv_file = f'{output.rstrip("/")}/cluster{cluster}_AAseq.fasta.tsv'
    command_03_r(fasta_tsv_file, input, cluster, output)
    delete_intermediate_files(output, cluster)

# command_01: translate into protein
def command_01_sh(cluster, input, output, interproscan):
    command_01_script = os.path.join(os.path.dirname(__file__), 'KmerGOp_01.sh')
    if not os.path.isfile(command_01_script):
        raise FileNotFoundError(f"Script file not found: {command_01_script}")
    command_01 = [
        'bash', command_01_script,
        input,
        output
    ]
    result_01 = sp.run(command_01, capture_output=True, text=True)
    if result_01.returncode != 0:
        print(f"Error in Translate into protein:\n{result_01.stderr}")
        raise RuntimeError("Translate into protein failed")

# command_02: runTomTom
def command_02_r(cluster, input, pep_file, output, interproscan):
    command_02_script = os.path.join(os.path.dirname(__file__), 'KmerGOp_02.R')
    if not os.path.isfile(command_02_script):
        raise FileNotFoundError(f"R script not found: {command_02_script}")
    command_02 = [
        'Rscript', command_02_script,
        '--cluster', cluster,
        '--markerkmer', input,
        '--pep', pep_file,
        '--out', output
    ]
    result_02 = sp.run(command_02, capture_output=True, text=True)
    if result_02.returncode != 0:
        print(f"Error in runTomTom:\n{result_02.stderr}")
        raise RuntimeError("runTomTom failed")

# interproscan
def interproscan_tool(interproscan, fasta_file):
    command_interproscan = f'{interproscan} -i {fasta_file} -f tsv -goterms'
    print(f"Running interproscan with command: {command_interproscan}")
    try:
        result_interproscan = sp.run(command_interproscan, shell=True, check=True, capture_output=True, text=True)
        print(f"interproscan completed successfully.\n{result_interproscan.stdout}")
    except sp.CalledProcessError as e:
        print(f"Error in interproscan:\n{e.stderr}")
        raise RuntimeError("interproscan failed") from e

# command_03: enrich GO
def command_03_r(fasta_tsv_file, input, cluster, output):
    command_03_script = os.path.join(os.path.dirname(__file__), 'KmerGOp_03.R')
    if not os.path.isfile(command_03_script):
        raise FileNotFoundError(f"R script not found: {command_03_script}")
    command_03 = [
        'Rscript', command_03_script,
        '--tsv', fasta_tsv_file,
        '--markerkmer', input,
        '--cluster', cluster,
        '--out', output
    ]
    result_03 = sp.run(command_03, capture_output=True, text=True)
    if result_03.returncode != 0:
        print(f"Error in GO_Annotations_03:\n{result_03.stderr}")
        raise RuntimeError("GO_Annotations 03 failed")

# Delete intermediate files after processing
def delete_intermediate_files(output, cluster):    
    files_to_delete = [f"pep.txt", f"cluster{cluster}.meme", f"cluster{cluster}.txt", f"cluster{cluster}_AAseq.fasta", f"cluster{cluster}_AAseq.fasta.tsv"]
    for file_name in files_to_delete:
        file_path = os.path.join(output, file_name)
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Deleted file: {file_path}")

if __name__ == '__main__':
    sys.exit(main(sys.argv))