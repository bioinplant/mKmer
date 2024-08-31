#### Pipline  ####

#[1] High quality cells are filtered by umi_tools
Refer to the umi_tools.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes umi_tools official website (https://github.com/CGATOxford/UMI-tools).

#[2] Removing duplicates
perl RemoveDuplicates.pl -i /path/to/sample_R1_extracted.fq.gz -o R1_extracted_duplicate.fq
perl RemoveDuplicates.pl -i /path/to/sample_R2_extracted.fq.gz -o R2_extracted_duplicate.fq

#[3] Counting of k-mers by jellyfish
Refer to the jellyfish.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes jellyfish official website (https://github.com/gmarcais/Jellyfish).

#[4] Choosing the number of k
Rscript KmerFrequency.R --input 11mer_counts.histo,12mer_counts.histo,13mer_counts.histo --out /path/to/frequency_rank/

#[5] Choosing the number of HCKs (topkmer)
Rscript KmerRank.R --histo 13mer_counts.histo --out /path/to/frequency_rank/

#[6] Generating the kmer/cell matrix (kmercount file need to be named "kmer_counts_dumps.fa")
bash KmerCell/KmerCell.sh --kmercount kmer_counts_dumps.fa --fastq R2_extracted_duplicate.fq --topkmer 10000 --k 13 --output /path/to/out_folder

#[5]  The routine downstream analysis of single cells, such as dimensionality reduction, clustering and finding marker K-mers, is performed by seurat.

#[6] Functional analysis
#[6.1] KmerGOn 
bash KmerGOn/KmerGOn.sh --cluster 0 --input markerkmer.txt --out /path/to/out_folder/ --db /path/to/MEME/gomo_databases
#[6.2] KmerGOp
bash KmerGOp/KmerGOp.sh --cluster 0 --markerkmer markerkmer.txt --out /path/to/out_folder/ --interproscan /path/to/interproscan-5.47-82.0/interproscan.sh
