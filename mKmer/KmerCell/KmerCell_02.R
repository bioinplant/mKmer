set.seed(42)

# Load required libraries
library(Matrix)
library(anndata)
library(reticulate)
library(optparse)

# Configure Python environment
env_path <- system("conda info --envs | grep -E '\\*' | awk '{print $3}'", intern = TRUE)
use_condaenv(condaenv = env_path, required = TRUE)
ad <- import("anndata")  # Import annData module for handling .h5ad files

# Initialize global variables
merged_matrix <- NULL

# Function definitions

#' Read and transpose .h5ad file
#' 
#' @param file_path Path to .h5ad file
#' @return Transposed matrix from the .h5ad file
read_and_transpose_h5ad <- function(file_path) {
    ann_data <- ad$read_h5ad(file_path)
    scrna_data <- t(ann_data$X)
    return(scrna_data)
}

# Main script

# Parse command line arguments
option_list <- list(
    make_option(
        c("-f", "--folder"),
        type = "character",
        default = "./h5ad",
        help = "Path to the folder containing .h5ad files",
        metavar = "character"
    )
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Get list of .h5ad files
h5ad_files <- list.files(
    path = opt$folder,
    pattern = "\\.h5ad$",
    full.names = TRUE
)

# Check if any .h5ad files are found
if (length(h5ad_files) == 0) {
    stop("No .h5ad files found in specified folder: ", opt$folder)
}

# Process each .h5ad file
for (file_path in h5ad_files) {
    # Read and transpose data
    scrna_data <- read_and_transpose_h5ad(file_path)
    
    # Check matrix dimensions consistency
    if (!is.null(merged_matrix) && nrow(merged_matrix) != nrow(scrna_data)) {
        warning("Row count mismatch in file: ", file_path, 
                "\nExpected: ", nrow(merged_matrix), 
                ", Found: ", nrow(scrna_data))
        next  # Skip this file
    }
    
    # Merge matrices column-wise
    if (is.null(merged_matrix)) {
        merged_matrix <- scrna_data
    } else {
        merged_matrix <- cbind(merged_matrix, scrna_data)
    }
    
    # Remove processed file
    file.remove(file_path)
}

# Get the folder path of the last processed file (if there are files to process)
if (length(h5ad_files) > 0) {
    folder_path <- dirname(h5ad_files[length(h5ad_files)])
} else {
    folder_path <- opt$folder
}

# Save merged matrix
if (!is.null(merged_matrix)) {
    saveRDS(merged_matrix, file = file.path(folder_path, "kmer_matrix.rds"))
    message("\nSuccessfully processed ", length(h5ad_files), " files.")
    message("Merged matrix dimensions: ", paste(dim(merged_matrix), collapse = " x "))
    message("Output saved to: ", file.path(folder_path, "kmer_matrix.rds"))
} else {
    warning("No valid data was processed. Output file not created.")
}
