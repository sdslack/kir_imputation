#!/bin/bash
if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <hapsample_input> <snp_list>"
   echo "Subsets final hapsample files to given list of SNPs"
   echo "in KIRIMP map."
   exit
fi

hapsample_input=$1  # should be prefix without file extension
snp_list=$2  # should be list of variant IDs
out_suffix=$3

hapsample_base=$(basename "$hapsample_input")
hapsample_dir=$(dirname "$hapsample_input")

# Convert hapsample to VCF
bcftools convert --hapsample2vcf \
  "$hapsample_input" \
  -o "${hapsample_dir}/tmp_${hapsample_base}.vcf"

# Filter to keep only SNPs in given list
plink2 \
  --vcf "${hapsample_dir}/tmp_${hapsample_base}.vcf" \
  --make-pgen --set-all-var-ids @:#:\$r:\$a --new-id-max-allele-len 1000 \
  --out "${hapsample_dir}/tmp_${hapsample_base}_chrpos"
plink2 \
  --pfile "${hapsample_dir}/tmp_${hapsample_base}_chrpos" \
  --extract "$snp_list" \
  --export vcf \
  --out "${hapsample_dir}/tmp_${hapsample_base}_chrpos_vcf"

# Write out new hapsample
bcftools convert "${hapsample_dir}/tmp_${hapsample_base}_chrpos_vcf.vcf" \
	--hapsample "${hapsample_input}_${out_suffix}"

# Clean up
rm ${hapsample_dir}/tmp_*