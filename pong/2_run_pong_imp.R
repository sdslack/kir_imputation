#!/user/bin/env Rscript

# Runs PONG based on Suraju's pipeline. Working directory needs to be
# KIRpong/data.

args <- commandArgs(trailingOnly=TRUE)

# Setup ------------------------------------------------------------------------

library(KIRpong)

plink_file <- args[1]
out_dir <- args[2]

# Settings that don't change
model_file="Global_PredictionModel.RData"
HLA_allele="KIR3DLS1"     

# Run --------------------------------------------------------------------------

bim_file <- paste0(plink_file, ".bim")
bed_file <- paste0(plink_file, ".bed")
fam_file <- paste0(plink_file, ".fam")

model.list=get(load(model_file))
hla.id=HLA_allele

yourgeno=hlaBED2Geno(
  bed.fn=bed_file, fam.fn=fam_file, bim.fn=bim_file, assembly="hg19")

model=hlaModelFromObj(model.list)

pred.guess=predict(
  model, yourgeno, type="response+prob", match.type = "Position")

pred.guess_value = as.data.frame(pred.guess$value)
pred.guess_postprob = as.data.frame(pred.guess$postprob)

# Write out --------------------------------------------------------------------

write.table(
  pred.guess_value,
  paste0(out_dir, "/KIR3DLS1_pred_guess_value.txt"),
  quote=F, sep="\t", row.names=F, col.names=T)
write.table(
  pred.guess_postprob,
  paste0(out_dir, "/KIR3DLS1_pred_guess_postprob.txt"),
  quote=F, sep="\t", row.names=F, col.names=T)
