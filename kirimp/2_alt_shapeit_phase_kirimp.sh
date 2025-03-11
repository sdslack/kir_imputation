#!/bin/bash

bed_fn=$1
nr_threads=$2
genetic_map_input_dir=$3
out_dir=$4

#Set bim and fam file name
bim_fn=`echo $bed_fn | sed 's/.bed/.bim/'`
fam_fn=`echo $bed_fn | sed 's/.bed/.fam/'`

#Set chr variable
#use the first column of the first line of the bim file to get this
chr=`head -1 $bim_fn | awk '{print $1}' | sed 's/chr//'`

#Run shapeit
shapeit --input-bed $bed_fn $bim_fn $fam_fn \
        --input-map ${genetic_map_input_dir}/chr${chr}.txt \
        --thread $nr_threads \
        --output-max ${out_dir}/chr${chr}.haps ${out_dir}/chr${chr}.samples
