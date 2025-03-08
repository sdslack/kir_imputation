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

input_vcf=$1
crossmap_chain=$2
ref_dir=$3
output_dir=$4

# Download 1000G phase 3 in hg19 as reference
# wget -nv -P "$ref_dir" \
   # ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
ref_fasta="${ref_dir}/human_g1k_v37.fasta.gz"

# Get basename of input_vcf
input_vcf_name=$(basename $input_vcf | sed 's/\.vcf.*//')

# Sort VCF
bcftools sort $input_vcf \
   -Oz -o "$output_dir"/temp_"$input_vcf_name"_sorted.vcf.gz

# Lift over from hg38 to hg19
CrossMap.py vcf \
   $crossmap_chain \
   "$output_dir"/temp_"$input_vcf_name"_sorted.vcf.gz \
   $ref_fasta \
   "$output_dir"/temp_"$input_vcf_name"_hg19.vcf.gz

# Set all varids to chr:pos:ref:alt
plink2 --bfile "$output_dir"/temp_"$input_vcf_name"_hg19.vcf.gz \
  --set-all-var-ids @:#:\$r:\$a --new-id-max-allele-len 600 \
  --make-pgen --out "$output_dir"/temp_"$input_vcf_name"_hg19_chrpos_ids

# Remove duplicate variants
plink2 --bfile "$output_dir"/temp_"$input_vcf_name"_hg19_chrpos_ids \
  --rm-dup --recode vcf bgz \
  --out "$output_dir"/$input_vcf_name"_hg19"

# Sort lifted over VCF
bcftools sort "$output_dir"/$input_vcf_name"_hg19.vcf.gz" \
   -Oz -o "$output_dir"/$input_vcf_name"_hg19_sorted.vcf.gz"

# Index sorted vcf
bcftools index "$output_dir"/$input_vcf_name"_hg19_sorted.vcf.gz"

# Cleanup
rm "$output_dir"/temp_*
