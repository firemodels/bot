@echo off
setlocal

OWNER=%username%
if "x%is_nightly%" == "x1" set OWNER=firemodels

set repo=%1
set TITLE=
set INFO=
set PREFIX=

set tag=x
if "x%repo%" == "xfds" set tag=FDS_TEST
if "x%repo%" == "xsmv" set tag=SMOKEVIEW_TEST
if "x%repo%" == "xcfast" set tag=CFAST_TEST
if x%tag% == x exit /b

set tempfile=%temp%\tempfile
cd ..\..\..\%repo%

git rev-parse --short HEAD > %tempfile%
set /p hash=<%tempfile%
erase %tempfile%

git describe --abbrev=7 --dirty --long  > %tempfile%
set /p TITLE=<%tempfile%
erase %tempfile%

git show -s --format=%%cd --date=format:"%%Y-%%b-%%d %%H:%%M" %hash% > %tempfile%
set /p INFO=<%tempfile%
erase %tempfile%

if NOT "x%INFO%" == "x" set TITLE=%TITLE% %INFO%
gh release edit %tag% -t "%TITLE%" -R github.com/%OWNER%/test_bundles
