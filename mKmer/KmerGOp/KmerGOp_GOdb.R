set.seed(42)

# Load required libraries
library(tidyr)
library(GO.db)
library(ggplot2)
library(optparse)
library(dplyr)
library(AnnotationDbi)
library(data.table)

# Define command-line options
option_list <- list(
  make_option(c("-t", "--tsv"), type = "character", help = "Path to TSV file", metavar = "character"),
  make_option(c("-c", "--cluster"), type = "integer", help = "Cluster number", metavar = "integer"),
  make_option(c("-m", "--markerkmer"), type = "character", help = "Path to marker kmer file", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", help = "Output folder path", metavar = "character")
)

# Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

tsv_path <- opt$tsv
cluster_num <- opt$cluster
out_path <- opt$out
markerkmer_path <- opt$markerkmer

# Read and preprocess the TSV file
ts_lines <- readLines(tsv_path)
ts_split <- strsplit(ts_lines, "\t")
max_columns <- max(sapply(ts_split, length))

ts_padded <- lapply(ts_split, function(line) c(line, rep(NA, max_columns - length(line))))
ts_df <- do.call(rbind, lapply(ts_padded, function(line) as.data.frame(t(line), stringsAsFactors = FALSE)))
colnames(ts_df) <- paste0("V", 1:max_columns)

ts_df <- ts_df[!is.na(ts_df$V14), ] %>% separate_rows(V14, sep = "\\|")

# Extract unique GO IDs and fetch GO term details
go_ids <- unique(ts_df$V14)
go_info <- AnnotationDbi::select(GO.db, keys = go_ids, columns = c("GOID", "TERM", "ONTOLOGY", "DEFINITION"), keytype = "GOID")
go_merged <- left_join(ts_df, go_info, by = c("V14" = "GOID"), relationship = "many-to-many")
go_merged <- go_merged[!is.na(go_merged$ONTOLOGY), ]

# Read marker kmer file and filter by cluster
markerkmer_df <- read.table(markerkmer_path, header = TRUE) %>% filter(cluster == cluster_num)

go_enriched <- left_join(markerkmer_df, go_merged, by = c("gene" = "V1"), relationship = "many-to-many")
go_enriched <- go_enriched[!is.na(go_enriched$ONTOLOGY), ]

# Aggregate enrichment data
enrich_go <- go_enriched %>% 
  group_by(V14, TERM, ONTOLOGY) %>% 
  summarise(Count = n(), .groups = "drop") %>% 
  rename(Description = TERM)

# Save enrichment results
output_file <- file.path(out_path, paste0("cluster", cluster_num, "_enrich_go.txt"))
write.table(enrich_go, output_file, sep = '\t', row.names = FALSE, quote = FALSE)

# Prepare data for visualization
enrich_go$ONTOLOGY <- factor(enrich_go$ONTOLOGY, levels = c("MF", "CC", "BP"))
enrich_go <- enrich_go[order(enrich_go$ONTOLOGY, enrich_go$Count, enrich_go$Description), ]
enrich_go$Description <- factor(enrich_go$Description, levels = enrich_go$Description)

# Define color scheme
color_palette <- c("#FD8D62", "#8DA1CB", "#66C3A5")

# Generate bar plot
enrich_plot <- ggplot(data = enrich_go, aes(x = Description, y = Count, fill = ONTOLOGY)) +
  geom_bar(stat = "identity", width = 0.8) +
  coord_flip() +
  xlab("GO Term") +
  ylab("Count") +
  scale_fill_manual(values = color_palette, breaks = c("BP", "CC", "MF")) +
  scale_y_continuous(breaks = seq(0, max(enrich_go$Count), by = 5), expand = c(0, 0)) +
  theme_bw() +
  theme(
    panel.grid.major.x = element_line(color = "grey90", size = 0.5),
    panel.grid.minor.x = element_blank()
  )

# Save the plot
plot_output_file <- file.path(out_path, paste0("cluster", cluster_num, ".png"))
ggsave(enrich_plot, file = plot_output_file, width = 9.03, height = 5.74, dpi = 300)
