test_that("typst_escape handles quotes and backslashes in the right order", {
  expect_equal(tweave:::typst_escape('say "hi"'), 'say \\"hi\\"')
  expect_equal(tweave:::typst_escape("a\\b"), "a\\\\b")
  # backslash-then-quote must not double-escape the quote's new backslash
  expect_equal(tweave:::typst_escape('\\"'), '\\\\\\"')
  expect_equal(tweave:::typst_escape("plain"), "plain")
})

test_that("format_inline rounds and renders scientific notation", {
  expect_equal(tweave:::format_inline(3.14159, digits = 2), "3.14")
  expect_equal(tweave:::format_inline(1.2e10), "1.2 times 10^(10)")
  expect_equal(tweave:::format_inline(1.2e-05), "1.2 times 10^(-05)")
  expect_equal(tweave:::format_inline("text"), "text")
})

test_that("source hook respects echo/include", {
  h <- tweave:::tweave_hooks()
  expect_equal(h$source("x <- 1", list(echo = FALSE)), "")
  expect_equal(h$output("out", list(results = "hide")), "")
  expect_match(h$source("x <- 1", list()), 'raw\\("x <- 1", lang: "r"\\)')
})
