# Set random seed for reproducibility
set.seed(42)

# Load necessary libraries
library(optparse)
library(ggplot2)
library(ggbump)
library(dplyr)
library(scales)
library(tidyverse)

# Define command-line options
option_list <- list(
  make_option(c("-i", "--input"), 
              type = "character", 
              default = NULL, 
              help = "Path to the 12mer_counts.histo file", 
              metavar = "character"),
  make_option(c("-o", "--out"), 
              type = "character", 
              default = NULL, 
              help = "Output file path", 
              metavar = "character")
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Assign input arguments to variables
kmer_file <- opt$input
out_path <- opt$out

# Check if both input file and output path are provided
if (is.null(kmer_file) | is.null(out_path)) {
  print_help(opt_parser)
  stop("Both input kmer file and output path must be provided.", call. = FALSE)
}

# Read and process the kmer data
kmer <- read.table(kmer_file)
kmer <- kmer %>% arrange(desc(V1))
kmer$V3 <- cumsum(kmer$V2)

# Calculate the maximum value for scaling
max_value <- max(kmer$V1)
y_max <- 10^ceiling(log10(max_value))
y_breaks <- 10^(0:ceiling(log10(max_value)))

# Function to find the "knee point" in the kmer data
find_knee_point <- function(kmer) {
  log_x <- log10(kmer$V3)
  log_y <- log10(kmer$V1)
  
  # Consider the middle 80% of the data for knee point detection
  mid_range <- round(nrow(kmer) * 0.1):round(nrow(kmer) * 0.9)
  
  # Compute the first derivative
  first_derivative <- diff(log_y[mid_range]) / diff(log_x[mid_range])
  
  # Find the knee point by locating the maximum absolute value of the first derivative
  knee_point_index <- mid_range[which.max(abs(first_derivative)) + 1]
  
  return(knee_point_index)
}

# Identify the knee point
knee_point_index <- find_knee_point(kmer)
knee_point <- kmer[knee_point_index, ]
kmer$color <- ifelse(kmer$V3 <= knee_point$V3, "darkblue", "lightgray")

# Create the plot
pic <- ggplot(kmer, aes(x = V3, y = V1, color = color)) +
  geom_point(size = 4) +
  scale_color_identity() +
  geom_vline(xintercept = knee_point$V3, color = "darkblue", linetype = "dashed", size = 2) +
  scale_x_log10(breaks = y_breaks, 
                labels = trans_format("log10", math_format(10^.x))) +
  scale_y_log10(breaks = y_breaks,
                labels = trans_format("log10", math_format(10^.x)),
                limits = c(1, y_max)) +
  labs(x = "K-mer index", y = "K-mer count", size = 100) + 
  coord_fixed(ratio = 1) +
  theme_minimal() +
  theme(panel.background = element_rect(fill = 'white', color = 'black'),
        panel.grid.major = element_line(color = "grey90"),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        text = element_text(family = "Times New Roman", size = 38), 
        axis.title.x = element_text(size = 32, margin = margin(t = 20)),
        axis.title.y = element_text(size = 32, margin = margin(r = 20)),
        axis.text = element_text(size = 25, colour = "black")) +
  annotate("text", x = knee_point$V3, y = 5, 
           label = paste0("x=", knee_point$V3), color = "darkblue",
           vjust = 1.5, hjust = -0.2, size = 12, family = "Times New Roman")

# Save the plot
ggsave(paste0(out_path, "KmersRank.png"), plot = pic, width = 12, height = 12, units = "in", dpi = 300, bg = "white")
