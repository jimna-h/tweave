# knitr -> Typst output hooks -------------------------------------------

# Escape a string so it survives inside Typst's raw("...").
# Backslashes must be escaped before quotes.
typst_escape <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  gsub('"', '\\"', x, fixed = TRUE)
}

# Format a single inline `r expr` value for Typst.
# Numerics are rounded to `digits`; scientific notation is rendered
# as Typst math (1.2e+03 -> 1.2 times 10^(3)).
format_inline <- function(x, digits = 4) {
  if (is.numeric(x)) {
    r <- round(x, digits)
    # Don't let rounding flatten small-but-nonzero values (e.g. p-values)
    # to 0; fall back to significant digits for those.
    x <- ifelse(x != 0 & r == 0, signif(x, digits), r)
  }
  res <- as.character(x)
  gsub("e\\+?(-?\\d+)", " times 10^(\\1)", res)
}

# The hook functions, as a named list ready for knitr::knit_hooks$set().
tweave_hooks <- function() {
  list(
    source = function(x, options) {
      if (isFALSE(options$include) || isFALSE(options$echo)) return("")
      sprintf(
        '#block(
  fill: luma(240),
  inset: 8pt,
  radius: 4pt,
  width: 100%%,
  raw("%s", lang: "r")
)',
        typst_escape(paste(x, collapse = "\n"))
      )
    },

    output = function(x, options) {
      if (isFALSE(options$include) || identical(options$results, "hide") ||
          trimws(x) == "") {
        return("")
      }
      sprintf(
        '#block(
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  radius: 4pt,
  width: 100%%,
  raw("%s")
)',
        typst_escape(x)
      )
    },

    plot = function(x, options) {
      if (isFALSE(options$include)) return("")
      sprintf('#align(center, image("%s", width: 80%%))', x)
    },

    inline = function(x) {
      # Users may set `digits` in any chunk to change rounding
      env <- knitr::knit_global()
      d <- if (exists("digits", envir = env)) get("digits", envir = env) else 4
      format_inline(x, digits = d)
    }
  )
}

# Default chunk options for weaving.
tweave_chunk_opts <- function(fig_path) {
  list(
    dev = "png",
    fig.path = fig_path,
    fig.show = "asis",
    comment = "",
    message = FALSE,
    warning = FALSE
  )
}
