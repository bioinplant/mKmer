library(Matrix)
library(anndata)
library(reticulate)
library(optparse)

use_condaenv(condaenv = "/public/home/mofy/anaconda3/envs/mKmer", required = TRUE)
ad <- import("anndata")

merged_matrix <- NULL

# 定义函数读取并转置HDF5文件中的特征矩阵
read_and_transpose_h5ad <- function(file_path) {
  # 读取HDF5文件
  anndata <- ad$read_h5ad(file_path)
  # 提取特征矩阵并进行转置操作
  scRNA_data <- t(anndata$X)
  return(scRNA_data)
}

# 解析命令行参数
option_list <- list(
  make_option(c("-f", "--folder"), type = "character", default = "./h5ad",
              help = "Path to the folder containing .h5ad files", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# 获取指定文件夹下所有的HDF5文件
h5ad_files <- list.files(path = opt$folder, pattern = "\\.h5ad$", full.names = TRUE)

# 遍历每个HDF5文件并读取特征矩阵
for (file_path in h5ad_files) {
  # 读取并转置特征矩阵
  scRNA_data <- read_and_transpose_h5ad(file_path)
  # 将特征矩阵添加到合并矩阵中
  if (is.null(merged_matrix)) {
    merged_matrix <- scRNA_data
  } else {
    merged_matrix <- cbind(merged_matrix, scRNA_data)
  }
}

# 保存合并后的矩阵为RDS文件
saveRDS(merged_matrix, file = "kmer_matrix.rds")
