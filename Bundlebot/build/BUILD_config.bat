@echo off
:: This scripts defines revisions and tags for a bundle.
:: It is run by the other BUILD scripts.
:: You do not need to run it.

:: firebot pass 2/21/2024
:: FDS-6.8.0-1538-g3abe090/master
:: SMV-6.8.0-2075-g38047e9/master

set BUNDLE_OPTION=test
::set BUNDLE_OPTION=release

set BUNDLE_FDS_REVISION=3abe090
set BUNDLE_FDS_TAG=FDS-6.9.0
set BUNDLE_SMV_REVISION=38047e9
set BUNDLE_SMV_TAG=SMV-6.9.0

:: lines below should not need to be changed

if NOT "%BUNDLE_OPTION%" == "release" set BUNDLE_OPTION=test
if "%BUNDLE_OPTION%" == "test" set GH_REPO=test_bundles
if "%BUNDLE_OPTION%" == "test" set GH_FDS_TAG=BUNDLE_TEST
if "%BUNDLE_OPTION%" == "test" set GH_SMOKEVIEW_TAG=BUNDLE_TEST
if "%BUNDLE_OPTION%" == "release" set GH_REPO=fds
