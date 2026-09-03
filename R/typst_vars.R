# Values inside complex math expressions --------------------------------
#
# A knit-time value can never sit *inside* a live Typst math zone via the
# usual `` `r expr` `` substitution -- Typst's math grammar always tries
# to resolve a bare multi-letter run as a variable/function name, with no
# raw-text escape hatch (see the README for the full explanation). That's
# fine for a value at the edge of an expression (`$R^2 =$ `r r2``), but a
# value genuinely inside a fraction, exponent, or square root has no such
# edge to sit at.
#
# The fix: expose a whole dictionary of values as real, static Typst
# source (`#let vals = (...)`), then reference entries with
# `vals.at("key", default: ...)` -- valid Typst syntax at *any* position
# in a math expression, and safe pre-knit because `default:` supplies a
# placeholder when the dict doesn't have the key yet (e.g. before this
# chunk has run, or in an empty `#let vals = (:)` placeholder above it).

#' Emit a Typst dictionary literal from named R values
#'
#' Formats `values` as a `#let <name> = (...)` Typst statement, for the
#' "dictionary + `.at(default:)`" pattern that lets knit-time values
#' appear *inside* complex math expressions (fractions, exponents,
#' square roots, ...) without breaking a live Typst preview. Call this
#' from a chunk with `results='asis'`, wrapped in `cat()`:
#'
#' ```
#' ```{r, results='asis', echo=FALSE}
#' cat(tweave::typst_vars(list(r2 = r2, slope = slope)))
#' ```
#' ```
#'
#' Then, anywhere in the document (including inside math), reference
#' entries with `vals.at("r2", default: 0)`. Put a `#let vals = (:)`
#' placeholder above the first use so the pre-knit source (and hence a
#' live Typst preview) always has *something* to resolve `vals` to.
#'
#' @param values A fully named list of R values to expose to Typst.
#'   Numeric values are rounded to `digits` (with the same small-value
#'   fallback as inline `` `r expr` `` substitution); character values
#'   are quoted and escaped; logicals become Typst `true`/`false`.
#' @param name The Typst variable name for the dictionary. Defaults to
#'   `"vals"`; use something else if you need more than one dictionary
#'   in the same document.
#' @param digits Rounding for numeric values, matching tweave's usual
#'   inline-rounding default.
#' @return The generated Typst source, as a single string ending in a
#'   newline. Wrap the call in `cat()` inside a `results='asis'` chunk;
#'   the return value is not auto-print-safe (R's default print method
#'   would add quotes and an index prefix, corrupting the output).
#' @export
typst_vars <- function(values, name = "vals", digits = 4) {
  if (length(values) == 0 || is.null(names(values)) ||
      any(names(values) == "")) {
    stop("`values` must be a fully named, non-empty list, e.g. ",
         'list(r2 = r2, slope = slope).', call. = FALSE)
  }
  entries <- vapply(names(values), function(key) {
    sprintf("%s: %s", key, typst_literal(values[[key]], digits))
  }, character(1))
  sprintf("#let %s = (%s)\n", name, paste(entries, collapse = ", "))
}

# Format a single R value as a Typst literal (for use inside a dict).
typst_literal <- function(x, digits) {
  if (is.logical(x)) return(if (isTRUE(x)) "true" else "false")
  if (is.numeric(x)) {
    # Typst's numeric literals accept both decimal and scientific (e-05,
    # e+05) notation, so just let R pick whichever is natural -- unlike
    # format_inline()'s prose output, this never needs the "times 10^()"
    # math-notation rewrite, since this string is parsed as a real Typst
    # number (and may be used in further arithmetic), not displayed text.
    return(format(round_for_display(x, digits), trim = TRUE))
  }
  sprintf('"%s"', typst_escape(as.character(x)))
}
