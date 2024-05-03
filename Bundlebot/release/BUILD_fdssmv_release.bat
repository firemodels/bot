@echo off
set CURDIR=%CD%
call config.bat

cd ..\..\Scripts
call update_repos -m

set TEST=
:: uncomment following line to test script (does not upload bundle to github or run gh command)
:: set TEST=-U

cd %CURDIR%
cd ..\nightly
call run_bundlebot -c -R release -F %BUNDLE_FDS_REVISION% -X %BUNDLE_FDS_TAG% -S %BUNDLE_SMV_REVISION% -Y %BUNDLE_SMV_TAG% %TEST%
cd %CURDIR%

if "X%TEST%" == "X-U" goto :EOF
set "TITLE=Bundle Test - %BUNDLE_FDS_TA%G/%BUNDLE_FDS_REVISION% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_REVISION%"
gh release edit %GH_FDS_TAG%  -t %$TITLE% -R github.com/%GH_OWNER%/%GH_REPO%
:EOF
