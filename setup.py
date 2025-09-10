from setuptools import setup
import os
import subprocess

def set_executable_permission():
    target_path = "mKmer/smAnnotation/kraken2-report/kraken2-report"
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    full_path = os.path.join(base_dir, target_path)
    
    if os.path.exists(full_path):
        try:
            os.chmod(full_path, 0o755)
            print(f"\n\033[92mSuccess: -> {full_path}\033[0m")
        except Exception as e:
            print(f"\n\033[91mError: {str(e)}\033[0m")
    else:
        print(f"\n\033[93mWarning: -> {full_path}\033[0m")
        print(f"work: {os.getcwd()}")
        print(f"path: {full_path}")
        print(f"list: {os.listdir(os.path.dirname(full_path))}")

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
)

if __name__ == "__main__":
    set_executable_permission()
