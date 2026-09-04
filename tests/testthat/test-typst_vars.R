# Helper: TRUE if `typst compile` on this file exits 0.
compiles_cleanly <- function(path) {
  out <- tempfile(fileext = ".pdf")
  status <- system2("typst", c("compile", shQuote(path), shQuote(out)),
                    stdout = FALSE, stderr = FALSE)
  status == 0
}

test_that("typst_literal formats each R type correctly", {
  expect_equal(tweave:::typst_literal(0.93531987, 4), "0.9353")
  expect_equal(tweave:::typst_literal(3L, 4), "3")
  expect_equal(tweave:::typst_literal(TRUE, 4), "true")
  expect_equal(tweave:::typst_literal(FALSE, 4), "false")
  expect_equal(tweave:::typst_literal("hi", 4), '"hi"')
  # small-but-nonzero values fall back to signif, same as format_inline();
  # Typst's numeric literals accept e-notation directly, no rewrite needed
  expect_equal(tweave:::typst_literal(0.000012345, 4), "1.234e-05")
})

test_that("typst_literal escapes quotes and backslashes in strings", {
  expect_equal(tweave:::typst_literal('say "hi"', 4), '"say \\"hi\\""')
})

test_that("typst_vars emits a valid #let dict statement", {
  out <- tweave::typst_vars(list(r2 = 0.93531987, label = "fit"), digits = 4)
  expect_equal(out, '#let vals = (r2: 0.9353, label: "fit")\n')
})

test_that("typst_vars respects a custom dict name", {
  out <- tweave::typst_vars(list(x = 1), name = "stats")
  expect_match(out, "^#let stats = ")
})

test_that("typst_vars rejects unnamed or empty input", {
  expect_error(tweave::typst_vars(list(1, 2)), "fully named")
  expect_error(tweave::typst_vars(list(a = 1, 2)), "fully named")
  expect_error(tweave::typst_vars(list()), "fully named")
})

test_that("scientific-notation dict values are valid, correct Typst numbers", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  tmp <- withr::local_tempfile(fileext = ".typ")
  writeLines(c(
    tweave::typst_vars(list(tiny = 0.000012345)),
    '#(vals.at("tiny", default: 0) * 1000000)'  # should evaluate to ~12.34
  ), tmp)
  expect_true(compiles_cleanly(tmp))
})

test_that("typst_vars output is valid Typst, pre- and post-knit shaped", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  tmp <- withr::local_tempfile(fileext = ".typ")

  # "pre-knit": empty placeholder dict, values referenced with a default
  writeLines(c(
    '#let vals = (:)',
    '$ sqrt(vals.at("r2", default: 0) / 2) + x^(vals.at("slope", default: 1)) $'
  ), tmp)
  expect_true(compiles_cleanly(tmp))

  # "post-knit": what typst_vars() actually emits, in place of the chunk
  writeLines(c(
    tweave::typst_vars(list(r2 = 0.9353, slope = 5.0659)),
    '$ sqrt(vals.at("r2", default: 0) / 2) + x^(vals.at("slope", default: 1)) $'
  ), tmp)
  expect_true(compiles_cleanly(tmp))
})

test_that("the bundled package's val()/vals work with no per-document setup", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  pkg_dir <- system.file("typst", "tweave", package = "tweave")
  skip_if(pkg_dir == "", "tweave Typst package not found in installed R package")

  local_pkgs <- withr::local_tempdir()
  dest <- file.path(local_pkgs, "typst", "packages", "local", "tweave")
  dir.create(dest, recursive = TRUE)
  file.copy(list.files(pkg_dir, full.names = TRUE), dest, recursive = TRUE)
  withr::local_envvar(XDG_DATA_HOME = local_pkgs)

  tmp <- withr::local_tempfile(fileext = ".typ")

  # No #let vals = (:) anywhere -- importing the package alone must be
  # enough for val("anything") to be valid, pre-knit.
  writeLines(c(
    '#import "@local/tweave:0.1.0": val',
    '$ sqrt(val("mse") / val("sxx")) $'
  ), tmp)
  expect_true(compiles_cleanly(tmp))

  # A results='asis'-style #let vals = (...) later in the same document
  # shadows the package's empty one for everything after it.
  writeLines(c(
    '#import "@local/tweave:0.1.0": val',
    '#let vals = (mse: 18.08, sxx: 295.44)',
    '$ sqrt(val("mse") / val("sxx")) $'
  ), tmp)
  expect_true(compiles_cleanly(tmp))
})
