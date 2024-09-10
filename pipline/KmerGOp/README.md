# KmerGOp
### file--tomtom.R
'runTomTom' function you need to specify the database (https://meme-suite.org/meme/meme-software/Databases/motifs/motif_databases.12.24.tgz) and 'meme suit' tools.
The 'meme' file needs to be copied from the downloaded motif database to (e.g. Motif_databases/PROTEIN/prosite2021_04. Meme) mKmer virtual environment extdata folder (/path/to/anaconda3/envs/mKmer/lib/R/library/memes/extdata/)
```
# Specifies the code for the database
options(meme_db = system.file("extdata/prosite2021_04.meme", package = "memes", mustWork = TRUE))
```
The 'runTomTom' function needs to specify the folder where the meme suit tool resides, which is in the virtual environment of meme.
```
# Specify the code for the 'meme suit' tool
tomtom_out <- runTomTom(example_motif, meme_path = "/path/to/anaconda3/envs/meme/bin")
```
