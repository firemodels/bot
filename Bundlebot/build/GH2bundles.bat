@echo off

set CURDIR=%CD%
call BUILD_config.bat

cd bundles
set BUNDLEDIR=%CD%

echo ***cleaning %BUNDLEDIR%
git clean -dxf

cd %CURDIR%

set BUNDLE_BASE=%BUNDLE_FDS_TAG%_%BUNDLE_SMV_TAG%_

:DOWNLOADFILE
  set FILE=%1
  echo downloading %FILE%
  gh release download %GH_FDS_TAG% -p %FILE% -D %BUNDLEDIR%  -R github.com/%GH_OWNER%/%GH_REPO%
  exit /b

call :DOWNLOADFILE FDS_Config_Management_Plan.pdf
call :DOWNLOADFILE FDS_Technical_Reference_Guide.pdf
call :DOWNLOADFILE FDS_User_Guide.pdf
call :DOWNLOADFILE FDS_Validation_Guide.pdf
call :DOWNLOADFILE FDS_Verification_Guide.pdf
call :DOWNLOADFILE SMV_User_Guide.pdf
call :DOWNLOADFILE SMV_Verification_Guide.pdf
call :DOWNLOADFILE SMV_Technical_Reference_Guide.pdf
call :DOWNLOADFILE %BUNDLE_BASE%lnx.sh
call :DOWNLOADFILE %BUNDLE_BASE%lnx.sha1
call :DOWNLOADFILE %BUNDLE_BASE%osx.sh
call :DOWNLOADFILE %BUNDLE_BASE%osx.sha1
call :DOWNLOADFILE %BUNDLE_BASE%win.exe
call :DOWNLOADFILE %BUNDLE_BASE%win.sha1
echo ***files downloaded to %BUNDLEDIR%
cd %CURDIR%
