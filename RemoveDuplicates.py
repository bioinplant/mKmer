'''
============================================================================
mKmer RemoveDuplicates - pipeline for removal of repeat sequence of single-microbe RNA-seq datasets
============================================================================

Main function: 
    This module takes a fastq-file as input, which is recommended to contain extracted
    barcode and UMI information adding to the read name.

'''

description = '''
Method:

    pipeline for removal of repeat sequence of single-microbe RNA-seq datasets:
        mKmer RemoveDuplicates --input [fastq.gz_file] --output [extracted_fastq.gz_filename]

    Note: The pipeline is carried out with the last 29 characters (20barcode+_+8umi) of the identifier line (the first row of 
               each four rows) as the identification. If you want to change the standard of recognized identifiers, you need to 
               change the location of "29" in the RemoveDuplicates.pl file.
 
'''

import gzip
import argparse
from statistics import mean
import random
random.seed(42)

def parse_args():
    parser = argparse.ArgumentParser(
                                    usage = globals()["__doc__"],
                                    description = description,
                                    formatter_class=argparse.RawTextHelpFormatter)
    group = parser.add_argument_group("RemoveDuplicates-specific options")
    group.add_argument('-i', '--input', type=str, help="fastq.gz file")
    group.add_argument('-o', '--output', type=str, help="output filename")
    return parser.parse_args()

def avg_quality_score(quality_line):
    return mean([ord(char) - 33 for char in quality_line])

def process_fastq(input_file, output_file):
    seqs = {}
    open_func = gzip.open if input_file.endswith(".gz") else open
    with open_func(input_file, "rt") as infile:
        while True:
            line1 = infile.readline()
            if not line1:
                break
            line2 = infile.readline()
            line3 = infile.readline()
            line4 = infile.readline()
            id_suffix = line1.strip()[-29:]
            avg_quality = avg_quality_score(line4.strip())
            if id_suffix in seqs:
                if avg_quality > seqs[id_suffix]["quality"]:
                    seqs[id_suffix] = {"seq": (line1, line2, line3, line4), "quality": avg_quality}
            else:
                seqs[id_suffix] = {"seq": (line1, line2, line3, line4), "quality": avg_quality}
    with open(output_file, "w") as outfile:
        for entry in seqs.values():
            outfile.writelines(entry["seq"])
    print(f"Redo complete. Results have been saved to {output_file}")

def main():
    args = parse_args()
    process_fastq(args.input, args.output)

if __name__ == "__main__":
    main()