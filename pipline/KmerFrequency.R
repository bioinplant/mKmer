library(optparse)
library(ggplot2)
library(dplyr)
library(scales)
library(tidyverse)
library(stringr)

# 定义参数列表
option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input histo files, separated by commas", metavar = "character"),
  make_option(c("-o", "--out"), type = "character", help = "Output file path", metavar = "character")
)

# 解析参数
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

# 获取输入文件和输出文件路径
file_paths <- strsplit(opt$input, ",")[[1]]
output_path <- opt$out

# 定义颜色向量
colors <- c("#D8B365", "#5BB5AC", "#DE526C")

# 创建一个空的数据框来存储合并后的数据
combined_data <- data.frame()

# 创建一个空的命名向量来存储颜色映射
color_mapping <- setNames(colors, character(length(colors)))

# 定义变量以存储第一个和最后一个文件的峰值
first_peak_Coverage <- 0
last_peak_Frequency <- 0

# 循环读取每个文件，并提取文件名中的数字
for (i in seq_along(file_paths)) {
  file_path <- file_paths[i]
  kmer_data <- read.table(file_path)
  kmer_size <- str_extract(basename(file_path), "\\d+")
  
  # 创建数据框并添加来源列
  data <- data.frame(Coverage = kmer_data$V1, Frequency = kmer_data$V2, Source = paste0(kmer_size, "-mer"))
  
  # 更新颜色映射
  color_mapping[paste0(kmer_size, "-mer")] <- colors[i]
  
  # 合并数据
  combined_data <- rbind(combined_data, data)
  
  # 获取第一个文件的峰值Coverage和最后一个文件的峰值Frequency
  if (i == 1) {
    first_peak_Coverage <- data$Coverage[which.max(data$Frequency)]
  }
  if (i == length(file_paths)) {
    last_peak_Frequency <- max(data$Frequency)
  }
}

# 找到每个数据源的峰值位置并获取峰值的覆盖次数和频率
peak_info <- combined_data %>%
  group_by(Source) %>%
  summarize(peak_Coverage = Coverage[which.max(Frequency)],
            peak_Frequency = max(Frequency))

# 创建ggplot对象
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
    axis.title.x = element_text(size = 35, margin = margin(t = 20)), #x坐标轴标题
    axis.title.y = element_text(size = 35, margin = margin(r = 20)), #y坐标轴标题
    axis.text = element_text(size = 25, family = "Times New Roman", colour = "black"), #坐标轴数值
    legend.key.size = unit(0.6, "inches"), #图例的大小
    legend.position = c(0.95, 0.95), #图例的位置
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


# 保存为png图片
ggsave(paste0(output_path, "KmerFrequency.png"), plot = pic_dna, width = 15, height = 12, units = "in", dpi = 500, bg = "white")
