#!/bin/bash
if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <plink_input> <threads>"
   echo "Converts input PLINK chr19 and input reference panel VCF"
   echo "to BCF and phases chr19 with SHAPEIT5. Uses hapmap genetic"
   echo "map and 1000G haplotype reference."
   exit
fi

plink_input=$1
code_dir=$2
threads=$3

# Get SHAPEIT5 dockerfile
# cd "$code_dir"
# docker="${code_dir}/shapeit5_v5.1.1"
# if [ ! -f "${docker}.sif" ]; then
#     wget -O "${docker}.tar.gz" https://github.com/odelaneau/shapeit5/releases/download/v5.1.1/shapeit5_v5.1.1.docker.tar.gz
#     gunzip "${docker}.tar.gz"
#     apptainer build shapeit5_v5.1.1.sif docker-archive://"${docker}.tar"
# fi

# Get maps
# Genetic map
map="/projects/sslack@xsede.org/genetic_maps/hg19/kirimp/chr19.b37.gmap.gz"  # SHAPEIT5 recommended
if [ ! -f "$map" ]; then
    wget -O "$map" https://github.com/odelaneau/shapeit5/raw/refs/heads/main/resources/maps/b37/chr19.b37.gmap.gz
    # wget -O "$map" https://github.com/odelaneau/shapeit4/blob/master/maps/genetic_maps.b37.tar.gz # SHAPEIT4 recommended, hapmap based
    # wget  -O "$map" http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz  # 1000G based
fi
# Haplotype reference - 1000G
hap_ref="/projects/sslack@xsede.org/genetic_maps/hg19/kirimp/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz"
if [ ! -f "$hap_ref" ]; then
   wget -O "$hap_ref" \
      https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
   wget -O "${hap_ref}.tbi" \
      https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr19.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz.tbi
fi

# Add AC & AN tags (required for SHAPEIT)
input_dir=$(dirname "$plink_input")
plink_name=$(basename "$plink_input")
plink2 --bfile "$plink_input" \
   --export vcf bgz \
   --out "${input_dir}/tmp_{plink_name}_vcf"
   
bcftools +fill-AN-AC \
   "${input_dir}/tmp_{plink_name}_vcf.vcf.gz" \
   -Oz -o "${input_dir}/tmp_{plink_name}_vcf_fill.vcf.gz"

bcftools convert -Ob -o "${plink_input}.bcf" \
	"${input_dir}/tmp_{plink_name}_vcf_fill.vcf.gz"
	tabix "$plink_input".bcf
tabix -f "${plink_input}.bcf"

hap_ref_name="${hap_ref%.vcf.gz}"
if [ ! -f "$hap_ref_name".bcf ]; then
   bcftools convert -Ob -o "$hap_ref_name".bcf \
      "$hap_ref"
   tabix "$hap_ref_name".bcf
fi

#TODO: not sure if phase_common_static is most up to date?
# apptainer exec ${docker}.sif phase_common_static \
SHAPEIT5_phase_common \
   --input "${plink_input}.bcf" \
   --reference "$hap_ref_name".bcf \
   --region 19 \
   --map "$map" \
   --output "${plink_input}_phased.bcf" \
   --thread $threads \
   --log "${plink_input}_shapeit_log.txt"

# Make temp PLINK2 files for mapping with KIR*IMP ref
plink2 --bcf "${plink_input}_phased.bcf" \
   --chr chr19 --make-pgen \
   --out "${plink_input}_phased_plink"
   
# Clean up
rm ${input_dir}/tmp_*