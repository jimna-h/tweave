# Using your existing Python, instead of reticulate's managed venv -----
#
# By default, reticulate creates and prefers its own isolated virtual
# environment ("r-reticulate"), completely separate from whatever Python
# you've been `pip install`-ing packages into directly. That's a sensible
# default for reproducibility, but it means packages you already have
# installed are invisible to tweave until you tell reticulate to look
# somewhere else.

#' Point reticulate at your existing system Python
#'
#' By default, reticulate creates and uses its own isolated virtual
#' environment, separate from whatever Python you've been installing
#' packages into directly with `pip install`. If you already have Python
#' set up the way you want it, this points reticulate at that Python
#' instead -- for the current session, and (by default) permanently, so
#' every future `tweave` build picks it up automatically without you
#' repeating this.
#'
#' @param python Path to the Python interpreter to use. Defaults to
#'   whatever `python` (Windows) or `python3` (macOS/Linux) resolves to
#'   on your PATH -- the same interpreter a plain `pip install` targets.
#' @param persist Save this choice so future R sessions -- and future
#'   `tweave` builds, which each start a fresh session -- use it
#'   automatically, by writing `RETICULATE_PYTHON` to your `.Renviron`.
#'   Default `TRUE`. Set `FALSE` to change it for this session only.
#' @return (Invisibly) the path to the Python interpreter that was set.
#' @export
use_system_python <- function(python = NULL, persist = TRUE) {
  if (is.null(python)) python <- find_system_python()
  if (python == "") {
    stop(
      "No working Python found on your PATH.\n",
      "  If you're on Windows and know you've installed Python, this can ",
      "happen when a Microsoft Store \"App Execution Alias\" stub shadows ",
      "your real install. Try: Settings > Apps > Advanced app settings > ",
      "App execution aliases, and turn OFF the entries for python.exe and ",
      "python3.exe. Then try again.\n",
      "  Otherwise, install Python from https://python.org (on Windows, ",
      "check \"Add python.exe to PATH\" during install) and try again.",
      call. = FALSE
    )
  }

  reticulate::use_python(python, required = TRUE)
  message("Using Python: ", python)

  if (persist) {
    path <- renviron_set("RETICULATE_PYTHON", python)
    message(
      "Saved to ", path, " -- future R sessions, including future ",
      "tweave builds, will use this Python automatically. Restart R (or ",
      "open a new terminal) for anything already running to pick it up."
    )
  }

  invisible(python)
}

# The Python a plain `pip install` would target. Unlike a naive
# Sys.which(), this skips Windows's fake "App Execution Alias" stub
# (a placeholder python.exe that Windows puts on PATH by default, even
# with no Python installed via the Store -- it exists but isn't a real
# interpreter) and verifies each candidate actually runs before
# accepting it.
find_system_python <- function() {
  # On Windows, the official Python Launcher (py.exe) is more reliable
  # than searching PATH by name: it's designed specifically to locate a
  # real, working Python installation and isn't itself alias-shadowed.
  if (.Platform$OS.type == "windows") {
    py_launcher <- tryCatch(
      system2("py", c("-3", "-c", "import sys; print(sys.executable)"),
              stdout = TRUE, stderr = TRUE),
      error = function(e) character()
    )
    if (length(py_launcher) == 1 && python_is_usable(py_launcher)) {
      return(py_launcher)
    }
  }

  names <- if (.Platform$OS.type == "windows") {
    c("python", "python3")
  } else {
    c("python3", "python")
  }

  for (n in names) {
    for (candidate in python_path_candidates(n)) {
      if (!python_looks_like_store_alias(candidate) &&
          python_is_usable(candidate)) {
        return(candidate)
      }
    }
  }

  ""
}

# All PATH entries matching an executable name, in PATH order -- unlike
# Sys.which(), which only ever returns the first match. Needed because
# the first "python" on PATH is often the Windows Store alias stub, and
# we need to be able to look past it to a real install further along.
python_path_candidates <- function(name) {
  exe <- if (.Platform$OS.type == "windows") paste0(name, ".exe") else name
  dirs <- strsplit(Sys.getenv("PATH"), .Platform$path.sep, fixed = TRUE)[[1]]
  candidates <- file.path(dirs, exe)
  candidates[file.exists(candidates)]
}

# Windows's App Execution Alias stubs live under a well-known path,
# whether Windows reports it in full or as an abbreviated 8.3 short path
# (e.g. "...\MICROS~1\WINDOW~1\python.exe").
python_looks_like_store_alias <- function(path) {
  grepl("WindowsApps", path, ignore.case = TRUE) ||
    grepl("MICROS~.\\\\WINDOW~", path, ignore.case = TRUE)
}

# TRUE if `path --version` actually runs and prints a real version
# number. Deliberately strict: Windows's App Execution Alias stub, when
# run with --version, prints "Python was not found; run without
# arguments to install from the Microsoft Store..." -- which contains
# the literal word "Python", so a loose substring check is fooled by
# the alias's own rejection message. Requiring digits right after
# "Python" rules that out.
python_is_usable <- function(path) {
  out <- tryCatch(
    system2(path, "--version", stdout = TRUE, stderr = TRUE),
    error = function(e) character(),
    warning = function(w) character()
  )
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) return(FALSE)
  length(out) > 0 && any(grepl("^Python \\d+\\.\\d", out, ignore.case = TRUE))
}

# -- .Renviron helpers -----------------------------------------------

renviron_path <- function() {
  path <- Sys.getenv("R_ENVIRON_USER", unset = "")
  if (nzchar(path)) return(path)
  file.path(path.expand("~"), ".Renviron")
}

# Set (or update in place) a KEY=value line in the user's .Renviron,
# without disturbing anything else already there.
renviron_set <- function(key, value) {
  path <- renviron_path()
  lines <- if (file.exists(path)) readLines(path, warn = FALSE) else character()

  line <- paste0(key, "=", value)
  hit <- grep(paste0("^", key, "\\s*="), lines)

  if (length(hit) > 0) {
    lines[hit[1]] <- line
    if (length(hit) > 1) lines <- lines[-hit[-1]]  # drop any duplicates
  } else {
    lines <- c(lines, line)
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
  invisible(path)
}
