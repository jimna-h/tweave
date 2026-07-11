# One-command setup: Typst package + CLI shim ---------------------------

#' Set up tweave after installing the R package
#'
#' Does two things:
#' 1. Copies the bundled Typst package into your local Typst packages
#'    directory, so documents can `#import "@local/tweave:0.1.0"`.
#' 2. Puts the `tweave` command on your PATH (or tells you exactly how).
#'
#' Safe to re-run at any time, e.g. after updating the package.
#'
#' @param bin_dir Where to place the CLI shim. Defaults to `~/.local/bin`
#'   on macOS/Linux and `\%LOCALAPPDATA\%\\tweave\\bin` on Windows.
#' @export
install <- function(bin_dir = NULL) {
  install_typst_package()
  install_cli(bin_dir)

  # Detect-and-instruct for the Typst CLI itself
  if (Sys.which("typst") == "") {
    message(
      "\nNOTE: the Typst CLI is not on your PATH yet. Install it with:\n",
      "  Windows:  winget install --id Typst.Typst\n",
      "  macOS:    brew install typst\n",
      "  other:    https://github.com/typst/typst/releases"
    )
  }

  message(
    "\nDone! To check the setup, open a NEW terminal ",
    "(PowerShell or Terminal -- not this R console) and run:\n",
    "  tweave --version"
  )
  invisible(TRUE)
}

# -- Typst package -------------------------------------------------------

bundled_typst_packages <- function() {
  root <- system.file("typst", package = "tweave")
  if (root == "") stop("Bundled Typst packages not found; reinstall tweave.",
                       call. = FALSE)
  list.files(root)  # e.g. "tweave", "pretty-questions"
}

install_typst_package <- function() {
  root <- system.file("typst", package = "tweave")
  for (pkg in bundled_typst_packages()) {
    dest <- file.path(typst_local_packages_dir(), pkg)
    dir.create(dest, recursive = TRUE, showWarnings = FALSE)
    ok <- file.copy(list.files(file.path(root, pkg), full.names = TRUE), dest,
                    recursive = TRUE, overwrite = TRUE)
    if (!all(ok)) stop("Could not copy the Typst package to ", dest,
                       call. = FALSE)
    message("Typst package installed: ", dest)
  }
}

# Platform-correct location of Typst's @local packages.
typst_local_packages_dir <- function() {
  sysname <- Sys.info()[["sysname"]]
  if (.Platform$OS.type == "windows") {
    file.path(Sys.getenv("LOCALAPPDATA"), "typst", "packages", "local")
  } else if (identical(sysname, "Darwin")) {
    path.expand("~/Library/Application Support/typst/packages/local")
  } else {
    data_home <- Sys.getenv("XDG_DATA_HOME", path.expand("~/.local/share"))
    file.path(data_home, "typst", "packages", "local")
  }
}

# -- CLI shim ------------------------------------------------------------

install_cli <- function(bin_dir = NULL) {
  windows <- .Platform$OS.type == "windows"
  shim_name <- if (windows) "tweave.cmd" else "tweave"
  src <- system.file("bin", shim_name, package = "tweave")
  if (src == "") stop("Bundled CLI shim not found; reinstall tweave.",
                      call. = FALSE)

  if (is.null(bin_dir)) {
    bin_dir <- if (windows) {
      file.path(Sys.getenv("LOCALAPPDATA"), "tweave", "bin")
    } else {
      path.expand("~/.local/bin")
    }
  }
  dir.create(bin_dir, recursive = TRUE, showWarnings = FALSE)

  dest <- file.path(bin_dir, shim_name)
  if (!file.copy(src, dest, overwrite = TRUE)) {
    stop("Could not copy the CLI shim to ", dest, call. = FALSE)
  }
  if (!windows) Sys.chmod(dest, "0755")
  message("CLI installed: ", dest)

  if (!dir_on_path(bin_dir)) {
    if (windows) {
      message(
        "\nOne manual step: add this folder to your PATH so the `tweave` ",
        "command works everywhere:\n  ", bin_dir, "\n",
        "How: press Start, type \"environment variables\", open ",
        "\"Edit environment variables for your account\",\n",
        "select \"Path\" -> Edit -> New, paste the folder, OK. ",
        "Then open a NEW terminal."
      )
    } else {
      message(
        "\nOne manual step: ", bin_dir, " is not on your PATH. ",
        "Add this line to your ~/.zshrc or ~/.bashrc:\n",
        '  export PATH="$HOME/.local/bin:$PATH"\n',
        "then open a new terminal."
      )
    }
  }
}

dir_on_path <- function(dir) {
  path <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
  normalizePath(dir, mustWork = FALSE) %in%
    vapply(path, normalizePath, character(1), mustWork = FALSE)
}

# -- Uninstall -----------------------------------------------------------

#' Remove everything tweave::install() set up
#'
#' Deletes the Typst template package and the CLI shim. Run this *before*
#' removing the R package itself with `remove.packages("tweave")`.
#'
#' @param bin_dir Where the CLI shim was placed, if you overrode the
#'   default in [install()].
#' @export
uninstall <- function(bin_dir = NULL) {
  removed <- FALSE

  # 1. Bundled Typst packages (tweave + pretty-questions)
  for (pkg in bundled_typst_packages()) {
    typst_pkg <- file.path(typst_local_packages_dir(), pkg)
    if (dir.exists(typst_pkg)) {
      unlink(typst_pkg, recursive = TRUE)
      message("Removed Typst package: ", typst_pkg)
      removed <- TRUE
    }
  }

  # 2. CLI shim
  windows <- .Platform$OS.type == "windows"
  if (is.null(bin_dir)) {
    bin_dir <- if (windows) {
      file.path(Sys.getenv("LOCALAPPDATA"), "tweave", "bin")
    } else {
      path.expand("~/.local/bin")
    }
  }
  shim <- file.path(bin_dir, if (windows) "tweave.cmd" else "tweave")
  if (file.exists(shim)) {
    unlink(shim)
    message("Removed CLI: ", shim)
    removed <- TRUE
  }
  # On Windows the shim lives in its own folder; remove it if now empty
  if (windows && dir.exists(bin_dir) &&
      length(list.files(bin_dir, all.files = TRUE, no.. = TRUE)) == 0) {
    unlink(bin_dir, recursive = TRUE)
  }

  if (!removed) message("Nothing to remove; tweave::install() files not found.")

  message(
    "\nTo finish, remove the R package itself:\n",
    '  remove.packages("tweave")',
    if (windows) paste0(
      "\nIf you added a tweave folder to your PATH during setup, you can ",
      "delete that entry\n(Start -> \"environment variables\" -> Path) -- ",
      "it is harmless either way."
    ) else ""
  )
  invisible(TRUE)
}
