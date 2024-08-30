#!/bin/bash
export RANDOM_SEED=12345
# 检查是否传递了所有必要的参数
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <markerkmer.txt> <output_directory>"
  exit 1
fi

# 获取脚本参数
markerkmer="$1"
out_path="$2"

# 确保输出目录存在
mkdir -p $out_path

# 初始化fasta内容
fasta_content=""

# 读取文件并生成FASTA格式内容
while IFS= read -r line; do
  if [ "$line" != "$(head -n 1 $markerkmer)" ]; then  # 跳过表头
    gene=$(echo $line | awk '{print $1}')
    head=">${gene}"
    sequence="$gene"
    fasta_content="${fasta_content}${head}\n${sequence}\n"
  fi
done < $markerkmer

# 将FASTA内容传递给seqkit进行翻译，并处理结果
echo -e "$fasta_content" | seqkit translate --frame 6 | sed 's/\*//g' | \
awk '/^>/ {if(seq) {if(length(seq) == 4) {print header; print seq}}; header=$0; seq=""} !/^>/ {seq=seq""$0} END {if(length(seq) == 4) {print header; print seq}}' | \
awk 'BEGIN {print "cluster_rank\tpep_seq"} /^>/ {header=substr($0,2)} !/^>/ {print header "\t" $0}' | \
awk 'BEGIN {print "kmer\tpep_seq"} NR>1 {split($1, parts, "_"); kmer = parts[1]; print kmer "\t" $2;}' > "${out_path}pep.txt"

echo "FASTA and peptide sequence processing complete. Output saved to ${out_path}pep.txt"

