# The tweave pipeline: .typ (with R chunks) -> .knit.typ -> .pdf ---------

#' Weave an R-Typst document and compile it to PDF
#'
#' Runs `input` through knitr with tweave's Typst output hooks, then calls
#' `typst compile` on the result.
#'
#' @param input Path to a `.typ` file containing R code chunks.
#' @param output Path for the intermediate knitted file. Defaults to
#'   `<input>.knit.typ` next to the input; removed after a successful
#'   compile unless `keep = TRUE` (always kept when compilation fails,
#'   since Typst's error messages point at its line numbers).
#' @param quiet Suppress knitr progress output.
#' @param keep Keep the intermediate `.knit.typ` after a successful build.
#' @return (Invisibly) the path to the compiled PDF.
#' @export
weave <- function(input, output = NULL, quiet = FALSE, keep = FALSE) {
  if (!file.exists(input)) {
    stop("Input file not found: ", input, call. = FALSE)
  }
  if (file.size(input) == 0) {
    stop("Input file is empty: ", input,
         "\n  (If you just wrote it in an editor, did you save?)",
         call. = FALSE)
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

  # Compile straight to <input>.pdf (no ".knit" in the final name).
  # NB: system2() does not quote arguments; paths may contain spaces
  pdf <- file.path(doc_dir, paste0(base, ".pdf"))
  status <- system2("typst", c("compile", "--root", shQuote(doc_dir),
                               shQuote(output), shQuote(pdf)))
  if (status != 0) {
    stop("typst compile failed (see message above).\n",
         "  The intermediate file was kept for debugging -- the error's ",
         "line numbers refer to it:\n  ", output, call. = FALSE)
  }

  if (!keep) unlink(output)
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
