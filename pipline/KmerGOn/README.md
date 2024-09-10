# KmerGOn
### file--tomtom_meme_txt.R
'runTomTom' function you need to specify the database (https://meme-suite.org/meme/meme-software/Databases/motifs/motif_databases.12.24.tgz) and 'meme suit' tools
The meme file needs to be copied from the downloaded motif database to (e.g. motif_databases/PROKARYOTE/prodoric_2021.9.meme) mKmer virtual environment extdata folder (/path/to/anaconda3/envs/mKmer/lib/R/library/memes/extdata/)
```
# Specifies the code for the database
options(meme_db = system.file("extdata/prodoric_2021.9.meme", package = "memes", mustWork = TRUE))
```
The runTomTom function needs to specify the folder where the meme suit tool resides, which is in the virtual environment named meme.
```
# Specify the code for the meme suit tool
tomtom_out <- runTomTom(example_motif, meme_path = "/path/to/anaconda3/envs/meme/bin")
```
### file--run_ama_gomo.sh
This file requires the MEME suite's ama and gomo tools, and therefore the meme virtual environment needs to be activated.
```
# The script needs to be loaded
source /path/to/anaconda3/etc/profile.d/conda.sh
conda activate meme
```
