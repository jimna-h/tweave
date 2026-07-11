test_that("weave knits and compiles end to end", {
  skip_if(Sys.which("typst") == "", "Typst CLI not available")

  tmp <- withr::local_tempdir()
  fixture <- test_path("fixtures", "minimal.typ")
  input <- file.path(tmp, "minimal.typ")
  file.copy(fixture, input)

  pdf <- weave(input, quiet = TRUE)
  expect_true(file.exists(pdf))

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
  weave(input, quiet = TRUE)
  knitted <- readLines(file.path(tmp, "digits.knit.typ"))
  expect_true(any(grepl("Value: 3.14.", knitted, fixed = TRUE)))
})
