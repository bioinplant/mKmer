#!/bin/bash

jellyfish count -m 11 -s 10M -C -o 11mer_counts.jf R1_extracted_duplicate.fq R2_extracted_duplicate.fq
jellyfish count -m 12 -s 10M -C -o 12mer_counts.jf R1_extracted_duplicate.fq R2_extracted_duplicate.fq
jellyfish count -m 13 -s 10M -C -o 13mer_counts.jf R1_extracted_duplicate.fq R2_extracted_duplicate.fq

jellyfish histo 11mer_counts.jf -o 11mer_counts.histo -h 100000000
jellyfish histo 12mer_counts.jf -o 12mer_counts.histo -h 100000000
jellyfish histo 13mer_counts.jf -o 13mer_counts.histo -h 100000000

jellyfish dump 13mer_counts.jf > kmer_counts_dumps.fa

