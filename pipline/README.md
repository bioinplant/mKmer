# mKmer_pipline

The sample data is from SAMC3766839 of PRJCA017256 (https://ngdc.cncb.ac.cn/bioproject/browse/PRJCA017256).

### [1] High quality cells are filtered by umi_tools ###
Refer to the umi_tools.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes umi_tools official website (https://github.com/CGATOxford/UMI-tools).
![d2](https://github.com/user-attachments/assets/cdcc0b26-5bc3-462e-8a2c-07e06783c05f)

### [2] Removing duplicates ###
```
# RemoveDuplicates.pl is adapted from https://blog.csdn.net/weixin_41869644/article/details/86591953
# RemoveDuplicates.pl identifies the last 29 characters of lines starting with ">" as identifiers for recognition and deduplication.
perl RemoveDuplicates.pl -i /path/to/sample_R1_extracted.fq.gz -o R1_extracted_duplicate.fq
perl RemoveDuplicates.pl -i /path/to/sample_R2_extracted.fq.gz -o R2_extracted_duplicate.fq
```
### [3] Annotating species ###
```
# The output folder needs to contain the smAnnotation.sh file
bash smAnnotation.sh --input /path/to/R2_extracted_duplicate.fq --db /path/to/kraken2_standard_db/kraken_ncbi_refseq_db_202309 --K2Rtool /path/to/kraken2-report/kraken2-report
```
![Uploading image.png…]()

### [4] Counting of k-mers by jellyfish ###
Refer to the jellyfish.sh file for the code corresponding to the example data. Different data sources may need different parameters, you may refer to specific changes jellyfish official website (https://github.com/gmarcais/Jellyfish).
### [5] Choosing the number of k ###
```
Rscript KmerFrequency.R --input 11mer_counts.histo,12mer_counts.histo,13mer_counts.histo --out /path/to/frequency_rank/
```
![figure1-b](https://github.com/user-attachments/assets/8605f458-c74c-4c9c-968f-3ac30492e1bb)

### [6] Choosing the number of HCKs (topkmer) ###
```
Rscript KmerRank.R --histo 13mer_counts.histo --out /path/to/frequency_rank/
```
![figure1-c](https://github.com/user-attachments/assets/f18d4635-d268-47d6-8c9b-3420bc179f09)

### [7] Generating the kmer/cell matrix ###
```
# kmercount file need to be named "kmer_counts_dumps.fa"
bash KmerCell/KmerCell.sh --kmercount kmer_counts_dumps.fa --fastq R2_extracted_duplicate.fq --topkmer 10000 --k 13 --output /path/to/out_folder
```
### [8] Dimensionality reduction, clustering and finding marker K-mers ###
The routine downstream analysis of single cells is performed by seurat(v4).
```
#Some of the parameters used in this sample
#min.cells and min.features do not need to set values. After species mapping, only species with purity > 50% are retained. Remove strains with fewer than 10 species.
normalization.method = "LogNormalize", scale.factor = 10000
selection.method = "vst", nfeatures = 6000
dims = 1:30, resolution = 0.5
only.pos = TRUE, test.use = 'MAST', min.pct = 0.25, logfc.threshold = 0.25
```
![figure1-e](https://github.com/user-attachments/assets/cb7fa0c2-33ff-454e-bcd7-5e614188e6bd)

### [9] Functional analysis ###
```
# KmerGOn 
bash KmerGOn/KmerGOn.sh --cluster 0 --input markerkmer.txt --out /path/to/out_folder/ --db /path/to/MEME/gomo_databases
```
```
# KmerGOp
bash KmerGOp/KmerGOp.sh --cluster 0 --markerkmer markerkmer.txt --out /path/to/out_folder/ --interproscan /path/to/interproscan-5.47-82.0/interproscan.sh
```
![figure1-f-KgoN](https://github.com/user-attachments/assets/36c662da-db17-4ed1-977c-fdb53d5616a3)

