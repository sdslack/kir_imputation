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
hap_ref_dir=$2
threads=$3

# TODO: add check for hap ref bcf and skip first part if found

# Download 1000G phase 3 in hg19 as reference
# wget -nv -P "$hap_ref_dir" \
   # ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz{,.tbi}
hap_ref="ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz"

# Download genetic map
# wget -nv -P "$hap_ref_dir" \
#    https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/tables/genetic_map_hg19_withX.txt.gz

# Convert to BCF for better phasing performance
vcf_name="${vcf_input%.vcf.gz}"
hap_ref_name="${hap_ref%.vcf.gz}"

bcftools convert -Ob -o "$vcf_name".bcf \
	"$vcf_input"
tabix "$vcf_name".bcf

bcftools convert -Ob -o "${hap_ref_dir}/${hap_ref_name}.bcf" \
	"${hap_ref_dir}/${hap_ref}"
tabix "${hap_ref_dir}/${hap_ref_name}.bcf"

# Run phasing with Eagle
# --vcfRef="${hap_ref_dir}/${hap_ref_name}.bcf"
# --allowRefAltSwap
# if re-add, needs to be --vcfTarget, not --vcf
eagle --vcf "$vcf_name".bcf \
	--geneticMapFile="${hap_ref_dir}/genetic_map_hg19_withX.txt.gz" \
	--numThreads=$threads \
	--chrom 19 \
	--outPrefix="$vcf_name"_phased

# Make temp PLINK2 files for mapping with KIR*IMP ref
plink2 --vcf "$vcf_name"_phased.vcf.gz \
   --chr chr19 --make-pgen \
   --out "$vcf_name"_phased_plink
