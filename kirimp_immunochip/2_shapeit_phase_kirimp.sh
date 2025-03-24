#!/bin/bash
if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <plink_input> <hap_ref> <threads>"
   echo "Converts input PLINK chr19 and input reference panel VCF"
   echo "to BCF and phases chr19 with SHAPEIT5. Uses 1000G genetic"
   echo "map and haplotype reference."
   exit
fi

plink_input=$1
threads=$2

# Get maps
# Genetic map
map="/projects/sslack@xsede.org/genetic_maps/hg19/kirimp/human_g1k_v37.fasta.gz"  # SHAPEIT4 recommended
if [ ! -f "$map" ]; then
    #wget -O "$map" "https://github.com/odelaneau/shapeit4/blob/master/maps/genetic_maps.b37.tar.gz" # SHAPEIT4 recommended, hapmap based
    wget  -O "$map" http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz  # 1000G based
fi
# Haplotype reference - 1000G
hap_ref="/projects/sslack@xsede.org/genetic_maps/hg19/kirimp/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz"
if [ ! -f "$hap_ref" ]; then
   wget -O "$hap_ref" \
      https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
   wget -O "${hap_ref}.tbi" \
      https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz.tbi
fi

# Convert to BCF for better phasing performance
hap_ref_name="${hap_ref%.vcf.gz}"

plink2 --bfile "$plink_input" \
   --export bcf \
   --out "$plink_input".bcf
tabix "$plink_input".bcf

if [ ! -f "$hap_ref_name".bcf ]; then
   bcftools convert -Ob -o "$hap_ref_name".bcf \
      "$hap_ref"
   tabix "$hap_ref_name".bcf
fi

SHAPEIT5_phase_common \
   --input "${plink_input}.bcf" \
   --reference "$hap_ref_name".bcf \
   --region 19 \
   --map "$map" \
   --output "${plink_input}_phased.bcf" \
   --thread $threads \
   --log "${plink_input}_shapeit_log.txt"

# Make temp PLINK2 files for mapping with KIR*IMP ref
plink2 --vcf "${plink_input}_phased.bcf" \
   --chr chr19 --make-pgen \
   --out "${plink_input}_phased_plink"