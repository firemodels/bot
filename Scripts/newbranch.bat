@echo off
set repo=%1
set branch=%2

set CURDIR=%CD%

cd ..\..
set GITROOT=%CD%

cd %CURDIR%

set repodir=%GITROOT%\%repo%
if exist %repodir% goto endif1
  echo ***error: repo %repodir% does not exist
  exit /b
:endif1

if NOT "x%branch%" == "x" goto endif2
  echo ***error: branch parameter is missing
  exit /b
:endif2

echo Do you wish to create the branch: %branch% in repo: %repodir% ?
echo Press any key to continue, CTRL c to abort
pause >Nul

cd %repodir%
git checkout -b %branch% firemodels/master
git push -u origin %branch%


