@echo off

set CURDIR=%CD%
call config.bat

cd smvbundles
set BUNDLEDIR=%CD%

echo ***cleaning $BUNDLEDIR
git clean -dxf

cd %CURDIR%

set BUNDLE_BASE=%BUNDLE_SMV_TAG%_

call :downloadfile %BUNDLE_BASE%lnx.sh
:: call :downloadfile ${BUNDLE_BASE}lnx.tar.gz
call :downloadfile %BUNDLE_BASE%lnx.sha1

call :downloadfile %BUNDLE_BASE%osx.sh
:: call :downloadfile ${BUNDLE_BASE}osx.tar.gz
call :downloadfile %BUNDLE_BASE%osx.sha1

call :downloadfile %BUNDLE_BASE%win.exe
::call :downloadfile ${BUNDLE_BASE}win.tar.gz
call :downloadfile %BUNDLE_BASE%win.sha1

echo ***files downloaded to %BUNDLEDIR%
cd %CURDIR%
goto eof

::----------------------------------------------------------
:downloadfile
::----------------------------------------------------------
set ffile=%1
  echo downloading %ffile%
  gh release download SMOKEVIEW_TEST2 -p %ffile% -D %BUNDLEDIR%  -R github.com/%GH_OWNER%/%GH_REPO%
  exit /b 0

:eof
