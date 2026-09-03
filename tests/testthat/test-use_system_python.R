test_that("find_system_python resolves via sys.executable, not file guessing", {
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  # This exercises the NEW primary mechanism directly: running the
  # candidate by name and asking it for its own path, rather than the
  # PATH-scanning fallback.
  found <- tweave:::find_system_python()
  expect_true(tweave:::python_is_usable(found))
})

test_that("the -c code argument survives shell quoting intact", {
  # Regression test for a real bug: passing "import sys; print(...)" as
  # a raw system2() argument let the shell split on the semicolon and
  # choke on the parentheses ("sh: Syntax error: word unexpected").
  # shQuote() must wrap the whole code string as one token.
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  out <- system2("python3", c("-c", shQuote("import sys; print(sys.executable)")),
                stdout = TRUE, stderr = TRUE)
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

test_that("python_looks_like_store_alias recognizes the Windows trap", {
  expect_true(tweave:::python_looks_like_store_alias(
    "C:\\Users\\sirja\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe"
  ))
  # Windows sometimes reports this as an abbreviated 8.3 short path
  expect_true(tweave:::python_looks_like_store_alias(
    "C:\\Users\\sirja\\AppData\\Local\\MICROS~1\\WINDOW~1\\python.exe"
  ))
  expect_false(tweave:::python_looks_like_store_alias(
    "C:\\Python312\\python.exe"
  ))
  expect_false(tweave:::python_looks_like_store_alias("/usr/bin/python3"))
})

test_that("python_is_usable rejects a non-functional file and accepts a real interpreter", {
  fake <- withr::local_tempfile()
  file.create(fake)  # exists, but isn't executable Python
  expect_false(tweave:::python_is_usable(fake))

  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  expect_true(tweave:::python_is_usable(Sys.which("python3")))
})

test_that("python_path_candidates finds all PATH matches, not just the first", {
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  found <- tweave:::python_path_candidates("python3")
  expect_true(length(found) >= 1)
  expect_true(any(file.exists(found)))
})

test_that("find_system_python still accepts a real interpreter even under a WindowsApps-style path", {
  # A legitimate, working Python installed from the Microsoft Store
  # lives under the same directory as the broken alias stub -- path
  # alone can't tell them apart, only behavior can. Simulate: a broken
  # alias-like path (fails --version) and a working one (passes),
  # both under directories containing "WindowsApps", to confirm the
  # working one still gets found despite looking suspicious by path.
  broken_dir <- withr::local_tempdir()
  windowsapps_like <- file.path(broken_dir, "WindowsApps")
  dir.create(windowsapps_like)
  writeLines(c("#!/bin/sh",
    'echo "Python was not found; run without arguments to install..."',
    "exit 0"), file.path(windowsapps_like, "python3"))
  Sys.chmod(file.path(windowsapps_like, "python3"), "0755")

  working_dir <- withr::local_tempdir()
  working_windowsapps_like <- file.path(working_dir, "WindowsApps")
  dir.create(working_windowsapps_like)
  writeLines(c("#!/bin/sh", 'echo "Python 3.11.9"', "exit 0"),
             file.path(working_windowsapps_like, "python3"))
  Sys.chmod(file.path(working_windowsapps_like, "python3"), "0755")

  withr::local_envvar(PATH = paste(windowsapps_like, working_windowsapps_like,
                                   sep = .Platform$path.sep))

  found <- tweave:::find_system_python()
  expect_equal(found, file.path(working_windowsapps_like, "python3"))
})

test_that("find_system_python skips a fake alias planted ahead of a real interpreter", {
  skip_if(Sys.which("python3") == "", "no system python3 in this environment")
  real_dir <- dirname(Sys.which("python3"))

  # Simulate the Windows situation: a non-functional "python3" earlier
  # on PATH than the real one.
  fake_dir <- withr::local_tempdir()
  file.create(file.path(fake_dir, "python3"))
  Sys.chmod(file.path(fake_dir, "python3"), "0755")

  withr::local_envvar(PATH = paste(fake_dir, Sys.getenv("PATH"), sep = .Platform$path.sep))

  found <- tweave:::find_system_python()
  expect_true(tweave:::python_is_usable(found))
  expect_false(identical(dirname(found), fake_dir))
})
