set.seed(42)
library(optparse)
library(memes)
library(magrittr)
library(universalmotif)
library(Biostrings)
library(dplyr)

# Define the options
option_list <- list(
  make_option(c("-p", "--pep"), type = "character", default = NULL, help = "path to the pep.txt file", metavar = "character"),
  make_option(c("-m", "--markerkmer"), type = "character", default = NULL, help = "path to the markerkmer.txt file", metavar = "character"),
  make_option(c("-c", "--cluster"), type = "integer", help = "cluster number", metavar = "integer"),
  make_option(c("-o", "--out"), type = "character", default = NULL, help = "output file path", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
pep_file <- opt$pep
markerkmer_file <- opt$markerkmer
cluster_num <- opt$cluster
out_path <- opt$out

if (is.null(pep_file) | is.null(markerkmer_file) | is.null(out_path)) {
  print_help(opt_parser)
  stop("All input files and output path must be provided.", call. = FALSE)
}

markerkmer <- read.table(markerkmer_file, header = TRUE)
pep <- read.table(pep_file, header = TRUE)
cluster_gene <- left_join(markerkmer, pep, by = c("gene" = "kmer"), relationship = "many-to-many")
cluster_gene <- cluster_gene[!is.na(cluster_gene$pep_seq), ]
cluster_gene <- distinct(cluster_gene)
cluster_gene <- cluster_gene %>% filter(cluster == cluster_num)
out_meme <- paste0(out_path, "cluster", cluster_num, ".meme")
out_txt <- paste0(out_path, "cluster", cluster_num, ".txt")
tomtom_kmer <- data.frame()

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
script_dir <- normalizePath(dirname(script_path))
meme_db_path <- paste0(script_dir, "/KmerGO/prosite2021_04.meme")
options(meme_db = meme_db_path)

env_path <- system("conda info --envs | grep -E '\\*' | awk '{print $3}'", intern = TRUE)
env_path <- file.path(env_path, "bin")

for (i in 1:nrow(cluster_gene)) {
  motif_sequence <- as.character(cluster_gene$pep_seq[i])
  tryCatch({
    example_motif <- create_motif(motif_sequence, alphabet = "AA")
    tomtom_out <- runTomTom(example_motif, meme_path = env_path)
    first_row <- tomtom_out[1, ]
    first_row$motif_sequence <- first_row$best_match_motif[[1]]@consensus
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
  }, error = function(e) {
    warning(paste("Error processing motif_sequence:", motif_sequence, "Skipping to next sequence. Error:", e$message))
  })
}

tomtom_kmer_char <- tomtom_kmer[, sapply(tomtom_kmer, is.character)]
merge <- left_join(cluster_gene, tomtom_kmer_char, by = c("pep_seq" = "consensus"), relationship = "many-to-many")
merge_unique <- unique(merge)
write.table(merge_unique, file = out_txt, sep = "\t", quote = FALSE, row.names = FALSE)
tset_meme_content <- readLines(out_meme)
header_content <- c("MEME version 5.0.5", "", "ALPHABET= ACDEFGHIKLMNPQRSTVWY", "")
new_content <- c(header_content, tset_meme_content)
writeLines(new_content, out_meme)
merge_fasta <- merge_unique
fasta_content2 <- ""

for (i in 1:nrow(merge_fasta)) {
  head <- paste(">", merge_fasta$gene[i], sep = "")
  sequence <- merge_fasta$motif_sequence[i]
  fasta_content2 <- paste(fasta_content2, head, "\n", sequence, "\n", sep = "")
}

writeLines(fasta_content2, paste0(out_path, "cluster", cluster_num, "_AAseq.fasta"))
