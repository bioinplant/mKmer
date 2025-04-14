import argparse
import gc
import numpy as np
import pandas as pd
import anndata
import time
from scipy.sparse import csr_matrix
from collections import defaultdict

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
    total_counts = dict(sorted(total_counts.items(), key=lambda item: item[1], reverse=True))
    sequences_in_all_dicts = []
    get_count = 0
    for sequence in total_counts:
        if model == 'intersection' and total_appear.get(sequence, 0) == dict_paths_len:
            sequences_in_all_dicts.append(sequence)
            get_count += 1
        elif model == 'union':
            sequences_in_all_dicts.append(sequence)
            get_count += 1
        if get_count == max_output_num_of_k_mer:
            break
    end_time = time.time()
    del total_counts, total_appear
    gc.collect()
    return sequences_in_all_dicts

def read_fastq_file(file_path):
    with open(file_path, "r") as file:
        while True:
            sequence_id = file.readline().strip()
            if not sequence_id:
                break
            parts = sequence_id.split('_')
            barcode = parts[1]
            umi = parts[2].split(' ')[0]
            sequence = file.readline().strip()
            file.readline()
            file.readline()
            yield barcode, umi, sequence

def generate_kmer_vectors(cell_sequences, barcodes, k_mer_index_dict, k):
    vector_len = len(k_mer_index_dict)
    vectors = {}
    for barcode in barcodes:
        kmer_counts = np.zeros(vector_len, dtype=np.int32)
        for seq in cell_sequences[barcode]:
            for i in range(len(seq) - k + 1):
                kmer = seq[i:i+k]
                idx = k_mer_index_dict.get(kmer, -1)
                if idx != -1:
                    kmer_counts[idx] += 1
        vectors[barcode] = kmer_counts
    return vectors

def main(args):
    top_sequences = get_top_k_mers(
        sequence_count_dict_paths=[args.kmercount], 
        max_output_num_of_k_mer=args.topkmer, 
        model='intersection'
    )
    k_mer_index_dict = {seq: idx for idx, seq in enumerate(top_sequences)}
    del top_sequences
    gc.collect()
    cell_sequences = defaultdict(list)
    umi_set = set()
    
    for barcode, umi, sequence in read_fastq_file(args.fastq):
        if (umi_key := f"{barcode}{umi}") not in umi_set:
            umi_set.add(umi_key)
            cell_sequences[barcode].append(sequence)

    barcodes = list(cell_sequences.keys())
    total_barcodes = len(barcodes)
    batch_size = 1000
    
    for batch_start in range(0, total_barcodes, batch_size):
        batch_end = min(batch_start + batch_size, total_barcodes)
        current_barcodes = barcodes[batch_start:batch_end]
        vectors = generate_kmer_vectors(
            cell_sequences=cell_sequences,
            barcodes=current_barcodes,
            k_mer_index_dict=k_mer_index_dict,
            k=args.k
        )
        data_matrix = csr_matrix(np.array([vectors[b] for b in current_barcodes], dtype=np.float32))
        adata = anndata.AnnData(
            data_matrix,
            obs=pd.DataFrame(index=current_barcodes),
            var=pd.DataFrame(index=list(k_mer_index_dict.keys()))
        )
        output_path = f"{args.output}-k-mer-batch-{batch_end}.h5ad"
        adata.write(output_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Optimized k-mer processing pipeline')
    parser.add_argument('--kmercount', type=str, required=True, help='Path to kmer counts file')
    parser.add_argument('--fastq', type=str, required=True, help='Path to input FASTQ file')
    parser.add_argument('--topkmer', type=int, required=True, help='Number of top k-mers to select')
    parser.add_argument('--k', type=int, required=True, help='k-mer length')
    parser.add_argument('--output', type=str, required=True, help='Output path prefix')
    
    args = parser.parse_args()
    main(args)
