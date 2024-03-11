@echo off
setlocal

set CURDIR=%CD%

cd bundles
set BUNDLEDIR=%CD%

echo ***cleaning %BUNDLEDIR%
git clean -dxf

cd %CURDIR%

call :downloadfile SMOKEVIEW_TEST SMV_UG_figures.tar.gz
call :downloadfile SMOKEVIEW_TEST SMV_VG_figures.tar.gz

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