@echo off
set CURDIR=%CD%
call BUILD_config.bat

cd ..\scripts
call run_bundlebot -c -R release -F %BUNDLE_FDS_REVISION% -X %BUNDLE_FDS_TAG% -S %BUNDLE_SMV_REVISION% -Y %BUNDLE_SMV_TAG%
cd %CURDIR%

:: use only tag
::set use_only_tags=1
::run_bundlebot -c -R release -X %BUNDLE_FDS_TAG% -Y %BUNDLE_SMV_TAG%

set "TITLE=Bundle Test - %BUNDLE_FDS_TA%G/%BUNDLE_FDS_REVISION% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_REVISION%"
gh release edit %GH_FDS_TAG%  -t %$TITLE% -R github.com/%GH_OWNER%/%GH_REPO%
