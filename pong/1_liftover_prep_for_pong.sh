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
maf=$5

# Download 1000G phase 3 in hg19 as reference
wget -nv -P "$ref_dir" \
   ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
ref_fasta="${ref_dir}/human_g1k_v37.fasta.gz"
gunzip "${ref_dir}/human_g1k_v37.fasta.gz"
  # may produce warning about removing garbage at end due to legacy format
ref_fasta="${ref_fasta%.gz}"

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
   
# Sort variants
plink2 --vcf "${output_dir}/temp_${input_vcf_name}_hg19.vcf.gz" \
  --sort-vars \
  --make-pgen --out "${output_dir}/temp_${input_vcf_name}_hg19_sorted"

# Set all varids to chr:pos:ref:alt, apply MAF filter
plink2 --pfile "${output_dir}/temp_${input_vcf_name}_hg19_sorted" \
  --set-all-var-ids @:#:\$r:\$a --new-id-max-allele-len 600 \
  --maf "$maf" \
  --make-pgen --out "${output_dir}/temp_${input_vcf_name}_hg19_sorted_maf${maf}_chrpos_ids"

# Remove duplicate variants and write out PLINK1.9
plink2 --pfile "${output_dir}/temp_${input_vcf_name}_hg19_sorted_maf${maf}_chrpos_ids" \
  --rm-dup \
  --make-bed --out "${output_dir}/${input_vcf_name}_hg19_sorted_maf${maf}_chrpos_ids_dedup"

# Cleanup
rm "$output_dir"/temp_*
