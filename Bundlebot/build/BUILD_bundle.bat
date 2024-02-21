@echo off
set option=%1

call GH_config %option%
call BUILD_config

cd ..\scripts
call run_bundlebot -c -R release -F %BUNDLE_FDS_REVISION% -X %BUNDLE_FDS_TAG% -S %BUNDLE_SMV_REVISION% -Y %BUNDLE_SMV_TAG%

:: use only tag
::set use_only_tags=1
::run_bundlebot -c -R release -X %BUNDLE_FDS_TAG% -Y %BUNDLE_SMV_TAG%

