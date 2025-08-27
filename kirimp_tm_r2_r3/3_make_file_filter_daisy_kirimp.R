#!/user/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)

print("Script makes file for PLINK to filter DAISY/ASK individuals to just")
print("DAISY individuals.")

library(tidyverse)

psam_file <- args[1]

psam <- read_delim(psam_file, show_col_types = F, col_names = T)

# Create list of DAISY IDs
  # DAISY ID format: #####-# (one sample ends with -3!)
list_daisy <- psam %>%
  filter(grepl("([[:digit:]]){5}-[[:digit:]]_([[:digit:]]){5}-[[:digit:]]$", `#IID`)) %>%
  select(`#IID`)

# Write out file to be used with PLINK --keep
write_tsv(list_daisy, "daisy_id_list.txt", col_names = F)
