@echo off
set CURDIR=%CD%

:: build and upload bundle
call run_bundlebot -c >  bundle2.out 2>&1

:: build but don't upload bundle (for testing)
:: call run_bundlebot -c -U
cd %CURDIR%
echo complete