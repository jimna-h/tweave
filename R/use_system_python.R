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
#' Looks for a normal, traditionally-installed Python (python.org,
#' winget, conda). Deliberately does not try to detect or work around
#' Microsoft Store-packaged Python: it's locked down by Windows' own
#' AppX security model in ways that can fail unpredictably depending on
#' how deeply nested the calling process is, and no amount of scripting
#' from R can reliably fix that. If that's the only Python this finds,
#' install a normal one from <https://python.org> instead.
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
      "  Install Python from https://python.org (on Windows, check ",
      "\"Add python.exe to PATH\" during install) and try again.\n",
      "  Avoid the Microsoft Store version if you have a choice -- it's ",
      "known to cause hard-to-diagnose failures with R/reticulate.",
      call. = FALSE
    )
  }

  # Set directly for the current session first: reticulate::use_python()
  # refuses to override an already-set RETICULATE_PYTHON (by design), so
  # if a stale value is already loaded -- e.g. from an earlier corrupted
  # .Renviron entry -- calling use_python() alone would be silently
  # ignored. Setting the env var ourselves makes this session correct
  # immediately, not just future ones.
  Sys.setenv(RETICULATE_PYTHON = python)
  reticulate::use_python(python, required = TRUE)
  message("Using Python: ", python)

  if (persist) {
    # R's .Renviron parser treats backslash as an escape character and
    # silently drops unrecognized escape sequences -- an unescaped
    # Windows path (C:\Users\...) written as-is gets corrupted on the
    # next read (verified: every backslash vanishes). Forward slashes
    # are accepted everywhere Windows accepts paths, so convert just
    # for the persisted value; the path used right now, above, and
    # everywhere else in this function stays exactly as found.
    renviron_path_value <- chartr("\\", "/", python)
    path <- renviron_set("RETICULATE_PYTHON", renviron_path_value)
    message(
      "Saved to ", path, " -- future R sessions, including future ",
      "tweave builds, will use this Python automatically. Restart R (or ",
      "open a new terminal) for anything already running to pick it up."
    )
  }

  invisible(python)
}

# The Python a plain `pip install` would target: whatever `python` (or
# `python3`) resolves to on PATH, or -- on Windows, tried first -- the
# official Python Launcher (py.exe), which is the standard way to find
# "the" Python on a machine with several installed. py.exe is itself a
# dispatcher rather than an interpreter, so it's asked for the real
# interpreter path via sys.executable; a plain Sys.which() result is
# used as-is for "python"/"python3", since that's already a real path.
find_system_python <- function() {
  if (.Platform$OS.type == "windows" && Sys.which("py") != "") {
    resolved <- run_python_probe(c("py", "-3"))
    status <- attr(resolved, "status")
    ok <- (is.null(status) || status == 0) && length(resolved) == 1 &&
      resolved != ""
    if (ok && python_is_usable(resolved)) return(resolved)
  }

  names <- if (.Platform$OS.type == "windows") {
    c("python", "python3")
  } else {
    c("python3", "python")
  }
  for (n in names) {
    p <- unname(Sys.which(n))
    if (p != "" && python_is_usable(p)) return(p)
  }

  ""
}

# Run `<cmd> <probe-script>` and return the output -- where the probe
# script is a small temp .py file rather than an inline one-liner, since
# passing code containing semicolons and parentheses through shell
# quoting is a needless source of fragility a plain file path avoids.
# Only used for the `py` launcher, which needs to be asked what real
# interpreter it points to.
run_python_probe <- function(cmd) {
  exe <- cmd[[1]]
  extra_args <- cmd[-1]

  script <- tempfile(fileext = ".py")
  on.exit(unlink(script), add = TRUE)
  writeLines("import sys; print(sys.executable)", script)

  args <- c(extra_args, shQuote(script))
  tryCatch(
    system2(exe, args, stdout = TRUE, stderr = TRUE),
    error = function(e) character(),
    warning = function(w) character()
  )
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
