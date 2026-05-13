@echo off
set branch=%1
set repo=%2

if not "x%branch%" == "x" goto endif0
if not "x%repo%"   == "x" goto endif0
  echo Usage: newbranch branch repo
  echo   create a branch in repo repo.
  echo.
  echo   branch - branch to be created
  echo   repo   - repo branch is created in (default: smv)
  exit /b
:endif0


if "x%repo%" == "x" set repo=smv

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


