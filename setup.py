import subprocess
from setuptools import setup
from setuptools.command.install import install

class CustomInstallCommand(install):
    def run(self):
        self.install_conda_packages()
        install.run(self)

    def install_conda_packages(self):
        conda_commands = [
            "conda install python=3.8.20 -y",
            "conda install -c r r-base=4.3.2 -y",
            "conda install -c bioconda meme=5.5.7 -y",
            "conda install -c bioconda umi_tools=1.1.4 -y",
            "conda install -c bioconda jellyfish=2.2.10 -y",
            "conda install -c conda-forge anndata=0.9.2 -y",
            "conda install -c bioconda seqkit=2.8.2 -y",
            "conda install -c bioconda kraken2=2.1.3 -y",
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
            "conda install -c bioconda r-ggbump=0.1.0 -y",
            "conda install -c bioconda r-gert=2.0.1 -y"
        ]
        
        for command in conda_commands:
            print("Running command:", command)
            subprocess.check_call(command, shell=True)

setup(
    name="mKmer",
    version="1.0.0",
    packages=[
        'mKmer',
        'mKmer.KmerCell',
        'mKmer.KmerFrequency',
        'mKmer.KmerGOn',
        'mKmer.KmerGOp',
        'mKmer.KmerRank',
        'mKmer.RemoveDuplicates',
        'mKmer.smAnnotation'
    ],
    entry_points={'console_scripts': ['mKmer = mKmer.cli:main']},
    include_package_data=True,
    package_data={
        'mKmer.KmerCell': ['KmerCell.py'],
        'mKmer.KmerFrequency': ['KmerFrequency.py'],
        'mKmer.KmerGOn': ['KmerGOn.py'],
        'mKmer.KmerGOp': ['KmerGOp.py'],
        'mKmer.KmerRank': ['KmerRank.py'],
        'mKmer.RemoveDuplicates': ['RemoveDuplicates.py'],
        'mKmer.smAnnotation': ['smAnnotation.py'],
    },
    cmdclass={
        'install': CustomInstallCommand,
    },
)
