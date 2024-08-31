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
For mKmer, refer to the README file in the "pipline" folder. Each step can be used individually.

#### [2024-08-31] ####
#### Complete installation ####
# The versions may not be exactly the same.
# Please install conda first
```
#mKmer
conda create -n mKmer --offline
conda activate mKmer
conda install python=3.8
conda install -c r r-base=4.3.2
conda install -c bioconda umi_tools=1.1.4
conda install -c bioconda jellyfish=2.2.10
conda install -c conda-forge anndata=0.9.2
conda install -c bioconda seqkit=2.8.2
#smAnnotation
conda install -c bioconda kraken2=2.0.7_beta
conda install -c bioconda bracken=2.8
#interproscan
conda install -c conda-forge openjdk=11.0.23
```
```
#R package
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
#R console
install.packages("BiocManager")
BiocManager::install("universalmotif")
BiocManager::install("memes")
BiocManager::install("GO.db")
```
```
#MEME suite
conda create -n meme
conda activate meme
conda install -c bioconda meme=5.0.5
```

Sincerely thanks to the contributors of packages such as umi_tools, jellyfish, anndata, seqkit, kraken2, bracken, Matrix, reticulate, optparse, ggplot2, ggseqlogo, patchwork, tidyverse, ggbump, BiocManager, universalmotif, memes, GO.db, meme etc.    

If you have some questions, please send email to mofangyu@zju.edu.cn.    
