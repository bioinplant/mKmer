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
  make_option(c("-p", "--pep"), type = "character", default = NULL, 
              help = "Path to the pep.txt file", metavar = "character"),
  make_option(c("-m", "--markerkmer"), type = "character", default = NULL, 
              help = "Path to the markerkmer.txt file", metavar = "character"),
  make_option(c("-c", "--cluster"), type = "integer", 
              help = "Cluster number", metavar = "integer"),
  make_option(c("-o", "--out"), type = "character", default = NULL, 
              help = "Output file path", metavar = "character")
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Extract arguments
pep_file <- opt$pep
markerkmer_file <- opt$markerkmer
cluster_num <- opt$cluster
out_path <- opt$out

# Validate input arguments
if (is.null(pep_file) | is.null(markerkmer_file) | is.null(out_path)) {
  print_help(opt_parser)
  stop("All input files and output path must be provided.", call. = FALSE)
}

# Read input files
markerkmer <- read.table(markerkmer_file, header = TRUE)
pep <- read.table(pep_file, header = TRUE)

# Merge marker k-mer data with peptide sequences
cluster_gene <- left_join(markerkmer, pep, by = c("gene" = "kmer"), relationship = "many-to-many") %>%
  filter(!is.na(pep_seq)) %>%
  distinct() %>%
  filter(cluster == cluster_num)

# Define output file paths
out_meme <- file.path(out_path, paste0("cluster", cluster_num, ".meme"))
out_txt <- file.path(out_path, paste0("cluster", cluster_num, ".txt"))

tomtom_kmer <- data.frame()

# Get script directory and MEME database path
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
script_dir <- normalizePath(dirname(script_path))
meme_db_path <- file.path(script_dir, "prosite2021_04.meme")
options(meme_db = meme_db_path)

# Get Conda environment path
env_path <- system("conda info --envs | grep -E '\\*' | awk '{print $3}'", intern = TRUE)
env_path <- file.path(env_path, "bin")

# Process each peptide sequence
for (i in seq_len(nrow(cluster_gene))) {
  motif_sequence <- as.character(cluster_gene$pep_seq[i])
  
  tryCatch({
    example_motif <- create_motif(motif_sequence, alphabet = "AA")
    tomtom_out <- runTomTom(example_motif, meme_path = env_path)
    
    if (nrow(tomtom_out) > 0) {
      first_row <- tomtom_out[1, ]
      first_row$motif_sequence <- first_row$best_match_motif[[1]]@consensus
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
  }, error = function(e) {
    warning(paste("Error processing motif_sequence:", motif_sequence, "Skipping to next sequence. Error:", e$message))
  })
}

# Merge results and write output
merge_data <- left_join(cluster_gene, tomtom_kmer[, sapply(tomtom_kmer, is.character)], 
                        by = c("pep_seq" = "consensus"), relationship = "many-to-many") %>%
  unique()

write.table(merge_data, file = out_txt, sep = "\t", quote = FALSE, row.names = FALSE)

# Modify MEME file header
meme_content <- readLines(out_meme)
header_content <- c("MEME version 5.0.5", "", "ALPHABET= ACDEFGHIKLMNPQRSTVWY", "")
writeLines(c(header_content, meme_content), out_meme)

# Generate FASTA file
fasta_content <- paste0(
  apply(merge_data, 1, function(row) paste0(">", row["gene"], "\n", row["motif_sequence"], "\n")),
  collapse = ""
)

writeLines(fasta_content, file.path(out_path, paste0("cluster", cluster_num, "_AAseq.fasta")))
