#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_vcf> <crossmap_chain>"
   echo "       <ref_fasta> <output_dir>"
   echo "Takes PLINK2 files, removes duplicate SNPs while"
   echo "preferentially keeping those in PONG map. Outputs"
   echo "PLINK1.9 files for input into PONG."
   exit
fi

# TEMP NOTES
# Think PONG map encodes snp.allele as alt/ref

plink_prefix=$1
output_dir=$2

# Set all varids to chr:pos:ref:alt
plink2 --pfile "$plink_prefix" \
  --set-all-var-ids @:#:\$r:\$a --new-id-max-allele-len 1000 \
  --make-pgen --out "${output_dir}/temp_${plink_prefix}_chrpos_ids"

# Remove duplicate variants and write out PLINK1.9
plink2 --pfile "${output_dir}/temp_${plink_prefix}_chrpos_ids" \
  --rm-dup \
  --make-bed --out "${output_dir}/${plink_prefix}_chrpos_ids_dedup"

# Cleanup
rm "$output_dir"/temp_*
