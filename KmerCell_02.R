set.seed(42)
library(Matrix)
library(anndata)
library(reticulate)
library(optparse)

env_path <- system("conda info --envs | grep -E '\\*' | awk '{print $3}'", intern = TRUE)
use_condaenv(condaenv = env_path, required = TRUE)
ad <- import("anndata")
merged_matrix <- NULL

read_and_transpose_h5ad <- function(file_path) {
  anndata <- ad$read_h5ad(file_path)
  scRNA_data <- t(anndata$X)
  return(scRNA_data)
}

option_list <- list(
  make_option(c("-f", "--folder"), type = "character", default = "./h5ad",
              help = "Path to the folder containing .h5ad files", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
h5ad_files <- list.files(path = opt$folder, pattern = "\\.h5ad$", full.names = TRUE)

for (file_path in h5ad_files) {
  scRNA_data <- read_and_transpose_h5ad(file_path)
  if (is.null(merged_matrix)) {
    merged_matrix <- scRNA_data
  } else {
    merged_matrix <- cbind(merged_matrix, scRNA_data)
  }
  file.remove(file_path)
}

saveRDS(merged_matrix, file = "kmer_matrix.rds")
