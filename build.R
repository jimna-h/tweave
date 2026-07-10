library(knitr)

# 1. Capture the input filename from the command line
args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) > 0) args[1] else "hw.typ"

# 2. Paths: work in the caller's directory, but find qmdhooks.r
#    next to this script (no hardcoded paths)
get_script_dir <- function() {
  # Rscript passes the script path as --file=...
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }
  # Fallback: allow an env var override, else assume current directory
  env <- Sys.getenv("QMDTEMPLATE_HOME", unset = "")
  if (nzchar(env)) return(env)
  getwd()
}

script_dir  <- get_script_dir()
base_path   <- getwd()
base_name   <- tools::file_path_sans_ext(input_file)
knit_output <- file.path(base_path, paste0(base_name, ".knit.typ"))

# 3. Configure knitr
opts_chunk$set(
  dev = "png",
  fig.path = paste0("figure/", base_name, "/"),
  fig.show = "asis",
  comment = ""
)

# 4. Load hooks and knit
source(file.path(script_dir, "qmdhooks.r"))
knitr::knit(input_file, output = knit_output)

# 5. Compile to PDF
status <- system2("typst", c("compile", "--root", shQuote(base_path), shQuote(knit_output)))
if (status != 0) stop("typst compile failed (is typst on your PATH?)")
