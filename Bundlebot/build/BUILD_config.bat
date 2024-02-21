@echo off
:: This scripts defines revisions and tags for a bundle.
:: It is run by the other BUILD scripts.
:: You do not need to run it.

:: firebot pass 2/17/2024
:: FDS-6.8.0-1523-g29bcb71/master
:: SMV-6.8.0-2073-g0f8b692/master

set BUNDLE_OPTION=test
::set BUNDLE_OPTION=release
set BUNDLE_FDS_REVISION=debb46d
set BUNDLE_FDS_TAG=FDS-6.9.0
set BUNDLE_SMV_REVISION=0f8b692
set BUNDLE_SMV_TAG=SMV-6.9.0

:: lines below should not need to be changed

set valid=
if "%BUNDLE_OPTION%" == "nightly" set valid=1
if "%BUNDLE_OPTION%" == "test" set valid=1
if "%BUNDLE_OPTION%" == "release" set valid=1
if "%BUNDLE_OPTION%" == "" set option=test
if "%BUNDLE_OPTION%" == "nightly" set GH_REPO=nightly_bundles
if "%BUNDLE_OPTION%" == "test" set GH_REPO=test_bundles
if "%BUNDLE_OPTION%" == "release" set GH_REPO=fds
