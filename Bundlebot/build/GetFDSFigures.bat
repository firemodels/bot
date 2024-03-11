@echo off
setlocal

set CURDIR=%CD%

cd bundles
set BUNDLEDIR=%CD%

echo ***cleaning %BUNDLEDIR%
git clean -dxf

cd %CURDIR%

call :downloadfile FDS_TEST FDS_UG_figures.tar.gz
call :downloadfile FDS_TEST FDS_TG_figures.tar.gz
call :downloadfile FDS_TEST FDS_VERG_figures.tar.gz
call :downloadfile FDS_TEST FDS_VALG_figures.tar.gz
cd %CURDIR%
goto eof

::----------------------------------------------------------
:downloadfile
::----------------------------------------------------------
set tag=%1
set ffile=%2
  echo downloading %ffile%
  gh release download %tag% -p %ffile% -D %BUNDLEDIR%  -R github.com/%GH_OWNER%/%GH_REPO%
  exit /b 0

:eof