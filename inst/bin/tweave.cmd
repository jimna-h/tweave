@echo off
rem tweave CLI shim. Requires Rscript on PATH.
setlocal
where Rscript >nul 2>nul
if %errorlevel%==0 (
  Rscript -e "tweave::main()" %*
  exit /b %errorlevel%
)
echo tweave: Rscript not found on PATH. 1>&2
echo   Reinstall R from https://cran.r-project.org/, or add R's bin folder 1>&2
echo   (e.g. C:\Program Files\R\R-4.x.x\bin) to your PATH, then open a new terminal. 1>&2
exit /b 1
