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
      "No Python found on your PATH. Install Python from ",
      "https://python.org (on Windows, check \"Add python.exe to PATH\" ",
      "during install) and try again.",
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

# The Python a plain `pip install` would target: whatever's first on
# PATH, checking the platform-conventional name first.
find_system_python <- function() {
  names <- if (.Platform$OS.type == "windows") {
    c("python", "python3")
  } else {
    c("python3", "python")
  }
  for (n in names) {
    p <- Sys.which(n)
    if (p != "") return(unname(p))
  }
  ""
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
