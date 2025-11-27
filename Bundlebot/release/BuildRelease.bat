@echo off
set CURDIR=%CD%
call config.bat

echo cleaning bot repo
cd ..\..
git clean -dxf

cd %CURDIR%\..\..\Scripts
call update_repos -w

set DONOTUPLOAD=
:: uncomment following line to test script (does not upload bundle to github or run gh command)
:: set DONOTUPLOAD=-U

cd %CURDIR%
cd ..\nightly
call run_bundlebot -c -R release
cd %CURDIR%

if "X%DONOTUPLOAD%" == "X-U" goto :EOF
set "TITLE=Bundle Test - %BUNDLE_FDS_TAG%/%BUNDLE_FDS_REVISION% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_REVISION%"
gh release edit FDS_TEST -t %$TITLE% -R github.com/%username%/test_bundles
:EOF
