set.seed(42)
library(optparse)
library(xml2)
library(dplyr)
library(ggplot2)

option_list <- list(
  make_option(c("-c", "--cluster"), type = "integer", help = "Cluster number", metavar = "integer"),
  make_option(c("-o", "--out"), type = "character", help = "Output folder path", metavar = "character"),
  make_option(c("-x", "--xml"), type = "character", help = "Path to gomo.xml file", metavar = "character"),
  make_option(c("-t", "--txt"), type = "character", help = "Path to cluster.txt file", metavar = "character"),
  make_option(c("-i", "--implied_c"), type = "character", default = "n", help = "Implied condition", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
cluster_num <- opt$cluster
out_folder <- opt$out
xml_file <- opt$xml
txt_file <- opt$txt
implied_c <- opt$implied_c

######################## get information from gomo.xml ############################
xml_data <- read_xml(xml_file)
motifs <- xml_data %>% 
  xml_find_all("//motif")
results <- character()

for (motif in motifs) {
  id <- xml_attr(motif, "id")
  goterms <- motif %>% xml_find_all("goterm")
  for (goterm in goterms) {
    goterm_id <- xml_attr(goterm, "id")
    score <- xml_attr(goterm, "score")
    group <- xml_attr(goterm, "group")
    ontology <- switch(group, "b" = "BP", "m" = "MF", "c" = "CC", group)
    name <- xml_attr(goterm, "name")
    implied <- xml_attr(goterm, "implied")
    results <- c(results, paste(id, "\t", goterm_id, "\t", score, "\t", ontology, "\t", name, "\t", implied))
  }
}

column_names <- "Motif_Identifier\tID\tscore\tONTOLOGY\tDescription\timplied"
all_lines <- c(column_names, results)
gomo_out <- read.table(textConnection(all_lines), header = TRUE, sep = "\t")
enrich_go_raw_out <- paste0(out_folder, "/cluster", cluster_num, "enrich_go_raw.txt")
write.table(gomo_out, enrich_go_raw_out, sep = '\t', row.names = FALSE, quote = FALSE)

######################## make enrich_go.txt ############################
gomo_out <- data.frame(lapply(gomo_out, as.character), stringsAsFactors = FALSE)
gomo_out <- data.frame(lapply(gomo_out, trimws), stringsAsFactors = FALSE)
gomo_out <- gomo_out[gomo_out$implied == implied_c, ]
gomo_out <- gomo_out %>% group_by(Motif_Identifier) %>% slice_min(score)

tomtom_txt_out <- read.table(txt_file, header = TRUE)
merge <- left_join(tomtom_txt_out, gomo_out, by = c("best_match_name" = "Motif_Identifier"), relationship = "many-to-many")
merge <- merge %>% filter(!is.na(implied))
enrich_go <- merge[, c("ID", "Description", "ONTOLOGY")]
enrich_go <- enrich_go %>% group_by(ID, Description, ONTOLOGY) %>% summarise(Count = n(), .groups = "drop")
enrich_go_out <- paste0(out_folder, "/cluster", cluster_num, "enrich_go.txt")
write.table(enrich_go, enrich_go_out, sep = '\t', row.names = FALSE, quote = FALSE)

######################## plot ############################
plot_df <- enrich_go
plot_df <- data.frame(lapply(plot_df, as.character), stringsAsFactors = FALSE)
plot_df <- data.frame(lapply(plot_df, trimws), stringsAsFactors = FALSE)
plot_df$Count <- as.numeric(plot_df$Count)
plot_df$ONTOLOGY <- factor(plot_df$ONTOLOGY, levels = c("BP", "CC", "MF"))
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
  theme(
    text = element_text(family = "Times New Roman", color = "black"),
    axis.title.x = element_text(size = 14, color = "black"), 
    axis.title.y = element_text(size = 14, color = "black"),
    axis.text.x = element_text(size = 12, color = "black"), 
    axis.text.y = element_text(size = 12, color = "black"),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.5),
    panel.grid.minor.x = element_blank()
  )

plot_out <- paste0(out_folder, "/cluster", cluster_num, ".png")
ggsave(a, file = plot_out, width = 9.03, height = 5.74, dpi = 500)
