library(knitr)
knitr::opts_chunk$set(
  message = FALSE,
  warning = FALSE,
  comment = NA
)

# Escape a string so it survives inside Typst's raw("...")
# Backslashes must be escaped before quotes.
typst_escape <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  gsub('"', '\\"', x, fixed = TRUE)
}

# hook for the code source
knit_hooks$set(source = function(x, options) {
  if (isFALSE(options$include) || isFALSE(options$echo)) return("")

  full_code <- paste(x, collapse = "\n")

  sprintf('#block(
    fill: luma(240),
    inset: 8pt,
    radius: 4pt,
    width: 100%%,
    raw("%s", lang: "r")
  )', typst_escape(full_code))
})

# hook for the console output
knit_hooks$set(output = function(x, options) {
  if (isFALSE(options$include) || options$results == "hide" || trimws(x) == "") {
    return("")
  }

  sprintf('#block(
    stroke: 0.5pt + luma(200),
    inset: 8pt,
    radius: 4pt,
    width: 100%%,
    raw("%s")
  )', typst_escape(x))
})

# hook for plots
knit_hooks$set(plot = function(x, options) {
  if (isFALSE(options$include)) return("")

  sprintf('#align(center, image("%s", width: 80%%))', x)
})

# hook for in-text variables (`r expr`)
knit_hooks$set(inline = function(x) {
  if (is.numeric(x)) {
    # Set `digits` in the global environment to control rounding (default 4)
    d <- if (exists("digits", envir = .GlobalEnv)) get("digits", envir = .GlobalEnv) else 4
    x <- round(x, d)
  }

  res <- as.character(x)

  # Render scientific notation as Typst math (e.g. 1.2e+03 -> 1.2 times 10^(3))
  gsub("e\\+?(-?\\d+)", " times 10^(\\1)", res)
})
