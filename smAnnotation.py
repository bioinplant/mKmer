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


description = '''
Method:

    taxonomic annotation for each microbe in genus or species level:
#      bash smAnnotation.sh --input R2_extracted_duplicate.fq --db /path/to/kracken2_db --K2Rtool /path/to/kraken2-report --output smAnnotation
        mKmer smAnnotation --input [fastq.gz_file] --db [kracken2_databases] --K2Rtool [kraken2-report_tool] --output [out_folder]

    Note:  Sample file is the R2 end file of fastq which contain extracted barcode and UMI information adding to the 
    read name. And the databases (db) folder is the datasets collected by kracken2. The K2Rtool is the "kraken2-report"
    file in the "kraken2-report" folder.
'''

import os
import argparse
import subprocess
import shutil
import random
random.seed(42)

def usage():
    print("Usage: script.py --input <R2_extracted_duplicate.fq> --db <kraken2_database_directory> --K2Rtool <K2Rtool_path> --output <output_directory>")
    exit(1)

def execute_command(command, error_message=""):
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError:
        print(error_message)
        exit(1)

def main():
    parser = argparse.ArgumentParser(description="Convert Bash script to Python.")
    parser.add_argument("--input", required=True, help="Input fastq file path")
    parser.add_argument("--db", required=True, help="Kraken2 database directory")
    parser.add_argument("--K2Rtool", required=True, help="Path to K2Rtool executable")
    parser.add_argument("--output", default="./output", help="Output directory")
    args = parser.parse_args()
    R2_FILE = args.input
    DB_DIR = args.db
    K2RTOOL = args.K2Rtool
    OUTPUT_DIR = args.output

    if not os.path.isfile(R2_FILE):
        print(f"Error: File {R2_FILE} not found.")
        exit(1)
    if not os.path.isdir(DB_DIR):
        print(f"Error: Directory {DB_DIR} not found.")
        exit(1)
    if not os.path.isfile(K2RTOOL) or not os.access(K2RTOOL, os.X_OK):
        print(f"Error: File {K2RTOOL} not found or not executable.")
        exit(1)

    os.makedirs(f"{OUTPUT_DIR}/output", exist_ok=True)
    os.makedirs(f"{OUTPUT_DIR}/report", exist_ok=True)
    os.makedirs(f"{OUTPUT_DIR}/bracken_S", exist_ok=True)
    os.makedirs(f"{OUTPUT_DIR}/bracken_G", exist_ok=True)

    kraken2_cmd = f"kraken2 --db {DB_DIR} --report {OUTPUT_DIR}/ncbi_kraken2.report --output {OUTPUT_DIR}/ncbi_kraken2.output {R2_FILE}"
    execute_command(kraken2_cmd, "Error running kraken2.")

    with open(f"{OUTPUT_DIR}/ncbi_kraken2.output", "r") as infile:
        for line in infile:
            barcode = line.split('_')[1]
            with open(f"{OUTPUT_DIR}/output/{barcode}.txt", "a") as outfile:
                outfile.write(line)

    for file in os.listdir(f"{OUTPUT_DIR}/output"):
        file_name = os.path.splitext(file)[0]
        input_file = f"{OUTPUT_DIR}/output/{file}"
        output_file = f"{OUTPUT_DIR}/report/{file_name}.txt"
        execute_command(f"{K2RTOOL} {DB_DIR}/taxo.k2d {input_file} {output_file}", f"Error processing {file} with K2Rtool.")

    for level, folder in zip(["S", "G"], ["bracken_S", "bracken_G"]):
        input_dir = f"{OUTPUT_DIR}/report"
        output_dir = f"{OUTPUT_DIR}/{folder}"
        os.makedirs(output_dir, exist_ok=True)

        for file in os.listdir(input_dir):
            file_name = os.path.splitext(file)[0]
            input_file = f"{input_dir}/{file}"
            output_file = f"{output_dir}/{file_name}.txt"
            bracken_cmd = f"bracken -d {DB_DIR} -i {input_file} -o {output_file} -r 100 -l {level}"
            execute_command(bracken_cmd, f"Error running bracken for {file}.")

        merged_file = f"{OUTPUT_DIR}/bracken_merged_{level}.report"
        with open(merged_file, "w") as merged:
            for file in os.listdir(output_dir):
                file_name = os.path.splitext(file)[0]
                input_file = f"{output_dir}/{file}"
                with open(input_file, "r") as infile:
                    max_row = max(infile.readlines()[1:], key=lambda x: float(x.split('\t')[6]))
                    merged.write(f"{file_name}\t{max_row}")

    with open(f"{OUTPUT_DIR}/bracken_merged_S.report", "r") as s_file, open(f"{OUTPUT_DIR}/bracken_merged_G.report", "r") as g_file:
        g_data = {line.split('\t')[0]: line.split('\t')[7].strip() for line in g_file.readlines()}
        with open(f"{OUTPUT_DIR}/smAnnotation.report", "w") as sm_file:
            sm_file.write("barcode\tname\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads\n")
            for line in s_file:
                columns = line.strip().split('\t')
                barcode = columns[0]
                g_fraction = g_data.get(barcode, "NA")
                columns[7] = g_fraction
                sm_file.write("\t".join(columns) + "\n")

    shutil.rmtree(f"{OUTPUT_DIR}/bracken_S")
    shutil.rmtree(f"{OUTPUT_DIR}/bracken_G")
    shutil.rmtree(f"{OUTPUT_DIR}/output")
    shutil.rmtree(f"{OUTPUT_DIR}/report")
    os.remove(f"{OUTPUT_DIR}/bracken_merged_G.report")
    os.remove(f"{OUTPUT_DIR}/bracken_merged_S.report")
    os.remove(f"{OUTPUT_DIR}/ncbi_kraken2.output")
    os.remove(f"{OUTPUT_DIR}/ncbi_kraken2.report")

if __name__ == "__main__":
    main()