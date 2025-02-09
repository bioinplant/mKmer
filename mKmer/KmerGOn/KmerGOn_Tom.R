set.seed(42)

# Load required libraries
library(optparse)
library(memes)
library(magrittr)
library(universalmotif)
library(Biostrings)
library(dplyr)

# Define command-line options
option_list <- list(
  make_option(c("-c", "--cluster"), type = "integer", default = 0, 
              help = "Cluster number", metavar = "integer"),
  make_option(c("-i", "--markerkmer"), type = "character", 
              help = "Absolute path to input file", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", 
              help = "Output path", metavar = "character")
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
cluster_num <- opt$cluster
input_file <- opt$markerkmer
out_path <- opt$out

# Define output file paths
out_meme <- file.path(out_path, paste0("cluster", cluster_num, ".meme"))
out_txt <- file.path(out_path, paste0("cluster", cluster_num, ".txt"))

# Read input file
markerkmer <- read.table(input_file, header = TRUE)
cluster_gene <- markerkmer %>% filter(cluster == cluster_num)

# Initialize result storage
tomtom_kmer <- data.frame()

# Determine script directory and MEME database path
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
script_dir <- normalizePath(dirname(script_path))
meme_db_path <- file.path(script_dir, "prodoric_2021.9.meme")
options(meme_db = meme_db_path)

# Get conda environment path
env_path <- system("conda info --envs | grep -E '\*' | awk '{print $3}'", intern = TRUE)
env_path <- file.path(env_path, "bin")

# Process each gene in the cluster
for (i in seq_len(nrow(cluster_gene))) {
  motif_sequence <- as.character(cluster_gene$gene[i])
  motif_sequence <- gsub("[0-9]", "", motif_sequence)
  
  example_motif <- create_motif(motif_sequence)
  tomtom_out <- runTomTom(example_motif, meme_path = env_path)
  
  if (nrow(tomtom_out) > 0) {
    first_row <- tomtom_out[1, ]
    tomtom_kmer <- bind_rows(tomtom_kmer, first_row)
    
    best_match_motif <- first_row$best_match_motif[[1]]
    if (!is.logical(best_match_motif)) {
      write_meme(best_match_motif, out_meme, append = TRUE)
    } else {
      warning(paste("No valid match found for motif_sequence:", motif_sequence))
    }
  } else {
    warning(paste("No match found for motif_sequence:", motif_sequence))
  }
}

# Merge results and write output
tomtom_kmer_char <- tomtom_kmer[, sapply(tomtom_kmer, is.character)]
merge_result <- left_join(cluster_gene, tomtom_kmer_char, by = c("gene" = "consensus"), relationship = "many-to-many")
write.table(merge_result, file = out_txt, sep = "\t", quote = FALSE, row.names = FALSE)

# Update MEME file header
tset_meme_content <- readLines(out_meme)
header_content <- c("MEME version 5.0.5", "", "ALPHABET= ACGT", "")
new_content <- c(header_content, tset_meme_content)
writeLines(new_content, out_meme)
