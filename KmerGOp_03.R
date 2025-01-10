set.seed(42)
library(tidyr)
library(GO.db)
library(ggplot2)
library(optparse)
library(dplyr)
library(AnnotationDbi)
library(data.table)

option_list <- list(
  make_option(c("-t", "--tsv"), type = "character", help = "Path to TSV file", metavar = "character"),
  make_option(c("-c", "--cluster"), type = "integer", help = "Cluster number", metavar = "integer"),
  make_option(c("-m", "--markerkmer"), type = "character", help = "Path to markerkmer file", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", help = "Output folder path", metavar = "character")
)

parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)
tsv_path <- opt$tsv
cluster_num <- opt$cluster
out_path <- opt$out
markerkmer <- opt$markerkmer

######################## Identify DOID details and merge them with markerkmer ############################
lines <- readLines(tsv_path)
split_lines <- strsplit(lines, "\t")
max_columns <- max(sapply(split_lines, length))
padded_lines <- lapply(split_lines, function(line) {
  c(line, rep(NA, max_columns - length(line)))
})
df <- do.call(rbind, lapply(padded_lines, function(line) {
  as.data.frame(t(line), stringsAsFactors = FALSE)
}))
colnames(df) <- paste0("V", 1:max_columns)
df <- df[!is.na(df$V14), ]
df <- df %>% separate_rows(V14, sep = "\\|")
AAseq <- df
go_ids <- unique(AAseq$V14)
go_info <- AnnotationDbi::select(GO.db, keys = go_ids, columns = c("GOID", "TERM", "ONTOLOGY", "DEFINITION"), keytype = "GOID")
go_rich <- left_join(AAseq, go_info, by = c("V14" = "GOID"), relationship = "many-to-many")
go_rich <- go_rich[!is.na(go_rich$ONTOLOGY), ]
input_path <- dirname(tsv_path)
markerkmer_cluster <- read.table(markerkmer, header = TRUE) %>% filter(cluster == cluster_num)
go_rich <- left_join(markerkmer_cluster, go_rich, by = c("gene" = "V1"), relationship = "many-to-many")
go_rich <- go_rich[!is.na(go_rich$ONTOLOGY), ]
enrich_go <- go_rich[, c("V14", "TERM", "ONTOLOGY")] %>% group_by(V14, TERM, ONTOLOGY) %>% summarise(Count = n()) %>% ungroup() %>% rename(Description = TERM)
enrich_go_out <- file.path(out_path, paste0("cluster", cluster_num, "enrich_go.txt"))
write.table(enrich_go, enrich_go_out, sep = '\t', row.names = FALSE, quote = FALSE)

######################## plot ############################
plot_df <- enrich_go
plot_df <- data.frame(lapply(plot_df, as.character), stringsAsFactors = FALSE)
plot_df <- data.frame(lapply(plot_df, trimws), stringsAsFactors = FALSE)
plot_df$Count <- as.numeric(plot_df$Count)
plot_df$ONTOLOGY <- factor(plot_df$ONTOLOGY, levels = c("MF", "CC", "BP"))
plot_df <- plot_df[order(plot_df$ONTOLOGY, plot_df$Count, plot_df$Description), ]
plot_df$Description <- factor(plot_df$Description, levels = plot_df$Description)
COLS <- c("#FD8D62", "#8DA1CB", "#66C3A5")
a <- ggplot(data = plot_df, aes(x = Description, y = Count, fill = ONTOLOGY)) +
        geom_bar(stat = "identity", width = 0.8) +
        coord_flip() +
        xlab("GO Term") +
        ylab("Count") +
        scale_fill_manual(values = COLS, breaks = c("BP", "CC", "MF")) +
        scale_y_continuous(breaks = seq(0, max(plot_df$Count), by = 5), expand = c(0, 0)) +
        theme_bw() +
        theme(panel.grid.major.x = element_line(color = "grey90", size = 0.5), panel.grid.minor.x = element_blank())

plot_out <- file.path(out_path, paste0("cluster", cluster_num, ".png"))
ggsave(a, file = plot_out, width = 9.03, height = 5.74, dpi = 500)
