#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_vcf> <crossmap_chain>"
   echo "       <ref_fasta> <output_dir> <maf>"
   echo "Input should be VCF with only chromosome 19."
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
# wget -nv -P "$ref_dir" \
#    ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
ref_fasta="${ref_dir}/human_g1k_v37.fasta.gz"
gunzip "${ref_dir}/human_g1k_v37.fasta.gz"
  # may produce warning about removing garbage at end due to legacy format
ref_fasta="${ref_fasta%.gz}"

# Get basename of input_vcf
input_vcf_name=$(basename $input_vcf | sed 's/\.vcf.*//')
echo $input_vcf_name

# Sort VCF
bcftools sort $input_vcf \
   -Oz -o "$output_dir"/temp_"$input_vcf_name"_sorted.vcf.gz

# Lift over from hg38 to hg19
CrossMap vcf \
   $crossmap_chain \
   "$output_dir"/temp_"$input_vcf_name"_sorted.vcf.gz \
   $ref_fasta \
   "$output_dir"/temp_"$input_vcf_name"_hg19.vcf.gz

# Pass through PLINK1.9 to remove previous phasing and write out non-temp
# file that is lifted over and MAF filtered version of original input
plink2 --vcf "$output_dir"/temp_"$input_vcf_name"_hg19.vcf.gz \
   --chr chr19 --maf $maf \
   --make-bed \
   --out "$output_dir"/"$input_vcf_name"_maf${maf}_hg19

plink2 --bfile "$output_dir"/"$input_vcf_name"_maf${maf}_hg19 \
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
rm "$output_dir"/temp_*
