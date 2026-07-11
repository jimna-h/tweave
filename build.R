# DEPRECATED: build.R has been replaced by the tweave R package.
# Install it (see README) and use the `tweave` command or tweave::weave().
message("NOTE: build.R is deprecated; forwarding to tweave::weave().")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("Usage: Rscript build.R <input.typ>")
tweave::weave(args[[1]])
