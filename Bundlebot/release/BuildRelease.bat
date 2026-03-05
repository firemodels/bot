@echo off
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
cd %CURDIR%

if "X%UPLOADBUNDLE%" == "X" goto :EOF
set "TITLE=Bundle Test - %BUNDLE_FDS_TAG%/%BUNDLE_FDS_HASH% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_HASH%"
gh release edit FDS_TEST -t %$TITLE% -R github.com/%username%/test_bundles
:EOF
