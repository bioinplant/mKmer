set.seed(42)

# Load required libraries
library(optparse)
library(xml2)
library(dplyr)
library(ggplot2)

# Define command-line options
option_list <- list(
  make_option(c("-c", "--cluster"), type = "integer", help = "Cluster number", metavar = "integer"),
  make_option(c("-o", "--out"), type = "character", help = "Output folder path", metavar = "character"),
  make_option(c("-x", "--xml"), type = "character", help = "Path to gomo.xml file", metavar = "character"),
  make_option(c("-t", "--txt"), type = "character", help = "Path to cluster.txt file", metavar = "character"),
  make_option(c("-i", "--implied_c"), type = "character", default = "n", help = "Implied condition", metavar = "character")
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

cluster_num <- opt$cluster
out_folder <- opt$out
xml_file <- opt$xml
txt_file <- opt$txt
implied_c <- opt$implied_c

# Read XML data
gomo_data <- read_xml(xml_file)
motifs <- xml_find_all(gomo_data, "//motif")

# Extract relevant information from gomo.xml
results <- character()
for (motif in motifs) {
  motif_id <- xml_attr(motif, "id")
  goterms <- xml_find_all(motif, "goterm")
  
  for (goterm in goterms) {
    goterm_id <- xml_attr(goterm, "id")
    score <- xml_attr(goterm, "score")
    group <- xml_attr(goterm, "group")
    ontology <- switch(group, "b" = "BP", "m" = "MF", "c" = "CC", group)
    description <- xml_attr(goterm, "name")
    implied <- xml_attr(goterm, "implied")
    
    results <- c(results, paste(motif_id, goterm_id, score, ontology, description, implied, sep = "\t"))
  }
}

# Create data frame from extracted data
column_names <- "Motif_Identifier\tID\tscore\tONTOLOGY\tDescription\timplied"
all_lines <- c(column_names, results)
gomo_out <- read.table(textConnection(all_lines), header = TRUE, sep = "\t")

enrich_go_raw_out <- file.path(out_folder, paste0("cluster", cluster_num, "_enrich_go_raw.txt"))
write.table(gomo_out, enrich_go_raw_out, sep = '\t', row.names = FALSE, quote = FALSE)

# Process gomo_out data
gomo_out <- gomo_out %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), trimws)) %>%
  filter(implied == implied_c) %>%
  group_by(Motif_Identifier) %>%
  slice_min(score)

# Read cluster.txt file and merge with gomo_out
tomtom_txt_out <- read.table(txt_file, header = TRUE)
merged_data <- left_join(tomtom_txt_out, gomo_out, by = c("best_match_name" = "Motif_Identifier"), relationship = "many-to-many") %>%
  filter(!is.na(implied))

enrich_go <- merged_data %>%
  select(ID, Description, ONTOLOGY) %>%
  group_by(ID, Description, ONTOLOGY) %>%
  summarise(Count = n(), .groups = "drop")

enrich_go_out <- file.path(out_folder, paste0("cluster", cluster_num, "_enrich_go.txt"))
write.table(enrich_go, enrich_go_out, sep = '\t', row.names = FALSE, quote = FALSE)

# Prepare data for plotting
plot_df <- enrich_go %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), trimws))

plot_df$Count <- as.numeric(plot_df$Count)
plot_df$ONTOLOGY <- factor(plot_df$ONTOLOGY, levels = c("BP", "CC", "MF"))
plot_df <- plot_df[order(plot_df$ONTOLOGY, plot_df$Count, plot_df$Description), ]
plot_df$Description <- factor(plot_df$Description, levels = plot_df$Description)

# Define color scheme
COLS <- c("#FD8D62", "#8DA1CB", "#66C3A5")

# Generate bar plot
enrich_plot <- ggplot(plot_df, aes(x = Description, y = Count, fill = ONTOLOGY)) +
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

# Save plot
plot_out <- file.path(out_folder, paste0("cluster", cluster_num, ".png"))
ggsave(enrich_plot, file = plot_out, width = 9.03, height = 5.74, dpi = 300)
