@echo off
set CURDIR=%CD%
set develop=%1

:: build and upload bundle
if not exist %userprofile%\.bundle mkdir %userprofile%\.bundle
call run_bundlebot -c %develop% > %userprofile%\.bundle\bundle_nightly.out 2>&1

:: build but don't upload bundle (for testing)
:: call run_bundlebot -c -U
cd %CURDIR%
echo complete