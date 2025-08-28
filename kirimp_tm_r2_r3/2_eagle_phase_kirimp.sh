#!/bin/bash
if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_vcf> <hap_ref> <threads> <sub_region>"
   echo "Converts input VCF to BCF. If hap_ref argument is given "
   echo "given as file path to haplotype reference, also converts "
   echo "that to BCF. If hap_ref path given, phases with Eagle2 "
   echo "using it and the hg19 map from Eagle2. If hap_ref set to "
   echo "'no' then phases without a haplotype reference. Set "
   echo "sub_region to 'yes' to restrict to 20Mb around KIR*IMP "
   echo "SNPs or 'no' to run whole chromosome."
   exit
fi

input_vcf=$1
hap_ref=$2  # either path to haplotype reference or 'no'
threads=$3
sub_region=$4  # either 'yes' or 'no' to restrict to KIR*IMP region

# Hard coding 20Mb region (based on TOPMed server) around KIR*IMP SNPs
# chr19:55102179-55498744
reg_start=45300461
reg_stop=65300461

# Convert input to BCF for better phasing performance
vcf_name="${input_vcf%.vcf.gz}"
bcftools convert -Ob -o "$vcf_name".bcf \
	"$input_vcf"
tabix "$vcf_name".bcf

if [ "$hap_ref" = "no" ]; then
   if [ "$sub_region" = "yes" ]; then
      echo "Phasing without a haplotype reference and for the 20Mb around KIR*IMP."
      eagle --vcfTarget "$vcf_name".bcf \
         --geneticMapFile="/projects/sslack@xsede.org/software/Eagle_v2.4.1/tables/genetic_map_hg19_withX.txt.gz" \
         --numThreads=$threads \
         --allowRefAltSwap \
         --outPrefix="$vcf_name"_phased \
         --chrom 19 \
         --bpStart="$reg_start" \
         --bpEnd="$reg_stop"
   else
      echo "Phasing without a haplotype reference and for the whole chromosome."
      eagle --vcfTarget "$vcf_name".bcf \
         --geneticMapFile="/projects/sslack@xsede.org/software/Eagle_v2.4.1/tables/genetic_map_hg19_withX.txt.gz" \
         --numThreads=$threads \
         --allowRefAltSwap \
         --outPrefix="$vcf_name"_phased \
         --chrom 19
   fi
else
   hap_ref_name="${hap_ref%.vcf.gz}"
   bcftools convert -Ob -o "$hap_ref_name".bcf \
      "$hap_ref"
   tabix "$hap_ref_name".bcf

   if [ "$sub_region" = "yes" ]; then
      echo "Phasing with given haplotype reference and for the 20Mb around KIR*IMP."
      eagle --vcfTarget "$vcf_name".bcf \
         --geneticMapFile="/projects/sslack@xsede.org/software/Eagle_v2.4.1/tables/genetic_map_hg19_withX.txt.gz" \
         --vcfRef="$hap_ref_name".bcf \
         --numThreads=$threads \
         --allowRefAltSwap \
         --outPrefix="$vcf_name"_phased \
         --chrom 19 \
         --bpStart="$reg_start" \
         --bpEnd="$reg_stop"
   else
      echo "Phasing with given haplotype reference and for the whole chromosome."
      eagle --vcfTarget "$vcf_name".bcf \
         --geneticMapFile="/projects/sslack@xsede.org/software/Eagle_v2.4.1/tables/genetic_map_hg19_withX.txt.gz" \
         --vcfRef="$hap_ref_name".bcf \
         --numThreads=$threads \
         --allowRefAltSwap \
         --outPrefix="$vcf_name"_phased \
         --chrom 19
   fi
fi

# Make PLINK2 files for mapping with KIR*IMP ref
plink2 --vcf "$vcf_name"_phased.vcf.gz \
   --chr chr19 --make-pgen \
   --out "$vcf_name"_phased_plink
