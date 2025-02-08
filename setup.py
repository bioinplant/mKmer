from setuptools import setup

setup(
    name="mKmer",
    version="1.0.0",
    packages=['mKmer'],
    entry_points={'console_scripts': ['mKmer = mKmer.cli:main']},
)
