set.seed(12345)
library(optparse)
library(memes)
library(magrittr)
library(universalmotif)
library(Biostrings)
library(dplyr)

option_list <- list(
  make_option(c("-c", "--cluster"), type = "integer", default = 0, help = "Cluster number", metavar = "integer"),
  make_option(c("-i", "--markerkmer"), type = "character", help = "Absolute path to input file", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", help = "Output path", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
cluster_num <- opt$cluster
input_file <- opt$markerkmer
out_path <- opt$out
out_meme <- paste0(out_path, "cluster", cluster_num, ".meme")
out_txt <- paste0(out_path, "cluster", cluster_num, ".txt")
markerkmer <- read.table(input_file, header = TRUE)
cluster_gene <- markerkmer %>% filter(cluster == cluster_num)
tomtom_kmer <- data.frame()

options(meme_db = system.file("extdata/prodoric_2021.9.meme", package = "memes", mustWork = TRUE))

for (i in 1:nrow(cluster_gene)) {
  motif_sequence <- as.character(cluster_gene$gene[i])
  example_motif <- create_motif(motif_sequence)
  tomtom_out <- runTomTom(example_motif, meme_path = "/public/home/mofy/anaconda3/envs/meme/bin")
  first_row <- tomtom_out[1, ]
  tomtom_kmer <- bind_rows(tomtom_kmer, first_row)
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

tomtom_kmer_char <- tomtom_kmer[, sapply(tomtom_kmer, is.character)]
merge <- left_join(cluster_gene, tomtom_kmer_char, by = c("gene" = "consensus"), relationship = "many-to-many")
write.table(merge, file = out_txt, sep = "\t", quote = FALSE, row.names = FALSE)
tset_meme_content <- readLines(out_meme)
header_content <- c("MEME version 5.0.5", "", "ALPHABET= ACGT", "")
new_content <- c(header_content, tset_meme_content)
writeLines(new_content, out_meme)
