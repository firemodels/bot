@echo off
set CURDIR=%CD%
call config.bat

cd ..\..\Scripts
call setup_repos -A

set TEST=
:: uncomment following line to test script (does not upload bundle to github or run gh command)
:: set TEST=-U

cd %CURDIR%
cd ..\nightly
call run_bundlebot -c -R release -F %BUNDLE_FDS_REVISION% -X %BUNDLE_FDS_TAG% -S %BUNDLE_SMV_REVISION% -Y %BUNDLE_SMV_TAG% %TEST%
cd %CURDIR%

if "X%TEST%" == "X-U" goto :EOF
set "TITLE=Bundle Test - %BUNDLE_FDS_TAG%/%BUNDLE_FDS_REVISION% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_REVISION%"
gh release edit FDS_TEST -t %$TITLE% -R github.com/%username%/test_bundles
:EOF
