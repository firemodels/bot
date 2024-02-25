@echo off
set CURDIR=%CD%
call BUILD_config.bat

cd ..\scripts
call run_bundlebot -c -R release -F %BUNDLE_FDS_REVISION% -X %BUNDLE_FDS_TAG% -S %BUNDLE_SMV_REVISION% -Y %BUNDLE_SMV_TAG%
cd %CURDIR%
call BUILD_settitle.bat

:: use only tag
::set use_only_tags=1
::run_bundlebot -c -R release -X %BUNDLE_FDS_TAG% -Y %BUNDLE_SMV_TAG%

