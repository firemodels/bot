@echo on
setlocal

set OWNER=%1

if x%OWNER% == x set OWNER=%username%

set CURDIR=%CD%
call config

cd bundles
set BUNDLEDIR=%CD%

echo ***cleaning %BUNDLEDIR%
git clean -dxf

cd %CURDIR%

set BUNDLE_BASE=%BUNDLE_FDS_TAG%_%BUNDLE_SMV_TAG%_

call :downloadfile FDS_TEST FDS_Config_Management_Plan.pdf
call :downloadfile FDS_TEST FDS_Technical_Reference_Guide.pdf
call :downloadfile FDS_TEST FDS_User_Guide.pdf
call :downloadfile FDS_TEST FDS_Validation_Guide.pdf
call :downloadfile FDS_TEST FDS_Verification_Guide.pdf

call :downloadfile SMOKEVIEW_TEST SMV_User_Guide.pdf
call :downloadfile SMOKEVIEW_TEST SMV_Verification_Guide.pdf
call :downloadfile SMOKEVIEW_TEST SMV_Technical_Reference_Guide.pdf

call :downloadfile FDS_TEST %BUNDLE_BASE%lnx.sh
call :downloadfile FDS_TEST %BUNDLE_BASE%lnx_manifest.html

call :downloadfile FDS_TEST %BUNDLE_BASE%osx.sh
call :downloadfile FDS_TEST %BUNDLE_BASE%osx_manifest.html

call :downloadfile FDS_TEST %BUNDLE_BASE%win.exe
call :downloadfile FDS_TEST %BUNDLE_BASE%win_manifest.html
echo ***files downloaded to %BUNDLEDIR%
cd %CURDIR%
goto eof

::----------------------------------------------------------
:downloadfile
::----------------------------------------------------------
set RELEASE=%1
set ffile=%2
  echo downloading %ffile%
  gh release download %RELEASE% -p %ffile% -D %BUNDLEDIR%  -R github.com/%OWNER%/test_bundles
  exit /b 0

:eof
