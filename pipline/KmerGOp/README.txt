#### tomtom.R

### runTomTom函数需要指定数据库（https://meme-suite.org/meme/meme-software/Databases/motifs/motif_databases.12.24.tgz）和meme suit工具
## 数meme文件需从下载的motif数据库中复制到（如：motif_databases/PROTEIN/prosite2021_04.meme）mKmer虚拟环境的extdata文件夹中（/path/to/anaconda3/envs/mKmer/lib/R/library/memes/extdata/）
# 指定数据库的代码：options(meme_db = system.file("extdata/prosite2021_04.meme", package = "memes", mustWork = TRUE))
## runTomTom函数需要指定meme suit工具所在的文件夹，该文件夹是在meme这个虚拟环境中的
# 指定meme suit工具的代码：tomtom_out <- runTomTom(example_motif, meme_path = "/path/to/anaconda3/envs/meme/bin")


