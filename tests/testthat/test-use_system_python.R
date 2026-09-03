test_that("find_system_python finds something real on this machine", {
  skip_if(Sys.which("python3") == "" && Sys.which("python") == "",
          "no python on PATH in this environment")
  found <- tweave:::find_system_python()
  expect_true(file.exists(found))
})

test_that("renviron_set writes a new key without disturbing other lines", {
  tmp <- withr::local_tempfile()
  writeLines(c("SOME_OTHER_VAR=hello", "ANOTHER=world"), tmp)
  withr::local_envvar(R_ENVIRON_USER = tmp)

  tweave:::renviron_set("RETICULATE_PYTHON", "/usr/bin/python3")
  lines <- readLines(tmp)

  expect_true("RETICULATE_PYTHON=/usr/bin/python3" %in% lines)
  expect_true("SOME_OTHER_VAR=hello" %in% lines)
  expect_true("ANOTHER=world" %in% lines)
})

test_that("renviron_set updates an existing key in place, not appends", {
  tmp <- withr::local_tempfile()
  writeLines(c("RETICULATE_PYTHON=/old/path", "OTHER=kept"), tmp)
  withr::local_envvar(R_ENVIRON_USER = tmp)

  tweave:::renviron_set("RETICULATE_PYTHON", "/new/path")
  lines <- readLines(tmp)

  expect_equal(sum(grepl("^RETICULATE_PYTHON=", lines)), 1)
  expect_true("RETICULATE_PYTHON=/new/path" %in% lines)
  expect_true("OTHER=kept" %in% lines)
})

test_that("renviron_set creates .Renviron if it doesn't exist yet", {
  tmp_dir <- withr::local_tempdir()
  tmp <- file.path(tmp_dir, ".Renviron")
  withr::local_envvar(R_ENVIRON_USER = tmp)

  expect_false(file.exists(tmp))
  tweave:::renviron_set("RETICULATE_PYTHON", "/usr/bin/python3")
  expect_true(file.exists(tmp))
  expect_true("RETICULATE_PYTHON=/usr/bin/python3" %in% readLines(tmp))
})

test_that("use_system_python errors clearly when nothing is found", {
  expect_error(
    tweave::use_system_python(python = ""),
    "No Python found"
  )
})

test_that("a persisted RETICULATE_PYTHON is honored by a fresh R process", {
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  tmp <- withr::local_tempfile()
  withr::local_envvar(R_ENVIRON_USER = tmp)

  py <- Sys.which("python3")
  tweave::use_system_python(python = py, persist = TRUE)

  # Simulate what a future `tweave` build's fresh Rscript process sees:
  # read .Renviron's RETICULATE_PYTHON exactly as R itself would at startup.
  renviron_lines <- readLines(tmp)
  expect_true(any(grepl(paste0("^RETICULATE_PYTHON=", py), renviron_lines)))

  out <- system2(
    "Rscript",
    c("-e", shQuote(sprintf(
      'Sys.setenv(RETICULATE_PYTHON = "%s"); cat(reticulate::py_config()$python)',
      py
    ))),
    stdout = TRUE, stderr = TRUE
  )
  expect_true(any(grepl(py, out, fixed = TRUE)))
})
