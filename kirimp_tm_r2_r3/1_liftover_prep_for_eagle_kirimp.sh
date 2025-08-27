#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_vcf> <crossmap_chain>"
   echo "       <ref_fasta> <output_dir>"
   echo "Script uses CrossMap.py for liftover to hg19."
   echo "After liftover, removes any previous phasing"
   echo "and prepares for input into Eagle for phasing."
   exit
fi

# Code based on Alex Romero's "Imputation.Rmd"
input_vcf=$1
crossmap_chain=$2
ref_fasta=$3
output_dir=$4

# Get basename of input_vcf
input_vcf_name=$(basename $input_vcf | sed 's/\.vcf.*//')

# Sort VCF
bcftools sort $input_vcf \
   -Oz -o "$output_dir"/temp_"$input_vcf_name"_sorted.vcf.gz

# Lift over from hg38 to hg19
CrossMap vcf \
   $crossmap_chain \
   "$output_dir"/temp_"$input_vcf_name"_sorted.vcf.gz \
   $ref_fasta \
   "$output_dir"/temp_"$input_vcf_name"_hg19.vcf.gz

# Pass through PLINK to remove previous phasing
plink2 --vcf  "$output_dir"/temp_"$input_vcf_name"_hg19.vcf.gz \
   --chr chr19 \
   --make-pgen erase-phase \
   --out "$output_dir"/temp_plink_no_phase_"$input_vcf_name"_hg19

plink2 --pfile  "$output_dir"/temp_plink_no_phase_"$input_vcf_name"_hg19 \
   --chr chr19 \
   --recode vcf \
   --out "$output_dir"/temp_no_phase_"$input_vcf_name"_hg19

# Sort lifted over VCF
bcftools sort "$output_dir"/temp_no_phase_"$input_vcf_name"_hg19.vcf \
   -Oz -o "$output_dir"/"$input_vcf_name"_hg19_sorted.vcf.gz

# Add AC & AN tags (required for Eagle)
bcftools +fill-AN-AC \
   "$output_dir"/"$input_vcf_name"_hg19_sorted.vcf.gz \
   -Ov -o "$output_dir"/"$input_vcf_name"_hg19_sorted_fill.vcf

# Compress
bgzip -f "$output_dir"/"$input_vcf_name"_hg19_sorted_fill.vcf

# Index sorted vcf
bcftools index "$output_dir"/"$input_vcf_name"_hg19_sorted_fill.vcf.gz

# Cleanup
# rm "$output_dir"/temp_*
