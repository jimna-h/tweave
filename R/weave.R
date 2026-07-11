# The tweave pipeline: .typ (with R chunks) -> .knit.typ -> .pdf ---------

#' Weave an R-Typst document and compile it to PDF
#'
#' Runs `input` through knitr with tweave's Typst output hooks, then calls
#' `typst compile` on the result.
#'
#' @param input Path to a `.typ` file containing R code chunks.
#' @param output Path for the intermediate knitted file. Defaults to
#'   `<input>.knit.typ` next to the input.
#' @param quiet Suppress knitr progress output.
#' @return (Invisibly) the path to the compiled PDF.
#' @export
weave <- function(input, output = NULL, quiet = FALSE) {
  if (!file.exists(input)) {
    stop("Input file not found: ", input, call. = FALSE)
  }
  check_typst()

  input <- normalizePath(input)
  doc_dir <- dirname(input)
  base <- tools::file_path_sans_ext(basename(input))
  if (is.null(output)) {
    output <- file.path(doc_dir, paste0(base, ".knit.typ"))
  }

  # Knit from the document's directory so figure paths stay relative to it
  old_wd <- setwd(doc_dir)
  on.exit(setwd(old_wd), add = TRUE)

  # Set hooks/options, restoring whatever was there before we ran
  hooks <- tweave_hooks()
  old_hooks <- knitr::knit_hooks$get(names(hooks))
  on.exit(knitr::knit_hooks$set(old_hooks), add = TRUE)
  knitr::knit_hooks$set(hooks)

  opts <- tweave_chunk_opts(paste0("figure/", base, "/"))
  old_opts <- knitr::opts_chunk$get(names(opts))
  on.exit(knitr::opts_chunk$set(old_opts), add = TRUE)
  knitr::opts_chunk$set(opts)

  knitr::knit(input, output = output, quiet = quiet)

  status <- system2("typst", c("compile", "--root", doc_dir, output))
  if (status != 0) {
    stop("typst compile failed (see message above).", call. = FALSE)
  }

  pdf <- sub("\\.typ$", ".pdf", output)
  if (!quiet) message("Wrote ", pdf)
  invisible(pdf)
}

# Fail early, with instructions, if the Typst CLI is missing.
check_typst <- function() {
  if (Sys.which("typst") == "") {
    stop(
      "The Typst CLI was not found on your PATH.\n",
      "  Install it and try again:\n",
      "    Windows:  winget install --id Typst.Typst\n",
      "    macOS:    brew install typst\n",
      "    other:    https://github.com/typst/typst/releases\n",
      "  (If you just installed it, open a fresh terminal.)",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
