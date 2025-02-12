#!/bin/bash
export RANDOM_SEED=42
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 --input <input_meme_file> --db <database_directory>"
    exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input) input_meme_file="$2"; shift ;;
        --db) db_dir="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$input_meme_file" || -z "$db_dir" ]]; then
    echo "Usage: $0 --input <input_meme_file> --db <database_directory>"
    exit 1
fi

input_dir=$(dirname "$input_meme_file")
input_file=$(basename "$input_meme_file")
cd "$input_dir"
ama --o ama1_out --pvalues --verbosity 1 "$input_file" "$db_dir/bacteria_escherichia_coli_ctf073_1000_199.na" "$db_dir/bacteria_escherichia_coli_ctf073_1000_199.na.bfile"
ama --o ama2_out --pvalues --verbosity 1 "$input_file" "$db_dir/bacteria_escherichia_coli_k12_1000_199.na" "$db_dir/bacteria_escherichia_coli_k12_1000_199.na.bfile"
ama --o ama3_out --pvalues --verbosity 1 "$input_file" "$db_dir/bacteria_salmonella_enterica_typhi_ty2_1000_199.na" "$db_dir/bacteria_salmonella_enterica_typhi_ty2_1000_199.na.bfile"
ama --o ama4_out --pvalues --verbosity 1 "$input_file" "$db_dir/bacteria_yersinia_pestis_co92_1000_199.na" "$db_dir/bacteria_yersinia_pestis_co92_1000_199.na.bfile"
gomo --nostatus --verbosity 1 --t 0.05 --shuffle_scores 1000 --dag "$db_dir/go.dag" --oc gomo_out --seed 42 \
--motifs "$input_file" "$db_dir/bacteria_escherichia_coli_k12_1000_199.na.csv" ama1_out/ama.xml ama2_out/ama.xml ama3_out/ama.xml ama4_out/ama.xml
