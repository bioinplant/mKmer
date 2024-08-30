#!/bin/bash

umi_tools whitelist --stdin /path/to/sample_R1.fq.gz \
                                   --extract-method=regex \
                                   --bc-pattern="(?P<cell_1>.{20})(?P<umi_1>.{8})" \
                                   --expect-cells=10000  --plot-prefix=QC --log2stderr --subset-reads=100000000 \
                                   --knee-method=density --allow-threshold-error > QC_whitelist.txt

umi_tools whitelist --stdin /path/to/sample_R1.fq.gz \
                                   --set-cell-number=10000 \
                                   --method=umis --plot-prefix=QC \
                                   --extract-method=regex \
                                   --bc-pattern="(?P<cell_1>.{20})(?P<umi_1>.{8}).*" \
                                   --stdout whitelist.txt

umi_tools extract --extract-method=regex --bc-pattern="(?P<cell_1>.{20})(?P<umi_1>.{8}).*" \
                                 --stdin /path/to/sample_R1.fq.gz \
                                 --stdout R1_extracted.fq.gz \
                                 --read2-in /path/to/sample_R2.fq.gz \
                                 --read2-out=R2_extracted.fq.gz \
                                 --whitelist whitelist.txt --error-correct-cell

