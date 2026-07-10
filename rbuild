#!/usr/bin/env bash
# rbuild — knit an .typ file with R chunks and compile to PDF
# Usage: rbuild myfile.typ
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Rscript "$SCRIPT_DIR/build.R" "$@"
