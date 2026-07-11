@echo off
rem tweave CLI shim. Uses Rscript from PATH if available, otherwise
rem finds the installed R via the registry (R's installer does not
rem add itself to PATH by default).
setlocal
where Rscript >nul 2>nul
if %errorlevel%==0 (
  Rscript -e "tweave::main()" %*
  exit /b %errorlevel%
)
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\R-core\R" /v InstallPath 2^>nul') do set "R_HOME=%%b"
if not defined R_HOME for /f "tokens=2,*" %%a in ('reg query "HKCU\SOFTWARE\R-core\R" /v InstallPath 2^>nul') do set "R_HOME=%%b"
if not defined R_HOME (
  echo tweave: could not find R. Install R from https://cran.r-project.org/ 1>&2
  exit /b 1
)
"%R_HOME%\bin\Rscript.exe" -e "tweave::main()" %*
exit /b %errorlevel%
