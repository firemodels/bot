@echo off
set month=%1
set year=%2
set repo=%3

set fromdate=%year%-%month%-1
set todate=%year%-%month%-31

set fromdate="2025-08-01"
set todate="2025-08-31"

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

set outfile=%repo%_%year%_%month%.log

cd %repodir%
echo %repodir%
git log --no-merges --abbrev-commit --since=%fromdate% --until=%todate% --pretty=oneline --date=short 
git log --no-merges --abbrev-commit --since=%fromdate% --until=%todate% --pretty=oneline --date=short > %outfile% 2>&1

cd %CURDIR%

