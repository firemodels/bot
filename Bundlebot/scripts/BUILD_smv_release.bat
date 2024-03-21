@echo off
call ..\build\BUILD_config
run_smv_bundlebot -R release -S %BUNDLE_SMV_REVISION% -Y %BUNDLE_SMV_TAG%
