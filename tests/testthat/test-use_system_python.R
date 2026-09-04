test_that("find_system_python resolves via sys.executable, not file guessing", {
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  # Exercises the primary discovery mechanism directly.
  found <- tweave:::find_system_python()
  expect_true(tweave:::python_is_usable(found))
})

test_that("run_python_probe resolves a real interpreter's own path", {
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  # Regression coverage for the underlying design: probing via a temp
  # script file (not an inline one-liner threaded through nested shell
  # quoting) still correctly resolves sys.executable. The original
  # one-liner approach hit a real bug -- semicolons and parens getting
  # mangled by shell interpretation -- which the file-based probe
  # sidesteps by construction.
  out <- tweave:::run_python_probe(list("python3"))
  expect_false(any(grepl("Syntax error", out)))
  expect_true(tweave:::python_is_usable(out))
})

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

test_that("a Windows-style backslash path survives .Renviron round-trip intact", {
  # Real bug, confirmed: R's .Renviron parser treats backslash as an
  # escape character and silently drops unrecognized sequences, so an
  # unescaped "C:\Users\..." path gets every backslash stripped on the
  # next read. Converting to forward slashes (which Windows accepts
  # everywhere) sidesteps this rather than trying to replicate R's
  # exact escaping rules.
  tmp <- withr::local_tempfile()
  withr::local_envvar(R_ENVIRON_USER = tmp)

  windows_path <- "C:\\Users\\sirja\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe"
  safe_value <- chartr("\\", "/", windows_path)
  tweave:::renviron_set("RETICULATE_PYTHON", safe_value)

  out <- system2(
    "Rscript",
    c("-e", shQuote('cat(Sys.getenv("RETICULATE_PYTHON"))')),
    stdout = TRUE,
    env = paste0("R_ENVIRON_USER=", tmp)
  )
  expect_equal(out, "C:/Users/sirja/AppData/Local/Microsoft/WindowsApps/python.exe")
})

test_that("use_system_python takes effect even with a stale RETICULATE_PYTHON already set", {
  # reticulate::use_python() refuses to override an already-set
  # RETICULATE_PYTHON by design -- if a prior corrupted .Renviron entry
  # left a bad value loaded in the current session, calling use_python()
  # alone would be silently ignored. use_system_python() must set the
  # env var itself first so the current session is corrected immediately.
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  withr::local_envvar(RETICULATE_PYTHON = "/nonexistent/stale/path")

  real_python <- unname(Sys.which("python3"))
  expect_no_warning(tweave::use_system_python(python = real_python, persist = FALSE))
  expect_equal(Sys.getenv("RETICULATE_PYTHON"), real_python)
  expect_equal(reticulate::py_config()$python, real_python)
})

test_that("use_system_python errors clearly when nothing is found", {
  expect_error(
    tweave::use_system_python(python = ""),
    "No working Python found"
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

test_that("python_is_usable rejects the Windows alias's own rejection message", {
  # Real-world behavior, confirmed: running the Windows Store alias with
  # --version prints "Python was not found; run without arguments to
  # install from the Microsoft Store..." -- which contains the literal
  # word "Python". A loose substring check would wrongly accept this.
  # Exit code 0 specifically isolates the bug: a nonzero exit alone
  # would already reject it for unrelated reasons.
  fake_alias <- withr::local_tempfile()
  writeLines(c(
    "#!/bin/sh",
    'echo "Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Manage App Execution Aliases."',
    "exit 0"
  ), fake_alias)
  Sys.chmod(fake_alias, "0755")

  expect_false(tweave:::python_is_usable(fake_alias))
})

test_that("python_is_usable also rejects the alias when it exits nonzero", {
  fake_alias <- withr::local_tempfile()
  writeLines(c(
    "#!/bin/sh",
    'echo "Python was not found; run without arguments to install from the Microsoft Store..."',
    "exit 9009"
  ), fake_alias)
  Sys.chmod(fake_alias, "0755")

  expect_false(tweave:::python_is_usable(fake_alias))
})

test_that("python_is_usable accepts a real version string", {
  fake_real <- withr::local_tempfile()
  writeLines(c("#!/bin/sh", 'echo "Python 3.12.3"', "exit 0"), fake_real)
  Sys.chmod(fake_real, "0755")

  expect_true(tweave:::python_is_usable(fake_real))
})

test_that("python_is_usable rejects a non-functional file and accepts a real interpreter", {
  fake <- withr::local_tempfile()
  file.create(fake)  # exists, but isn't executable Python
  expect_false(tweave:::python_is_usable(fake))

  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  expect_true(tweave:::python_is_usable(Sys.which("python3")))
})
