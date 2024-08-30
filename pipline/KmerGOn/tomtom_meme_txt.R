set.seed(12345)
library(optparse)
library(memes)
library(magrittr)
library(universalmotif)
library(Biostrings)
library(dplyr)

# 定义命令行参数
option_list <- list(
  make_option(c("-c", "--cluster"), type = "integer", default = 0, help = "Cluster number", metavar = "integer"),
  make_option(c("-i", "--markerkmer"), type = "character", help = "Absolute path to input file", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", help = "Output path", metavar = "character")
)

# 解析命令行参数
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# 获取参数值
cluster_num <- opt$cluster
input_file <- opt$markerkmer
out_path <- opt$out

# 设置输出文件路径
out_meme <- paste0(out_path, "cluster", cluster_num, ".meme")
out_txt <- paste0(out_path, "cluster", cluster_num, ".txt")

# 读取数据
markerkmer <- read.table(input_file, header = TRUE)
cluster_gene <- markerkmer %>% filter(cluster == cluster_num)

# 初始化数据框
tomtom_kmer <- data.frame()

# 设置数据库路径
options(meme_db = system.file("extdata/prodoric_2021.9.meme", package = "memes", mustWork = TRUE))

# 处理每个基因
for (i in 1:nrow(cluster_gene)) {
  motif_sequence <- as.character(cluster_gene$gene[i])
  example_motif <- create_motif(motif_sequence)
  tomtom_out <- runTomTom(example_motif, meme_path = "/public/home/mofy/anaconda3/envs/meme/bin")
  
  # 处理 .txt 输出
  first_row <- tomtom_out[1, ]
  tomtom_kmer <- bind_rows(tomtom_kmer, first_row)
  
  # 处理 .meme 输出
  if (nrow(tomtom_out) > 0) {
    first_1 <- tomtom_out[1, ]
    best_match_motif <- first_1$best_match_motif[[1]]
    if (!is.logical(best_match_motif)) {
      write_meme(best_match_motif, out_meme, append = TRUE)
    } else {
      warning(paste("No valid match found for motif_sequence:", motif_sequence))
    }
  } else {
    warning(paste("No match found for motif_sequence:", motif_sequence))
  }
}

# 生成 .txt 文件
tomtom_kmer_char <- tomtom_kmer[, sapply(tomtom_kmer, is.character)]
merge <- left_join(cluster_gene, tomtom_kmer_char, by = c("gene" = "consensus"), relationship = "many-to-many")
write.table(merge, file = out_txt, sep = "\t", quote = FALSE, row.names = FALSE)

# 更新 .meme 文件
tset_meme_content <- readLines(out_meme)
header_content <- c("MEME version 5.0.5", "", "ALPHABET= ACGT", "")
new_content <- c(header_content, tset_meme_content)
writeLines(new_content, out_meme)
