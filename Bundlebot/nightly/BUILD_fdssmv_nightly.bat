@echo off
set CURDIR=%CD%
set develop=%1

set is_nightly=1

:: build and upload bundle
if not exist %userprofile%\.bundle mkdir %userprofile%\.bundle
call run_bundlebot -c

:: build but don't upload bundle (for testing)
:: call run_bundlebot -c -U
cd %CURDIR%
echo complete