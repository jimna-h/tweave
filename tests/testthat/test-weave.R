test_that("weave knits and compiles end to end", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")

  tmp <- withr::local_tempdir()
  fixture <- test_path("fixtures", "minimal.typ")
  input <- file.path(tmp, "minimal.typ")
  file.copy(fixture, input)

  pdf <- weave(input, quiet = TRUE, keep = TRUE)
  expect_true(file.exists(pdf))
  expect_equal(basename(pdf), "minimal.pdf")

  knitted <- readLines(file.path(tmp, "minimal.knit.typ"))
  expect_true(any(grepl("The mean is 2", knitted)))
})

test_that("weave fails clearly on a missing file", {
  expect_error(weave("no-such-file.typ"), "not found")
})

test_that("weave refuses an empty input file", {
  empty <- withr::local_tempfile(fileext = ".typ")
  file.create(empty)
  expect_error(weave(empty), "empty")
})

test_that("digits set in a chunk controls inline rounding", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  tmp <- withr::local_tempdir()
  input <- file.path(tmp, "digits.typ")
  writeLines(c(
    "```{r}", "digits <- 2", "x <- 3.14159", "```",
    "Value: `r x`."
  ), input)
  weave(input, quiet = TRUE, keep = TRUE)
  knitted <- readLines(file.path(tmp, "digits.knit.typ"))
  expect_true(any(grepl("Value: 3.14.", knitted, fixed = TRUE)))
})

test_that("weave handles paths containing spaces", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  tmp <- withr::local_tempdir()
  spacey <- file.path(tmp, "My Drive", "STAT 251")
  dir.create(spacey, recursive = TRUE)
  input <- file.path(spacey, "hw.typ")
  file.copy(test_path("fixtures", "minimal.typ"), input)
  pdf <- weave(input, quiet = TRUE)
  expect_true(file.exists(pdf))
})

test_that("intermediate is removed on success by default", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  tmp <- withr::local_tempdir()
  input <- file.path(tmp, "clean.typ")
  file.copy(test_path("fixtures", "minimal.typ"), input)
  weave(input, quiet = TRUE)
  expect_true(file.exists(file.path(tmp, "clean.pdf")))
  expect_false(file.exists(file.path(tmp, "clean.knit.typ")))
})

test_that("intermediate is kept when typst compilation fails", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")
  tmp <- withr::local_tempdir()
  input <- file.path(tmp, "broken.typ")
  writeLines(c("#import \"@local/does-not-exist:9.9.9\": *", "hello"), input)
  expect_error(weave(input, quiet = TRUE), "kept for debugging")
  expect_true(file.exists(file.path(tmp, "broken.knit.typ")))
})
