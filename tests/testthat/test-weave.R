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
