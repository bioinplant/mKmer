import argparse
import gc
import numpy as np
import pandas as pd
import anndata
import os
import time
from scipy.sparse import csr_matrix
import shutil

def sequence_count_varieties(file_path):
    sequence_count_dict = {}
    with open(file_path, 'r', encoding='utf-8') as file:
        while True:
            try:
                count = int(next(file).strip().replace('>',''))
                sequence = next(file).strip()
                sequence_count_dict[sequence] = count
            except StopIteration:
                break
    return sequence_count_dict

def get_top_k_mers(sequence_count_dict_paths, max_output_num_of_k_mer, model='intersection'):
    start_time = time.time()
    dict_paths_len = len(sequence_count_dict_paths)
    total_counts = {}
    total_appear = {}
    for sequence_count_dict_path in sequence_count_dict_paths:
        sequence_count_dict = sequence_count_varieties(file_path=sequence_count_dict_path)
        for sequence, count in sequence_count_dict.items():
            total_counts[sequence] = total_counts.get(sequence, 0) + count
            if model == 'intersection':
                total_appear[sequence] = total_appear.get(sequence, 0) + 1
        del sequence_count_dict
        gc.collect()
    total_counts = {k: v for k, v in sorted(total_counts.items(), key=lambda item: item[1], reverse=True)}
    sequences_in_all_dicts = []
    get_count = 0
    for sequence in total_counts:
        if model == 'intersection' and total_appear[sequence] == dict_paths_len:
            sequences_in_all_dicts.append(sequence)
            get_count += 1
        elif model == 'union':
            sequences_in_all_dicts.append(sequence)
            get_count += 1
        if get_count == max_output_num_of_k_mer:
            break
    end_time = time.time()
    del total_counts
    gc.collect()
    return sequences_in_all_dicts

def read_fastq_file(file_path):
    with open(file_path, "r") as file:
        while True:
            sequence_id = file.readline().strip()
            if not sequence_id:
                break
            barcode = sequence_id.split('_')[1]
            umi = sequence_id.split('_')[2].split(' ')[0]
            sequence = file.readline().strip()
            file.readline()
            file.readline()
            yield barcode, umi, sequence

def get_cell_sequence_vector(input_folder, cell_path_set, vector_len, seq_dict, k_mer_len):
    cell_seq_vector_dict = {}
    tmp_dict = {i: 0 for i in range(vector_len)}
    for file_name in cell_path_set:
        if file_name.endswith(".txt"):
            file_path = os.path.join(input_folder, file_name)
            with open(file_path, 'r') as file:
                lines = file.readlines()
                for line in lines:
                    for i in range(len(line) - k_mer_len):
                        sequence = line[i:i + k_mer_len]
                        if sequence in seq_dict:
                            pos = seq_dict[sequence]
                            tmp_dict[pos] += 1
            cell_seq_vector_dict[file_name.replace('.txt', '')] = list(tmp_dict.values())
        tmp_dict = {i: 0 for i in range(vector_len)}
    return cell_seq_vector_dict

def main(args):
    top_sequences = get_top_k_mers(
        sequence_count_dict_paths=[args.kmercount], 
        max_output_num_of_k_mer=args.topkmer, 
        model='intersection'
    )

    k_mer_index_dict = {seq: idx for idx, seq in enumerate(top_sequences)}
    del top_sequences
    gc.collect()

    output_txt_folder = args.output + '-cell-fastq-txts'
    if not os.path.exists(output_txt_folder):
        os.makedirs(output_txt_folder)

    umi_set = set()
    for barcode, umi, sequence in read_fastq_file(args.fastq):
        if barcode + umi not in umi_set:
            umi_set.add(barcode + umi)
            file_name = os.path.join(output_txt_folder, f"{barcode}.txt")
            with open(file_name, 'a' if os.path.exists(file_name) else 'w') as file2:
                file2.write(sequence + '\n')

    total_cell_paths = os.listdir(output_txt_folder)
    batch = 1000
    count = 0
    while count < len(total_cell_paths):
        until_count = min(count + 1000, len(total_cell_paths))
        tmp_set = total_cell_paths[count:until_count]
        cell_seq_vector_dict = get_cell_sequence_vector(
            input_folder=output_txt_folder,
            cell_path_set=tmp_set,
            vector_len=len(k_mer_index_dict),
            seq_dict=k_mer_index_dict,
            k_mer_len=args.k
        )
        df = pd.DataFrame.from_dict(cell_seq_vector_dict, orient='index')
        adata = anndata.AnnData(csr_matrix(df.values.astype(np.float32), dtype=np.float32))
        adata.obs_names = list(cell_seq_vector_dict.keys())
        adata.var_names = list(k_mer_index_dict.keys())
        re_path = args.output + '-k-mer-changed-until-' + str(until_count) + '.h5ad'
        adata.write(re_path)
        count += 1000

    shutil.rmtree(output_txt_folder)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process kmer counts and generate h5ad files.')
    parser.add_argument('--kmercount', type=str, required=True, help='Path to the kmer counts file (kmer_counts_dumps.fa).')
    parser.add_argument('--fastq', type=str, required=True, help='Path to the fastq file (R2_extracted_duplicate.fq).')
    parser.add_argument('--topkmer', type=int, required=True, help='Maximum number of output k-mers.')
    parser.add_argument('--k', type=int, required=True, help='Length of the k-mer sequences.')
    parser.add_argument('--output', type=str, required=True, help='Output directory for generated files.')
    
    args = parser.parse_args()
    main(args)
