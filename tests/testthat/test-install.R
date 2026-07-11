test_that("uninstall reverses install", {
  # point both install locations into a sandbox
  tmp <- withr::local_tempdir()
  bin <- file.path(tmp, "bin")
  withr::local_envvar(XDG_DATA_HOME = tmp)  # redirects typst dir on Linux
  skip_if(.Platform$OS.type == "windows")   # env redirect is XDG-based

  tweave::install(bin_dir = bin)
  expect_true(file.exists(file.path(bin, "tweave")))
  expect_true(dir.exists(file.path(tmp, "typst", "packages", "local", "tweave")))

  tweave::uninstall(bin_dir = bin)
  expect_false(file.exists(file.path(bin, "tweave")))
  expect_false(dir.exists(file.path(tmp, "typst", "packages", "local", "tweave")))
})
