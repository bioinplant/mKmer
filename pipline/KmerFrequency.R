library(optparse)
library(ggplot2)
library(dplyr)
library(scales)
library(tidyverse)
library(stringr)

option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input histo files, separated by commas", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", help = "Output file path", metavar = "character")
)

parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)
file_paths <- strsplit(opt$input, ",")[[1]]
output_path <- opt$out
colors <- c("#D8B365", "#5BB5AC", "#DE526C")
combined_data <- data.frame()
color_mapping <- setNames(colors, character(length(colors)))

first_peak_Coverage <- 0
last_peak_Frequency <- 0

for (i in seq_along(file_paths)) {
  file_path <- file_paths[i]
  kmer_data <- read.table(file_path)
  kmer_size <- str_extract(basename(file_path), "\\d+")
  data <- data.frame(Coverage = kmer_data$V1, Frequency = kmer_data$V2, Source = paste0(kmer_size, "-mer"))
  color_mapping[paste0(kmer_size, "-mer")] <- colors[i]
  combined_data <- rbind(combined_data, data)
  
  # 获取第一个文件的峰值Coverage和最后一个文件的峰值Frequency
  if (i == 1) {
    first_peak_Coverage <- data$Coverage[which.max(data$Frequency)]
  }
  if (i == length(file_paths)) {
    last_peak_Frequency <- max(data$Frequency)
  }
}

peak_info <- combined_data %>%
  group_by(Source) %>%
  summarize(peak_Coverage = Coverage[which.max(Frequency)], peak_Frequency = max(Frequency))

pic_dna <- ggplot(data = combined_data, aes(x = Coverage, y = Frequency, color = Source)) +
  geom_line(size = 2, show.legend = TRUE, key_glyph = "path") +
  geom_text(data = peak_info, aes(x = peak_Coverage + 20, y = 0.8 * peak_Frequency, 
                                  label = paste("Peak (", peak_Coverage, ", ", peak_Frequency, ")", sep = ""), 
                                  color = Source),
            vjust = -0.5, hjust = 0, size = 10, family = "Times New Roman") +
  xlim(0, first_peak_Coverage * 3) +
  ylim(0, last_peak_Frequency * 1.1) +
  labs(x = "Coverage", y = "Frequency", color = NULL) +
  theme_minimal() +
  theme(
    panel.background = element_rect(fill = 'white', color = 'black'),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    axis.title.x = element_text(size = 35, margin = margin(t = 20)), 
    axis.title.y = element_text(size = 35, margin = margin(r = 20)), 
    axis.text = element_text(size = 25, family = "Times New Roman", colour = "black"), 
    legend.key.size = unit(0.6, "inches"), 
    legend.position = c(0.95, 0.95), 
    legend.justification = c(1, 1),
    legend.background = element_blank(),
    legend.title = element_blank(),
    legend.text = element_text(size = 30, family = "Times New Roman"),
    legend.key.width = unit(10, "line"),
    text = element_text(family = "Times New Roman", size = 30)
  ) +
  guides(color = guide_legend(override.aes = list(size = 2))) +
  scale_color_manual(values = color_mapping) +
  scale_y_continuous(labels = scales::scientific) 

ggsave(paste0(output_path, "KmerFrequency.png"), plot = pic_dna, width = 15, height = 12, units = "in", dpi = 300, bg = "white")
