#!/bin/bash
export RANDOM_SEED=12345

usage() {
  echo "Usage: $0 --input <R2_extracted_duplicate.fq> --db <kraken2_database_directory> --K2Rtool <K2Rtool_path> --output <output_directory>"
  exit 1
}

if [ "$#" -lt 6 ]; then
  usage
fi

OUTPUT_DIR="./output"

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
    --output)
      shift
      OUTPUT_DIR=$1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

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

mkdir -p "$OUTPUT_DIR/output" "$OUTPUT_DIR/report" "$OUTPUT_DIR/bracken_S" "$OUTPUT_DIR/bracken_G"
script_dir=$(dirname "$(realpath "$0")")

kraken2 \
  --db "$DB_DIR" \
  --report "$OUTPUT_DIR/ncbi_kraken2.report" \
  --output "$OUTPUT_DIR/ncbi_kraken2.output" \
  "$R2_FILE"

awk -F '_' '{print > "'"$OUTPUT_DIR"'/output/" $2 ".txt"}' "$OUTPUT_DIR/ncbi_kraken2.output"
input_dir="$OUTPUT_DIR/output"
output_dir="$OUTPUT_DIR/report"
mkdir -p "$output_dir"

for file in "$input_dir"/*.txt; do
    file_name=$(basename -- "$file" .txt)
    input_file="$input_dir/${file_name}.txt"
    output_file="$output_dir/${file_name}.txt"
    "$K2RTOOL" "$DB_DIR/taxo.k2d" "$input_file" "$output_file"
done

input_dir="$OUTPUT_DIR/report"
output_dir="$OUTPUT_DIR/bracken_S"
mkdir -p "$output_dir"

for file in "$input_dir"/*.txt; do
    file_name=$(basename -- "$file" .txt)
    input_file="$input_dir/${file_name}.txt"
    output_file="$output_dir/${file_name}.txt"
    bracken -d "$DB_DIR" -i "$input_file" -o "$output_file" -r 100 -l S
done

rm "$input_dir"/*_bracken.txt
touch "$OUTPUT_DIR/bracken_merged_S.report"
input_dir="$OUTPUT_DIR/bracken_S"
for file in "$input_dir"/*.txt; do
    file_name=$(basename -- "$file" .txt)
    input_file="$input_dir/${file_name}.txt"
    awk -F'\t' -v file_name="$file_name" 'NR>1 && ($7 > max || NR==2) {max=$7; row=file_name"\t"$0} END{print row}' "$input_file" >> "$OUTPUT_DIR/bracken_merged_S.report"
done

input_dir="$OUTPUT_DIR/report"
output_dir="$OUTPUT_DIR/bracken_G"
mkdir -p "$output_dir"
for file in "$input_dir"/*.txt; do
    file_name=$(basename -- "$file" .txt)
    input_file="$input_dir/${file_name}.txt"
    output_file="$output_dir/${file_name}.txt"
    bracken -d "$DB_DIR" -i "$input_file" -o "$output_file" -r 100 -l G
done

rm "$input_dir"/*_bracken.txt
touch "$OUTPUT_DIR/bracken_merged_G.report"
input_dir="$OUTPUT_DIR/bracken_G"
for file in "$input_dir"/*.txt; do
    file_name=$(basename -- "$file" .txt)
    input_file="$input_dir/${file_name}.txt"
    awk -F'\t' -v file_name="$file_name" 'NR>1 && ($7 > max || NR==2) {max=$7; row=file_name"\t"$0} END{print row}' "$input_file" >> "$OUTPUT_DIR/bracken_merged_G.report"
done

sed '/^$/d' "$OUTPUT_DIR/bracken_merged_S.report" > "$OUTPUT_DIR/bracken_merged_S_sed.report"
sed '/^$/d' "$OUTPUT_DIR/bracken_merged_G.report" > "$OUTPUT_DIR/bracken_merged_G_sed.report"
awk 'BEGIN {FS=OFS="\t"} {NF--; print}' "$OUTPUT_DIR/bracken_merged_S_sed.report" > "$OUTPUT_DIR/bracken_merged_S_no_fraction.report"

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
' "$OUTPUT_DIR/bracken_merged_G_sed.report" "$OUTPUT_DIR/bracken_merged_S_no_fraction.report" > "$OUTPUT_DIR/smAnnotation.report"

sed -i '1ibarcode\tname\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads' "$OUTPUT_DIR/smAnnotation.report"
rm "$OUTPUT_DIR/bracken_merged_S_no_fraction.report" "$OUTPUT_DIR/bracken_merged_S.report" "$OUTPUT_DIR/bracken_merged_G.report" "$OUTPUT_DIR/ncbi_kraken2.report" "$OUTPUT_DIR/ncbi_kraken2.output" "$OUTPUT_DIR/bracken_merged_G_sed.report" "$OUTPUT_DIR/bracken_merged_S_sed.report"
rm -r "$OUTPUT_DIR/bracken_S" "$OUTPUT_DIR/bracken_G" "$OUTPUT_DIR/output" "$OUTPUT_DIR/report"