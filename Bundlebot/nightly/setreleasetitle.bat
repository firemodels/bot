@echo off
setlocal

set repo=%1
set TITLE=
set INFO=
set PREFIX=

set ERROR=1
if NOT "x%repo%" == "xfds" goto endif1
  set tag=FDS_TEST
  set ERROR=
:endif1

if NOT "x%repo%" == "xsmv" goto endif2
  set tag=SMOKEVIEW_TEST
  set ERROR=
:endif2

if NOT "x%repo%" == "xcfast" goto endif3
  set tag=CFAST_TEST
  set ERROR=
:endif3

if NOT x%ERROR% == x exit /b

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
gh release edit %tag% -t "%TITLE%" -R github.com/%GH_OWNER%/%GH_REPO%
