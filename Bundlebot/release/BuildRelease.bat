@echo off
setlocal
if "%~1"=="-h" (
  call "%~dp0..\nightly\BuildNightly.bat" -h
  exit /b 0
)
call "%~dp0..\bundle_lock.bat" acquire || exit /b 1
call :run_bundle %*
set "BUNDLE_BUILD_RESULT=%ERRORLEVEL%"
if defined BUNDLE_LOCK_OWNED call "%~dp0..\bundle_lock.bat" release
exit /b %BUNDLE_BUILD_RESULT%

:run_bundle
set CURDIR=%CD%

call config.bat

echo cleaning bot repo
cd ..\..
git clean -dxf

set UPLOADBUNDLE=-u
:: uncomment following line to test script (does not upload bundle to github or run gh command)
:: set UPLOADBUNDLE=

cd %CURDIR%
cd ..\nightly
call BuildNightly -R %UPLOADBUNDLE%
set "BUNDLE_NIGHTLY_RESULT=%ERRORLEVEL%"
cd %CURDIR%
if not "%BUNDLE_NIGHTLY_RESULT%"=="0" exit /b %BUNDLE_NIGHTLY_RESULT%

if "X%UPLOADBUNDLE%" == "X" goto :EOF
set "TITLE=Bundle Test - %BUNDLE_FDS_TAG%/%BUNDLE_FDS_HASH% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_HASH%"
gh release edit FDS_TEST -t %$TITLE% -R github.com/%username%/test_bundles
:EOF
