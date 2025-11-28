@echo off
set CURDIR=%CD%
set is_release=1

call config.bat

echo cleaning bot repo
cd ..\..
git clean -dxf

set UPLOADBUNDLE=-U
:: uncomment following line to test script (does not upload bundle to github or run gh command)
:: set UPLOADBUNDLE=

cd %CURDIR%
cd ..\nightly
call BuildNightly -R release %UPLOADBUNDLE%
cd %CURDIR%

if "X%UPLOADBUNDLE%" == "X" goto :EOF
set "TITLE=Bundle Test - %BUNDLE_FDS_TAG%/%BUNDLE_FDS_REVISION% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_REVISION%"
gh release edit FDS_TEST -t %$TITLE% -R github.com/%username%/test_bundles
:EOF
