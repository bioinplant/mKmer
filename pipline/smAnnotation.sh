#!/bin/bash

usage() {
  echo "Usage: $0 --input <R2_extracted_duplicate.fq> --db <kraken2_database_directory> --K2Rtool <K2Rtool_path>"
  exit 1
}

if [ "$#" -lt 6 ]; then
  usage
fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --input)
      shift
      R2_FILE=$1
      shift
      ;;
    --db)
      shift
      DB_DIR=$1
      shift
      ;;
    --K2Rtool)
      shift
      K2RTOOL=$1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# 检查各输入参数是否存在
if [ ! -f "$R2_FILE" ]; then
  echo "Error: File $R2_FILE not found."
  exit 1
fi

if [ ! -d "$DB_DIR" ]; then
  echo "Error: Directory $DB_DIR not found."
  exit 1
fi

if [ ! -f "$K2RTOOL" ]; then
  echo "Error: File $K2RTOOL not found."
  exit 1
fi

export RANDOM_SEED=12345

mkdir -p output report bracken_S bracken_G
kraken2 \
  --db "$DB_DIR" \
  --report ncbi_kraken2.report \
  --output ncbi_kraken2.output \
  "$R2_FILE"

# 按barcode将.output文件拆分为每个barcode的.output文件
awk -F '_' '{print > "output/" $2 ".txt"}' ncbi_kraken2.output

script_dir=$(dirname "$(realpath "$0")")
################################################### S ###########################################
###################### kraken2-report #########################
# 设置输入和输出目录为脚本所在目录下的文件夹
input_dir="$script_dir/output"
output_dir="$script_dir/report"
mkdir -p "$output_dir"

for file in "$input_dir"/*.txt; do
    # 提取文件名（不包含路径和扩展名）
    file_name=$(basename -- "$file" .txt)
    # 拼接输入与输出文件的路径
    input_file="$input_dir/${file_name}.txt"
    output_file="$output_dir/${file_name}.txt"
    # 运行kraken2-report命令
    "$K2RTOOL" "$DB_DIR"/taxo.k2d "$input_file" "$output_file"
done

###################### bracken #########################
input_dir="$script_dir/report"
output_dir="$script_dir/bracken_S"
mkdir -p "$output_dir"

for file in "$input_dir"/*.txt; do
    # 提取文件名（不包含路径和扩展名）
    file_name=$(basename -- "$file" .txt)
    # 拼接输入与输出文件的路径
    input_file="$input_dir/${file_name}.txt"
    output_file="$output_dir/${file_name}.txt"
    bracken -d "$DB_DIR" -i "$input_file" -o "$output_file" -r 100 -l S
done

rm "$input_dir"/*_bracken.txt

###################### filter_merge  #########################
touch bracken_merged_S.report
input_dir="$script_dir/bracken_S"

for file in "$input_dir"/*.txt; do
    # 提取文件名（不包含路径和扩展名）
    file_name=$(basename -- "$file" .txt)
    # 拼接输入文件的路径
    input_file="$input_dir/${file_name}.txt"
    awk -F'\t' -v file_name="$file_name" 'NR>1 && ($7 > max || NR==2) {max=$7; row=file_name"\t"$0} END{print row}' "$input_file" >> bracken_merged_S.report
done

sed -i '1ibarcode\tname\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads' bracken_merged_S.report

######################################################### G #######################################################
###################### bracken #########################
input_dir="$script_dir/report"
output_dir="$script_dir/bracken_G"
mkdir -p "$output_dir"

for file in "$input_dir"/*.txt; do
    # 提取文件名（不包含路径和扩展名）
    file_name=$(basename -- "$file" .txt)
    # 拼接输入与输出文件的路径
    input_file="$input_dir/${file_name}.txt"
    output_file="$output_dir/${file_name}.txt"
    bracken -d "$DB_DIR" -i "$input_file" -o "$output_file" -r 100 -l G
done

rm "$input_dir"/*_bracken.txt

###################### filter_merge  #########################
touch bracken_merged_G.report
input_dir="$script_dir/bracken_G"

for file in "$input_dir"/*.txt; do
    # 提取文件名（不包含路径和扩展名）
    file_name=$(basename -- "$file" .txt)
    # 拼接输入文件的路径
    input_file="$input_dir/${file_name}.txt"
    awk -F'\t' -v file_name="$file_name" 'NR>1 && ($7 > max || NR==2) {max=$7; row=file_name"\t"$0} END{print row}' "$input_file" >> bracken_merged_G.report
done

sed -i '1ibarcode\tname\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads' bracken_merged_G.report

###################### merge S_G  #########################

sed '/^$/d' bracken_merged_S.report > bracken_merged_S_sed.report
sed '/^$/d' bracken_merged_G.report > bracken_merged_G_sed.report

awk 'BEGIN {FS=OFS="\t"} {NF--; print}' bracken_merged_S_sed.report > bracken_merged_S_no_fraction.report

awk '
BEGIN {FS=OFS="\t"}
NR==FNR {g_fraction[$1]=$8; next}
{
    if ($1 in g_fraction) {
        print $0, g_fraction[$1]
    } else {
        print $0, "NA"
    }
}
' bracken_merged_G_sed.report bracken_merged_S_no_fraction.report > smAnnotation.report

rm bracken_merged_S_no_fraction.report bracken_merged_S.report bracken_merged_G.report ncbi_kraken2.report ncbi_kraken2.output bracken_merged_G_sed.report bracken_merged_S_sed.report
rm -r bracken_S bracken_G output report

