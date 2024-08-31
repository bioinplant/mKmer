# mKmer
microbiomics  K-mer  
    
Available now：    
mKmer: A K-mer embedding algorithm (mKmer) using RNA K-mer matrix.    
    
In preparation：    


#### ####
#### ####
------------------------------------------------------------------------------------------------------------------------------------------
#### ####
#### ####
### mKmer ###
### Version 1.0.0 ###

For mKmer (v.1.0.0), Anaconda3-2023.07-2-Linux-x86_64, R (v4.3.2) and Python (v3.8.19) are utilized to build the analysis platform on CentOS Linux (release 7.6.1810). umi_tools (v1.1.4), jellyfish (v2.2.10), anndata (v0.9.2), seqkit (v2.8.2), kraken2 (v2.0.7_beta), bracken (v2.8), meme (v5.0.5), openjdk (v11.0.23) and their dependent packages are mainly used for analysis and annotation. Then there are some R packages: Matrix (v1.6.3), anndata (v0.7.5.6), reticulate (v1.34.0), optparse (v1.7.5), BiocManager (v1.30.23), universalmotif (v1.20.0), memes (v1.10.0), GO.db (v3.18.0) and their dependent packages are mainly used for analysis and annotation. ggplot2 (v3.4.4), ggseqlogo (v0.2), patchwork (v1.1.3), tidyverse (v2.0.0), ggbump (v0.1.0) and their dependent packages are mainly utilized for visualization.

---
#### [2024-08-30] ####
#### mKmer's pipline folder has been uploaded for the first time.  ####
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
# KmerGOn 
bash KmerGOn/KmerGOn.sh --cluster 0 --input markerkmer.txt --out /path/to/out_folder/ --db /path/to/MEME/gomo_databases
# KmerGOp
bash KmerGOp/KmerGOp.sh --cluster 0 --markerkmer markerkmer.txt --out /path/to/out_folder/ --interproscan /path/to/interproscan-5.47-82.0/interproscan.sh







