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
import random
random.seed(42)

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

    command_01_py(cluster, input, output, interproscan)
    pep_file = f'{output.rstrip("/")}/pep.txt'
    command_02_r(cluster, input, pep_file, output, interproscan)
    fasta_file = f'{output.rstrip("/")}/cluster{cluster}_AAseq.fasta'
    interproscan_tool(interproscan, fasta_file)
    fasta_tsv_file = f'{output.rstrip("/")}/cluster{cluster}_AAseq.fasta.tsv'
    command_03_r(fasta_tsv_file, input, cluster, output)
    delete_intermediate_files(output, cluster)

def command_01_py(cluster, input, output, interproscan):
    os.makedirs(output, exist_ok=True)
    fasta_content = []
    with open(input, 'r') as infile:
        header_line = infile.readline().strip()
        for line in infile:
            line = line.strip()
            if line != header_line:
                gene = line.split()[0]
                fasta_content.append(f">{gene}\n{gene}\n")
    temp_fasta = os.path.join(output, "temp.fasta")
    with open(temp_fasta, 'w') as temp_file:
        temp_file.writelines(fasta_content)

    translated_temp = os.path.join(output, "translated.fasta")
    sp.run(
        ["seqkit", "translate", "--frame", "6", temp_fasta, "-o", translated_temp],
        check=True
    )
    output_file = os.path.join(output, "pep.txt")
    with open(translated_temp, 'r') as translated, open(output_file, 'w') as outfile:
        outfile.write("kmer\tpep_seq\n")
        header, sequence = None, ""
        for line in translated:
            line = line.strip()
            if line.startswith(">"):
                if header and len(sequence) == 4:
                    kmer = header.split("_")[0]
                    outfile.write(f"{kmer}\t{sequence}\n")
                header = line[1:]
                sequence = ""
            else:
                sequence += line
        if header and len(sequence) == 4:
            kmer = header.split("_")[0]
            outfile.write(f"{kmer}\t{sequence}\n")
    os.remove(temp_fasta)
    os.remove(translated_temp)
    print(f"FASTA and peptide sequence processing completed. Save the output to {output_file}")

def command_02_r(cluster, input, pep_file, output, interproscan):
    command_02_script = os.path.join(os.path.dirname(__file__), 'KmerGOp_Tom.R')
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

def interproscan_tool(interproscan, fasta_file):
    command_interproscan = f'{interproscan} -i {fasta_file} -f tsv -goterms'
    print(f"Running interproscan with command: {command_interproscan}")
    try:
        result_interproscan = sp.run(command_interproscan, shell=True, check=True, capture_output=True, text=True)
        print(f"interproscan completed successfully.\n{result_interproscan.stdout}")
    except sp.CalledProcessError as e:
        print(f"Error in interproscan:\n{e.stderr}")
        raise RuntimeError("interproscan failed") from e

def command_03_r(fasta_tsv_file, input, cluster, output):
    command_03_script = os.path.join(os.path.dirname(__file__), 'KmerGOp_GOdb.R')
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

def delete_intermediate_files(output, cluster):    
    files_to_delete = [f"pep.txt", f"cluster{cluster}.meme", f"cluster{cluster}.txt", f"cluster{cluster}_AAseq.fasta", f"cluster{cluster}_AAseq.fasta.tsv"]
    for file_name in files_to_delete:
        file_path = os.path.join(output, file_name)
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Deleted file: {file_path}")

if __name__ == '__main__':
    sys.exit(main(sys.argv))