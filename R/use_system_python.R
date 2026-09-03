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

# The Python a plain `pip install` would target. Rather than guessing
# file paths on PATH and checking file.exists() -- which doesn't work
# reliably against Windows's App Execution Alias stubs, since those
# aren't normal files, they're reparse-point stubs that only behave
# correctly when invoked by name through the OS's own command
# resolution -- this runs each candidate command *by name* (exactly
# like typing it in a terminal) and asks the running interpreter for
# its own canonical path via `sys.executable`. That's the genuine
# install location, never the alias stub itself, since the alias only
# affects how Python gets *started*, not what it reports once running.
find_system_python <- function() {
  candidates <- if (.Platform$OS.type == "windows") {
    list(c("py", "-3"), "python", "python3")
  } else {
    list("python3", "python")
  }

  for (cmd in candidates) {
    resolved <- run_python_probe(cmd)
    status <- attr(resolved, "status")
    if (!is.null(status) && status != 0) next
    if (length(resolved) != 1 || resolved == "") next
    if (python_is_usable(resolved)) return(resolved)
  }

  # Last-resort fallback: manually scan PATH, in case neither `python`,
  # `python3`, nor the `py` launcher are invokable by name but a real
  # interpreter is still findable as a file. Known to be unreliable for
  # Windows alias stubs specifically, but harmless to try.
  names <- if (.Platform$OS.type == "windows") {
    c("python", "python3")
  } else {
    c("python3", "python")
  }
  for (n in names) {
    scan_candidates <- python_path_candidates(n)
    is_alias_path <- vapply(scan_candidates, python_looks_like_store_alias,
                            logical(1))
    ordered <- c(scan_candidates[!is_alias_path], scan_candidates[is_alias_path])
    for (candidate in ordered) {
      if (python_is_usable(candidate)) return(candidate)
    }
  }

  ""
}

# Run `<cmd> <probe-script>` and return the output -- where the probe
# script is a small temp .py file, not an inline one-liner. Passing a
# one-liner containing semicolons and parentheses through nested shell
# quoting (R -> cmd.exe -> the target program) is one of the most
# fragile corners of Windows scripting; a file path is a much narrower,
# better-understood quoting problem (usually needing no quoting at all).
#
# On Windows, this goes through cmd.exe /c explicitly rather than
# spawning the process directly: a Windows App Execution Alias is a
# special reparse point (IO_REPARSE_TAG_APPEXECLINK) that the generic
# kernel I/O layer doesn't understand at all -- only launchers with
# specific support for it (cmd.exe, PowerShell, Explorer) can resolve
# and redirect through one. A generic process-spawn (what a direct
# system2() call amounts to) can fail on exactly the same alias that
# `cmd.exe /c python ...` handles correctly -- this mirrors a
# documented case of a different shell (4NT) getting a flat "No access
# to the file" error on an alias cmd.exe resolves fine.
run_python_probe <- function(cmd) {
  exe <- cmd[[1]]
  extra_args <- cmd[-1]

  script <- tempfile(fileext = ".py")
  on.exit(unlink(script), add = TRUE)
  writeLines("import sys; print(sys.executable)", script)

  args <- c(extra_args, shQuote(script))

  if (.Platform$OS.type == "windows") {
    wrapped <- windows_cmd_wrap(exe, args)
    exe <- wrapped$exe
    args <- wrapped$args
  }

  tryCatch(
    system2(exe, args, stdout = TRUE, stderr = TRUE),
    error = function(e) character(),
    warning = function(w) character()
  )
}

# Pure string-construction logic for routing a command through
# `cmd.exe /c`, factored out so it's testable on any platform (the
# actual invocation can only be verified on real Windows, but the
# command-line it constructs can be checked everywhere).
windows_cmd_wrap <- function(exe, args) {
  list(exe = "cmd", args = c("/c", paste(c(exe, args), collapse = " ")))
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
# (e.g. "...\MICROS~1\WINDOW~1\python.exe"). Used only to *deprioritize*
# a candidate (try it last) -- not to exclude it outright, since a real,
# working Python installed from the Microsoft Store also lives under
# this same directory. Only the actual --version behavior in
# python_is_usable() is authoritative.
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
