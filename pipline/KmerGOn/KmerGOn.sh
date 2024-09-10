#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --cluster) cluster="$2"; shift ;;
        --input) input_file="$2"; shift ;;
        --out) out_path="$2"; shift ;;
        --db) db_path="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$cluster" ] || [ -z "$input_file" ] || [ -z "$out_path" ] || [ -z "$db_path" ]; then
    echo "Usage: $0 --cluster <cluster_num> --input <input_file> --out <output_path> --db <db_path>"
    exit 1
fi

########################## tomtom ################################
script_dir=$(dirname "$0")
Rscript "$script_dir/tomtom_meme_txt.R" --cluster "$cluster" --markerkmer "$input_file" --out "$out_path"

########################## ama ################################
bash "$script_dir/run_ama_gomo.sh" --input "$out_path/cluster${cluster}.meme" --db "$db_path"

########################## plot ################################
Rscript "$script_dir/GO_Annotations.R" --cluster "$cluster" --out "$out_path" --xml "$out_path/gomo_out/gomo.xml" --txt "$out_path/cluster${cluster}.txt"

########################## rm ################################
rm -r ama1_out ama2_out ama3_out ama4_out "$out_path/gomo_out"
rm "$out_path/cluster${cluster}.meme" "$out_path/cluster${cluster}.txt"
