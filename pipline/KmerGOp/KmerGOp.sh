#!/bin/bash
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --markerkmer) markerkmer="$2"; shift ;;
        --cluster) cluster="$2"; shift ;;
        --out) out_path="$2"; shift ;;
        --interproscan) interproscan_tool="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$markerkmer" || -z "$cluster" || -z "$out_path" || -z "$interproscan_tool" ]]; then
    echo "Usage: $0 --markerkmer <markerkmer.txt> --cluster <cluster_num> --out <out_path> --interproscan <interproscan_tool>"
    exit 1
fi

export RANDOM_SEED=12345
########################## markerkmer2pep ################################
bash "$(dirname "$0")/markerkmer2pep.sh" "$markerkmer" "$out_path"

#  markerkmer2pep.sh 生成的输出文件名为 pep.txt
pep="${out_path}pep.txt"

########################## tomtom ################################
Rscript "$(dirname "$0")/tomtom.R" --cluster "$cluster" --markerkmer "$markerkmer" --pep "$pep" --out "$out_path"

####################  interproscan ####################
"$interproscan_tool" -i "${out_path}cluster${cluster}_AAseq.fasta" -f tsv -goterms

####################  GO_Annotations ####################
Rscript "$(dirname "$0")/GO_Annotations.R" --tsv "${out_path}cluster${cluster}_AAseq.fasta.tsv" --markerkmer "$markerkmer" --cluster "$cluster" --out "$out_path"


rm -r temp
rm "${out_path}cluster${cluster}_AAseq.fasta.tsv" "${out_path}cluster${cluster}_AAseq.fasta"
rm "${out_path}cluster${cluster}.meme" "$pep" "${out_path}cluster${cluster}.txt"


