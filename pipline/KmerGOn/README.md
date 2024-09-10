# KmerGOn
### file--tomtom_meme_txt.R
runTomTom函数需要指定数据库（https://meme-suite.org/meme/meme-software/Databases/motifs/motif_databases.12.24.tgz）和meme suit工具
meme文件需从下载的motif数据库中复制到（如：motif_databases/PROKARYOTE/prodoric_2021.9.meme）mKmer虚拟环境的extdata文件夹中（/path/to/anaconda3/envs/mKmer/lib/R/library/memes/extdata/）
```
# Specifies the code for the database
options(meme_db = system.file("extdata/prodoric_2021.9.meme", package = "memes", mustWork = TRUE))
```
runTomTom函数需要指定meme suit工具所在的文件夹，该文件夹是在meme这个虚拟环境中的
```
# Specify the code for the meme suit tool
tomtom_out <- runTomTom(example_motif, meme_path = "/path/to/anaconda3/envs/meme/bin")
```
### file--run_ama_gomo.sh
#该文件需要MEME suite的ama和gomo工具，因此需要激活meme虚拟环境，因此脚本里需要加载source /path/to/anaconda3/etc/profile.d/conda.sh和conda activate meme

