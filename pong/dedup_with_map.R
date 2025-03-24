# SDS 20250313

# model <- "/Users/slacksa/Downloads/Global_PredictionModel.RData"
model <- "/Users/slacksa/Downloads/Global_PredictionModel_Extended_Window.RData"

#TODO: check extended model!

# plink_pvar <- paste0(
#   Sys.getenv("RKJCOLLAB"),
#   "/DAISY/genetics/daisy_ask_genetics/1000g_imp/imputed_clean_maf0_rsq0.3/chr_all_concat.pvar")
# plink_pvar <- paste0(
#   Sys.getenv("RKJCOLLAB"),
#   "/Immunogenetics_T1D/data/imputation/teddy/1000g_imp/filt_miss_filt_snps/imputed_clean_maf0_rsq0.3/chr19_clean.pvar")
# plink_bim <- "/Users/slacksa/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/DAISY/genetics/daisy_ask_genetics/daisyask_exome_array/clean/daisyexome.bim"
plink_bim <- "/Users/slacksa/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Immunogenetics_T1D/raw/teddy/2023-09-27/SNP_masked_rj.bim"
# info <- read_delim(
#   gzfile("/Users/slacksa/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Immunogenetics_T1D/data/imputation/teddy/1000g_imp/filt_miss_filt_snps/imputed/chr19.info.gz"),
#   comment = "##")


# model <- args[1]
# plink_pvar <- args[2]

load(model)

# If input is PLINK2
plink_pvar <- read_delim(plink_pvar, comment = "##")
plink_pvar_chr19 <- plink_pvar %>%
  dplyr::filter(str_detect(`#CHROM`, "19"))

# If input is PLINK1.9
plink_pvar <- read_delim(
  plink_bim, col_names = c("chr", "id", "cm", "POS", "a1", "a2"))
plink_pvar_chr19 <- plink_pvar %>%
  dplyr::filter(str_detect(chr, "19"))

# If input is INFO
plink_pvar_chr19 <- info %>%
  dplyr::filter(str_detect(`#CHROM`, "19"))

print(paste0(
  "There are ", n_distinct(model.obj$snp.position), " SNP positions in model ",
  basename(model), "."))
print(paste0(
  "There are ", n_distinct(plink_pvar_chr19$POS), " SNP positions in chr19 of input data."
))
overlap <- intersect(model.obj$snp.position, plink_pvar_chr19$POS)
print(paste0(
  "There are ", n_distinct(overlap), " SNP positions that overlap (",
  round((n_distinct(overlap) / n_distinct(model.obj$snp.position))*100,
        digits = 1), "%)."
))
# DAISY 1000G Rsq 0.3 - 15% overlap
# TEDDY 1000G Rsq 0.3 - 3% overlap
# DAISY chip - 0.1% overlap
# TEDDY combined chip (no filtering) - 0.1% overlap - RECHECK hg38
# DAISY 1000G no filter - 
# TEDDY 1000G no filter - 100% overlap
# TEDDY chip with extended map - 0.1% - RECHECK hg38

# TODO: planning to continue here to write out files to use in PLINK to match
# input dataset with map.
