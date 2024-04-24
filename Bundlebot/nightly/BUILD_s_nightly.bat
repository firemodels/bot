@echo off
setlocal
set CURDIR=%CD%

:: build and upload bundle
if not exist %userprofile%\.bundle mkdir %userprofile%\.bundle
::call make_smv_bundle > %userprofile%\.bundle\bundle_smv_nightly.out 2>&1
call make_smv_bundle 

cd %CURDIR%
echo complete