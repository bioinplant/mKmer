'''
============================================================================
mKmer KmerGOn - pipeline for identifying clusters with motif database (DNA)
============================================================================

Main function: 
    This module takes a marker K-mer list as input, which is the output file of 
    the "FindAllMarkers" at Seurat, the number of the cluster you want to analyze, 
    and reference datasets recommends the corresponding MEME datasets (like 
    gomo_databases at https://meme-suite.org/meme/db/gomo). 

'''


description = '''
Method:

    pipeline for identifying clusters with motif database (DNA):
#      bash KmerGOn.sh --cluster "$cluster_id" --input markerkmer.txt --out /path/to/folder/ --db /path/to/gomo_databases
        mKmer KmerGOn --cluster [target_cluster_number] --input [marker_K-mer_list] --output [output_folder] --db [gomo_databases]

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
    group = parser.add_argument_group("KmerGOn-specific options")
    group.add_argument('-i', '--input', type=str, help="Marker K-mer list")
    group.add_argument('-o', '--output', type=str, help="Output path")
    group.add_argument('-c', '--cluster', type=str, help="Target cluster number")
    group.add_argument('-d', '--db', type=str, help="GOMO databases")

    args = parser.parse_args()
    input = quote(args.input)
    output = quote(args.output) + '/'
    if not os.path.exists(output):
        os.makedirs(output)
    cluster = quote(args.cluster)
    db = quote(args.db)

    run_tomtom_meme_r(cluster, input, output, db)
    meme_file = f'{output.rstrip("/")}/cluster{cluster}.meme'
    run_ama_gomo_sh(meme_file, db, cluster, input, output)
    xml_file = f'{output.rstrip("/")}/gomo_out/gomo.xml'
    txt_file = f'{output.rstrip("/")}/cluster{cluster}.txt'
    run_GO_Annotations_r(cluster, output, xml_file, txt_file)
    delete_intermediate_files(output, cluster)

# Command 1: Run Tomtom with R script
def run_tomtom_meme_r(cluster, input, output, db):
    command_01_script = os.path.join(os.path.dirname(__file__), 'KmerGOn_Tom.R')
    command_01 = [
        'Rscript', command_01_script,
        '--cluster', cluster,
        '--markerkmer', input,
        '--out', output
    ]
    result_01 = sp.run(command_01, capture_output=True, text=True)
    if result_01.returncode != 0:
        print(f"Error in tomtom_meme_01:\n{result_01.stderr}")
        raise RuntimeError("tomtom_meme 01 failed")

# Command 2: Run AMA with GOMO script
def run_ama_gomo_sh(meme_file, db, cluster, input, output):
    input_dir = os.path.dirname(meme_file)
    input_file = os.path.basename(meme_file)
    os.chdir(input_dir)
    sp.run([
        'ama', '--o', f'{output}/ama1_out', '--pvalues', '--verbosity', '1', 
        input_file, f'{db}/bacteria_escherichia_coli_ctf073_1000_199.na', f'{db}/bacteria_escherichia_coli_ctf073_1000_199.na.bfile'
    ])
    sp.run([
        'ama', '--o', f'{output}/ama2_out', '--pvalues', '--verbosity', '1', 
        input_file, f'{db}/bacteria_escherichia_coli_k12_1000_199.na', f'{db}/bacteria_escherichia_coli_k12_1000_199.na.bfile'
    ])
    sp.run([
        'ama', '--o', f'{output}/ama3_out', '--pvalues', '--verbosity', '1', 
        input_file, f'{db}/bacteria_salmonella_enterica_typhi_ty2_1000_199.na', f'{db}/bacteria_salmonella_enterica_typhi_ty2_1000_199.na.bfile'
    ])
    sp.run([
        'ama', '--o', f'{output}/ama4_out', '--pvalues', '--verbosity', '1', 
        input_file, f'{db}/bacteria_yersinia_pestis_co92_1000_199.na', f'{db}/bacteria_yersinia_pestis_co92_1000_199.na.bfile'
    ])
    sp.run([
        'gomo', '--nostatus', '--verbosity', '1', '--t', '0.05', '--shuffle_scores', '1000', '--dag', f'{db}/go.dag', '--oc', f'{output}/gomo_out',
        '--seed', '42', '--motifs', input_file, f'{db}/bacteria_escherichia_coli_k12_1000_199.na.csv',
        f'{output}/ama1_out/ama.xml', f'{output}/ama2_out/ama.xml', f'{output}/ama3_out/ama.xml', f'{output}/ama4_out/ama.xml'
    ])

# Command 3: Run GO Annotations R script
def run_GO_Annotations_r(cluster, output, xml_file, txt_file):
    command_03_script = os.path.join(os.path.dirname(__file__), 'KmerGOn_gomo.R')
    command_03 = [
        'Rscript', command_03_script,
        '--cluster', cluster,
        '--out', output,
        '--xml', xml_file,
        '--txt', txt_file
    ]
    result_03 = sp.run(command_03, capture_output=True, text=True)
    if result_03.returncode != 0:
        print(f"Error in GO_Annotations_03:\n{result_03.stderr}")
        raise RuntimeError("GO_Annotations 03 failed")

# Delete intermediate files after processing
def delete_intermediate_files(output, cluster):
    folders_to_delete = ['ama1_out', 'ama2_out', 'ama3_out', 'ama4_out', 'gomo_out']
    for folder_name in folders_to_delete:
        folder_path = os.path.join(output, folder_name)
        if os.path.exists(folder_path):
            shutil.rmtree(folder_path)
            print(f"Deleted folder: {folder_path}")
    files_to_delete = [f"cluster{cluster}.meme", f"cluster{cluster}.txt"]
    for file_name in files_to_delete:
        file_path = os.path.join(output, file_name)
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Deleted file: {file_path}")

if __name__ == '__main__':
    sys.exit(main(sys.argv))