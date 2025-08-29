#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_plink> <crossmap_chain> <out_dir> "
   echo "Script subsets to chr19, removes previous phasing, uses "
   echo "CrossMap for liftover to hg19, and prepares for input "
   echo "into Eagle2 for phasing."
   exit
fi

input_plink=$1  # path to PLINK prefix
crossmap_chain=$2
out_dir=$3

code_dir=$(dirname "$0")

### Liftover
# Modified from liftover repo, if revisit should update this to use
# that code directly instead of having a separate version here.

# Get input_plink without path and without extension
input_plink_name=$(basename "$input_plink")

# Subset to chr19 only. If input_plink is in PLINK2 format, also convert
# to PLINK1.9
if [ ! -f "${input_plink}.fam" ]; then
      plink2 --pfile "$input_plink" \
            --keep-allele-order --chr 19 \
            --make-bed \
            --out "${out_dir}/tmp_${input_plink_name}"
else
      plink2 --bfile "$input_plink" \
         --keep-allele-order --chr 19 \
         --make-bed \
         --out "${out_dir}/tmp_${input_plink_name}"
fi

# Create bed file to crossover from hg38 to hg19
cat "${out_dir}/tmp_${input_plink_name}.bim" | cut -f1 > ${out_dir}/tmp_c1.txt
cat "${out_dir}/tmp_${input_plink_name}.bim" | cut -f4 > ${out_dir}/tmp_c2.txt
cat "${out_dir}/tmp_${input_plink_name}.bim" | cut -f2 > ${out_dir}/tmp_c3.txt
paste ${out_dir}/tmp_c1.txt \
    ${out_dir}/tmp_c2.txt \
    ${out_dir}/tmp_c2.txt \
    ${out_dir}/tmp_c3.txt \
    > ${out_dir}/tmp_in.bed

# Do crossover
CrossMap bed "$crossmap_chain" \
   ${out_dir}/tmp_in.bed  \
   ${out_dir}/tmp_out.bed

# Extract only those SNPs that were successfully cross-overed
cut -f4 ${out_dir}/tmp_out.bed > ${out_dir}/tmp_snp_keep.txt
plink2 --bfile "${out_dir}/tmp_${input_plink_name}" \
    --extract ${out_dir}/tmp_snp_keep.txt \
    --make-bed --out ${out_dir}/tmp_gwas

# Update bim file positions
Rscript --vanilla ${code_dir}/update_pos.R \
    ${out_dir}/tmp_out.bed ${out_dir}/tmp_gwas.bim

# Set all varids to chr:pos:ref:alt and sort
plink2 --bfile ${out_dir}/tmp_gwas \
    --set-all-var-ids @:#:\$r:\$a --new-id-max-allele-len 1000 \
    --sort-vars \
    --make-pgen --out "${out_dir}/${input_plink_name}_chr19_hg19"

# Report SNP counts
orig_snp_nr=`wc -l ${out_dir}/tmp_${input_plink_name}.bim`
crossover_snp_nr=`wc -l ${out_dir}/tmp_gwas.bim`
echo "Original SNP nr: $orig_snp_nr"
echo "Crossovered SNP nr: $crossover_snp_nr"

# Cleanup

### Format for Eagle
plink2 --pfile "${out_dir}/${input_plink_name}_chr19_hg19" \
   --export vcf bgz \
   --out "${out_dir}/tmp_${input_plink_name}_chr19_hg19"

# Add AC & AN tags (required for Eagle)
bcftools +fill-AN-AC \
   "${out_dir}/tmp_${input_plink_name}_chr19_hg19.vcf.gz" \
   -Oz -o "${out_dir}/${input_plink_name}_chr19_hg19_fill.vcf.gz"

# Index sorted vcf
bcftools index "${out_dir}/${input_plink_name}_chr19_hg19_fill.vcf.gz"

# Cleanup
rm "$out_dir"/tmp_*
