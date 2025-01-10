'''
mKmer - a K-mer embedding algorithm using RNA K-mer matrix.
====================================================================

:Release: mKmer Group
:Verion:  1.0.0
:Date:    2024.12.30
:Tags:    mKmer analysis pipeline for single-microbe RNA-seq datasets

There are mainly 7 tools:
  - KmerCell	pipeline for generatal the cell-by-kmer matrix
  - KmerFrequency	pipeline for choice of the best K value
  - KmerGOn	pipeline for identifying clusters with motif database (DNA)
  - KmerGOp	pipeline for identifying clusters with motif database (protein)
  - KmerRank	pipeline for selection of optimal number of high count K-mers
  - RemoveDuplicates	pipeline for removal of repeat sequence of single-microbe RNA-seq datasets
  - smAnnotation	taxonomic annotation for each microbe in genus or species level

To get help on a specific tool, type:

	mKmer <tools> --help

To use a specific tools, type:

	mKmer <tool> [tools options] [tool argument]
'''

from __future__ import absolute_import
import os
import sys
import importlib
from mKmer import __version__

def main(argv = None):

  argv = sys.argv

  path = os.path.abspath(os.path.dirname(__file__))

  if len(argv) == 1 or argv[1] == "--help" or argv[1] == "-h":
    print(globals()["__doc__"])

    return

  elif len(argv) == 1 or argv[1] == "--version" or argv[1] == "-v":
    print("mKmer version: %s" % __version__)

    return

  elif argv[2] in ["--help", "-h", "--help-extended"]:
    print("mKmer: Version %s" % __version__)

  command = argv[1]

  module = importlib.import_module("mKmer." + command, "mKmer")
  ##remove 'mKmer' from sys.argv
  del sys.argv[0]
  module.main(sys.argv)

if __name__ == '__main__':
  sys.exit(main())
