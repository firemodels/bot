@echo off
call config
set CURDIR=%CD%
cd ..\nightly
::set GH_OWNER=%userprofile%
call run_cfastbundle -b release -f -u -C %BUNDLE_CFAST_REVISION% -c %BUNDLE_CFAST_TAG% -S %BUNDLE_SMV_REVISION% -s %BUNDLE_SMV_TAG%
cd %CURDIR%