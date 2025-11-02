#!/bin/bash

umi_tools whitelist --stdin R1.fastq.gz \
                    --bc-pattern=CCCCCCCCCCCCCCCCCCCCNNNNNNNN \
                    --set-cell-number=15000 \
                    --log2stderr > whitelist.txt
umi_tools extract --bc-pattern=CCCCCCCCCCCCCCCCCCCCNNNNNNNN \
                  --stdin R1.fastq.gz \
                  --stdout R1_extracted.fastq.gz \
                  --read2-in R2.fastaq.gz \
                  --read2-out=R2_extracted.fastq.gz \
                  --filter-cell-barcode \
                  --whitelist=whitelist.txt
