from setuptools import setup

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
