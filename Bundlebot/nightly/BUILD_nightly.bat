@echo off
set CURDIR=%CD%
set develop=%1

:: build and upload bundle
::call run_bundlebot -c >  bundle2.out 2>&1
call run_bundlebot -c %develop%

:: build but don't upload bundle (for testing)
:: call run_bundlebot -c -U
cd %CURDIR%
echo complete