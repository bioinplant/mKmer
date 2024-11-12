import subprocess

def install_conda_packages():
    conda_commands = [
        "conda install python=3.8 -y",
        "conda install -c r r-base=4.3.2 -y",
        "conda install -c bioconda umi_tools=1.1.4 -y",
        "conda install -c bioconda jellyfish=2.2.10 -y",
        "conda install -c conda-forge anndata=0.9.2 -y",
        "conda install -c bioconda seqkit=2.8.2 -y",
        "conda install -c bioconda kraken2=2.0.7_beta -y",
        "conda install -c bioconda bracken=2.8 -y",
        "conda install -c conda-forge openjdk=11.0.23 -y",
        "conda install -c bioconda r-Matrix=1.6.3 -y",
        "conda install -c bioconda r-anndata=0.7.5.6 -y",
        "conda install -c bioconda r-reticulate=1.34.0 -y",
        "conda install -c bioconda r-optparse=1.7.5 -y",
        "conda install -c bioconda r-ggplot2=3.4.4 -y",
        "conda install -c bioconda r-ggseqlogo=0.2 -y",
        "conda install -c bioconda r-patchwork=1.1.3 -y",
        "conda install -c bioconda r-tidyverse=2.0.0 -y",
        "conda install -c bioconda r-ggbump=0.1.0 -y"
    ]
    
    for command in conda_commands:
        subprocess.call(command, shell=True)

def install_r_packages():
    r_command = (
        "Rscript -e \""
        "options(repos = list(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')); "
        "install.packages('BiocManager'); "
        "BiocManager::install('universalmotif'); "
        "BiocManager::install('memes'); "
        "BiocManager::install('GO.db')"
        "\""
    )
    
    subprocess.call(r_command, shell=True)

if __name__ == "__main__":
    install_conda_packages()
    install_r_packages()