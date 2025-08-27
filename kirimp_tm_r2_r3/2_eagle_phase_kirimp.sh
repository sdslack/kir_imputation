#!/bin/bash
if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <vcf_input> <hap_ref> <threads>"
   echo "Converts input VCF and input reference panel VCF"
   echo "to BCF and phases with Eagle v2.4.1, using the"
   echo "hg38 map provided with Eagle."
   exit
fi

vcf_input=$1
hap_ref=$2
threads=$3

# Convert to BCF for better phasing performance
vcf_name="${vcf_input%.vcf.gz}"
hap_ref_name="${hap_ref%.vcf.gz}"

bcftools convert -Ob -o "$vcf_name".bcf \
	"$vcf_input"
tabix "$vcf_name".bcf

bcftools convert -Ob -o "$hap_ref_name".bcf \
	"$hap_ref"
tabix "$hap_ref_name".bcf

# Run phasing with Eagle
eagle --vcfTarget "$vcf_name".bcf \
	--geneticMapFile="/projects/sslack@xsede.org/software/Eagle_v2.4.1/tables/genetic_map_hg19_withX.txt.gz" \
	--vcfRef="$hap_ref_name".bcf \
	--numThreads=$threads \
	--allowRefAltSwap --chrom 19 \
	--outPrefix="$vcf_name"_phased

# Make temp PLINK2 files for mapping with KIR*IMP ref
plink2 --vcf "$vcf_name"_phased.vcf.gz \
   --chr chr19 --make-pgen \
   --out "$vcf_name"_phased_plink
