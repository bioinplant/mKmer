# mKmer
microbiomics  K-mer  
    
Available now：    
mKmer: A K-mer embedding algorithm (mKmer) using RNA K-mer matrix.        

#### ####
#### ####
------------------------------------------------------------------------------------------------------------------------------------------
#### ####
#### ####
### mKmer Version 1.0.0 ###

For mKmer (v.1.0.0), Anaconda3-2023.07-2-Linux-x86_64, R (v4.3.2) and Python (v3.8.19) are utilized to build the analysis platform on CentOS Linux (release 7.6.1810). umi_tools (v1.1.4), jellyfish (v2.2.10), anndata (v0.9.2), seqkit (v2.8.2), kraken2 (v2.0.7_beta), bracken (v2.8), meme (v5.0.5), openjdk (v11.0.23) and their dependent packages are mainly used for analysis and annotation. Then there are some R packages: Matrix (v1.6.3), anndata (v0.7.5.6), reticulate (v1.34.0), optparse (v1.7.5), BiocManager (v1.30.23), universalmotif (v1.20.0), memes (v1.10.0), GO.db (v3.18.0) and their dependent packages are mainly used for analysis and annotation. ggplot2 (v3.4.4), ggseqlogo (v0.2), patchwork (v1.1.3), tidyverse (v2.0.0), ggbump (v0.1.0) and their dependent packages are mainly utilized for visualization.

---

## Installation
#### [2024-08-31] Complete installation (The versions may not be exactly the same.) ####
The installation of various packages depends on the conda.

It is recommended to work directly from the git repository and create a new conda environment to use mKmer:
```
$ git clone https://github.com/bioinplant/mKmer.git
$ cd mKmer
$ python setup.py sdist  
$ python setup.py install
# If some R packages fails to download, install it manually on the R console


$ pip install dist/mkmer-1.0.0.tar.gz
```
Sincerely thanks to the contributors of packages such as umi_tools, jellyfish, anndata, seqkit, kraken2, bracken, Matrix, reticulate, optparse, ggplot2, ggseqlogo, patchwork, tidyverse, ggbump, BiocManager, universalmotif, memes, GO.db, meme etc.    

## Usage
The sample data is from SAMC3766839 of PRJCA017256 (https://ngdc.cncb.ac.cn/bioproject/browse/PRJCA017256). The analysis results of the sample data can be found in the readme file in the pipline folder.

#### [1] High quality cells are filtered by umi_tools ###
Refer to the umi_tools.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes umi_tools official website (https://github.com/CGATOxford/UMI-tools).

#### [2] Removing duplicates ###
```
# RemoveDuplicates.pl is adapted from https://blog.csdn.net/weixin_41869644/article/details/86591953
# RemoveDuplicates.pl identifies the last 29 characters of lines starting with ">" as identifiers for recognition and deduplication.
mKmer RemoveDuplicates --input R2_extracted.fq.gz --output R2_extracted_duplicate.fq
```
#### [3] Annotating species ###
```
mKmer smAnnotation --input R2_extracted_duplicate.fq --db /path/to/kracken2_db/ncbi_standard_8 --output smAnnotation --K2Rtool /path/to/kraken2-report/kraken2-report
```

#### [4] Counting of k-mers by jellyfish ###
Refer to the jellyfish.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes jellyfish official website (https://github.com/gmarcais/Jellyfish).
#### [5] Choosing the number of k ###
```
mKmer KmerFrequency  --input 11mer_counts.histo 12mer_counts.histo 13mer_counts.histo --output frequency_rank
```

#### [6] Choosing the number of HCKs (topkmer) ###
```
mKmer KmerRank --input 13mer_counts.histo --output frequency_rank
```

#### [7] Generating the cell-by-Kmer matrix ###
```
# kmercount file need to be named "kmer_counts_dumps.fa"
mKmer KmerCell --fasta kmer_counts_dumps.fa --fastq R2_extracted_duplicate.fq --topkmer 1 --bestK 1 --output matrix
```
#### [8] Dimensionality reduction, clustering and finding marker K-mers ###
The routine downstream analysis of single cells is performed by seurat(v4).
```
#Some of the parameters used in this sample
#min.cells and min.features do not need to set values. After species mapping, only species with purity > 50% are retained. Remove strains with fewer than 10 species.
normalization.method = "LogNormalize", scale.factor = 10000
selection.method = "vst", nfeatures = 6000
dims = 1:30, resolution = 0.5
only.pos = TRUE, test.use = 'MAST', min.pct = 0.25, logfc.threshold = 0.25
```

#### [9] Functional analysis ###
```
# KmerGOn 
mKmer KmerGOn --cluster 0 --input markerkmer.txt --output KmerGOn --db /path/to/gomo_databases
```
```
# KmerGOp
mKmer KmerGOp --cluster 0 --input markerkmer.txt --output KmerGOp --interproscan /path/to/interproscan-5.47-82.0/interproscan.sh
```

If you have some questions, please send email to mofangyu@zju.edu.cn.    
