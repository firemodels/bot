@echo off
set repopath=%1

For %%A in ("%repopath%") do (
    set repo=%%~nxA
)
set CURDIR=%CD%
cd %repopath%
git rev-parse --short HEAD > hash.out
set /p SHORTHASH=<hash.out
git show -s --format=%%cD %SHORTHASH% > REVDATE.out
set /p REVDATE=<REVDATE.out
echo %repo% repo hash: %SHORTHASH%, commit date: %REVDATE%
erase hash.out REVDATE.out
cd %CURDIR%

