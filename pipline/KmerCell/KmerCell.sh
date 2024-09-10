#!/bin/bash
# Usage: ./run_kmercell.sh --kmercount <kmercount> --fastq <fastq> --topkmer <topkmer> --k <k> --output <output_folder>
# Initialize variables
kmercount=""
fastq=""
topkmer=""
k=""
output_folder=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --kmercount) kmercount="$2"; shift ;;
        --fastq) fastq="$2"; shift ;;
        --topkmer) topkmer="$2"; shift ;;
        --k) k="$2"; shift ;;
        --output) output_folder="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if all necessary parameters are provided
if [[ -z "$kmercount" || -z "$fastq" || -z "$topkmer" || -z "$k" || -z "$output_folder" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: ./run_kmercell.sh --kmercount <kmercount> --fastq <fastq> --topkmer <topkmer> --k <k> --output <output_folder>"
    exit 1
fi

python "$(dirname "$0")/Kmercell.py" --kmercount "$kmercount" --fastq "$fastq" --topkmer "$topkmer" --k "$k" --output "$output_folder"/
Rscript "$(dirname "$0")/Kmercell.R" --folder "$output_folder"
find . -maxdepth 1 -name "*.h5ad" -exec rm -- {} +
