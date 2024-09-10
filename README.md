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
#### [2024-08-30] mKmer's "pipline" folder has been uploaded for the first time ####
For mKmer, refer to the README file in the "pipline" folder. Each step can be used individually.

## Installation
#### [2024-08-31] Complete installation (The versions may not be exactly the same.) ####
```
# Please install conda first
# mKmer
conda create -n mKmer --offline
conda activate mKmer
conda install python=3.8
conda install -c r r-base=4.3.2
conda install -c bioconda umi_tools=1.1.4
conda install -c bioconda jellyfish=2.2.10
conda install -c conda-forge anndata=0.9.2
conda install -c bioconda seqkit=2.8.2
# smAnnotation
conda install -c bioconda kraken2=2.0.7_beta
conda install -c bioconda bracken=2.8
# interproscan
conda install -c conda-forge openjdk=11.0.23
```
```
# R package
conda install -c bioconda r-Matrix=1.6.3
conda install -c bioconda r-anndata=0.7.5.6
conda install -c bioconda r-reticulate=1.34.0
conda install -c bioconda r-optparse=1.7.5
conda install -c bioconda r-ggplot2=3.4.4
conda install -c bioconda r-ggseqlogo=0.2
conda install -c bioconda r-patchwork=1.1.3
conda install -c bioconda r-tidyverse=2.0.0
conda install -c bioconda r-ggbump=0.1.0
```
```
# R console
install.packages("BiocManager")
BiocManager::install("universalmotif")
BiocManager::install("memes")
BiocManager::install("GO.db")
```
```
# MEME suite
conda create -n meme
conda activate meme
conda install -c bioconda meme=5.0.5
```

Sincerely thanks to the contributors of packages such as umi_tools, jellyfish, anndata, seqkit, kraken2, bracken, Matrix, reticulate, optparse, ggplot2, ggseqlogo, patchwork, tidyverse, ggbump, BiocManager, universalmotif, memes, GO.db, meme etc.    

## Usage
The sample data is from SAMC3766839 of PRJCA017256 (https://ngdc.cncb.ac.cn/bioproject/browse/PRJCA017256).The analysis results of the sample data can be found in the readme file in the pipline folder.

#### [1] High quality cells are filtered by umi_tools ###
Refer to the umi_tools.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes umi_tools official website (https://github.com/CGATOxford/UMI-tools).

#### [2] Removing duplicates ###
```
# RemoveDuplicates.pl is adapted from https://blog.csdn.net/weixin_41869644/article/details/86591953
# RemoveDuplicates.pl identifies the last 29 characters of lines starting with ">" as identifiers for recognition and deduplication.
perl RemoveDuplicates.pl -i /path/to/sample_R1_extracted.fq.gz -o R1_extracted_duplicate.fq
perl RemoveDuplicates.pl -i /path/to/sample_R2_extracted.fq.gz -o R2_extracted_duplicate.fq
```
#### [3] Annotating species ###
```
# The output folder needs to contain the smAnnotation.sh file
bash smAnnotation.sh --input /path/to/R2_extracted_duplicate.fq --db /path/to/kraken2_standard_db/kraken_ncbi_refseq_db_202309 --K2Rtool /path/to/kraken2_standard_db/kraken2-report/kraken2-report
```

#### [4] Counting of k-mers by jellyfish ###
Refer to the jellyfish.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes jellyfish official website (https://github.com/gmarcais/Jellyfish).
#### [5] Choosing the number of k ###
```
Rscript KmerFrequency.R --input 11mer_counts.histo,12mer_counts.histo,13mer_counts.histo --out /path/to/frequency_rank/
```

#### [6] Choosing the number of HCKs (topkmer) ###
```
Rscript KmerRank.R --histo 13mer_counts.histo --out /path/to/frequency_rank/
```

#### [7] Generating the kmer/cell matrix ###
```
# kmercount file need to be named "kmer_counts_dumps.fa"
bash KmerCell/KmerCell.sh --kmercount kmer_counts_dumps.fa --fastq R2_extracted_duplicate.fq --topkmer 10000 --k 13 --output /path/to/out_folder
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
bash KmerGOn/KmerGOn.sh --cluster 0 --input markerkmer.txt --out /path/to/out_folder/ --db /path/to/MEME/gomo_databases
```
```
# KmerGOp
bash KmerGOp/KmerGOp.sh --cluster 0 --markerkmer markerkmer.txt --out /path/to/out_folder/ --interproscan /path/to/interproscan-5.47-82.0/interproscan.sh
```

If you have some questions, please send email to mofangyu@zju.edu.cn.    
