@echo off
set gitroot=%1
set REPO=%2
set base_tag=%3

set CDIR=%CD%
cd %gitroot%\%repo%

git describe --dirty --long > file.out
set /p REPOVERSION=<file.out

git rev-parse --short HEAD > file.out
set /p REVISION=<file.out

set TAG=%REPO%-%base_tag%

echo :: %REPOVERSION%
echo set BUNDLE_%REPO%_REVISION=%REVISION%
echo set BUNDLE_%REPO%_TAG=%TAG%
echo.

cd %CDIR%