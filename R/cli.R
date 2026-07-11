# Command-line entry point ----------------------------------------------

#' CLI entry point for the `tweave` command
#'
#' Called by the shell shims as `Rscript -e "tweave::main()" <args>`.
#' Not intended for interactive use; call [weave()] from R instead.
#'
#' @param args Command-line arguments (for testing; defaults to the real ones).
#' @export
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) == 0 || args[[1]] %in% c("-h", "--help")) {
    cat(
      "tweave -- knit R code chunks in a Typst document and compile to PDF\n",
      "\n",
      "Usage:\n",
      "  tweave <input.typ>     knit and compile\n",
      "  tweave --version       print version\n",
      "  tweave --help          show this help\n",
      sep = ""
    )
    return(invisible(cli_exit(if (length(args) == 0) 1 else 0)))
  }

  if (args[[1]] == "--version") {
    cat("tweave ", as.character(utils::packageVersion("tweave")), "\n", sep = "")
    return(invisible(cli_exit(0)))
  }

  tryCatch(
    {
      weave(args[[1]])
      invisible(cli_exit(0))
    },
    error = function(e) {
      message("Error: ", conditionMessage(e))
      invisible(cli_exit(1))
    }
  )
}

# quit() with a status code, unless we're in an interactive session
# (so calling main() from the R console doesn't kill it).
cli_exit <- function(status) {
  if (!interactive()) quit(save = "no", status = status)
  status
}
