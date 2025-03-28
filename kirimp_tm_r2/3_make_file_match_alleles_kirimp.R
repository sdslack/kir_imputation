#!/user/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)

print("Script makes file for PLINK to adjust TEDDY SNPs so encoding matches")
print("the KIR*IMP reference panel. First trailing arg should be input temp_")
print("pvar file output by 1_liftover_teddy_kirimp.sh. Second trailing arg")
print("should be the the KIR*IMP allele coding CSV file.")

library(tidyverse)

pvar_file <- args[1]
kirimp_file <- args[2]

pvar <- read_delim(pvar_file, comment = "##", show_col_types = FALSE)
kirimp <- read_csv(kirimp_file, show_col_types = FALSE)

print(paste0("Variants in KIR*IMP reference panel: ", nrow(kirimp)))
print(paste0("Variants in input data: ", nrow(pvar)))

# Merge by position
merge <- inner_join(pvar, kirimp, by = c("POS" = "position"))
print(paste0("Variants in inner_join of KIR*IMP ref and input data: ",
             nrow(merge)))

# Check that reference/alternate alleles match
merge_mod <- merge %>%
  mutate(match = case_when(REF == allele0 ~ "yes",
                           REF != allele0 ~ "no"))
print("Table showing match of KIR*IMP ref allele to data ref allele:")
table(merge_mod$match)

print(paste0("For reference alleles that don't match, table showing if instead ",
             "data alternate allele matches ref:"))
merge_mod_filt <- merge_mod %>%
  dplyr::filter(match == "no") %>%
  mutate(match_alt = case_when(ALT == allele0 ~ "yes",
                               ALT != allele0 ~ "no"))
table(merge_mod_filt$match_alt)

print(paste0("Will export .txt for PLINK2 --ref-allele for alleles where KIR*IMP ",
             "ref matches data alternate allele to match ref/alt allele coding ",
             "for input into KIR*IMP."))

merge_mod_filt_exp <- merge_mod_filt %>%
  dplyr::filter(match_alt == "yes") %>%
  dplyr::select(ID, allele0)

pvar_name <- gsub("temp_plink_", "", gsub(".pvar", "", basename(pvar_file)))
pvar_dir <- dirname(pvar_file)
write_tsv(merge_mod_filt_exp,
          paste0(pvar_dir, "/", pvar_name, "_alleles_recode_match_kirimp_ref.txt"),
          col_names = F)

