@echo off
set repopath=%1
set option=%2

For %%A in ("%repopath%") do (
    set repo=%%~nxA
)
set CURDIR=%CD%
cd %repopath%
git rev-parse --short HEAD > hash.out
set /p SHORTHASH=<hash.out
if "x%option%" == "x" goto else1
git show -s --format=%%cd --date=format:%%Y%%b%%d %SHORTHASH% > REVDATE.out
set /p REVDATE=<REVDATE.out
echo %REVDATE%
goto endif1
:else1
git show -s --format=%%cD %SHORTHASH% > REVDATE.out
set /p REVDATE=<REVDATE.out
echo %repo% repo hash: %SHORTHASH%, commit date: %REVDATE%
:endif1
erase hash.out REVDATE.out
cd %CURDIR%

