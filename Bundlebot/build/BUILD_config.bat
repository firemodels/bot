@echo off
:: this script is used by other bundle scripts when building a release
:: edit fds and smv revisions and tags
set option=%1
set valid=
if "%option%" == "nightly" set valid=1
if "%option%" == "test" set valid=1
if "%option%" == "release" set valid=1
if "%valid%" == "" set option=test
if "%option%" == "nightly" set GH_REPO=nightly_bundles
if "%option%" == "test" set GH_REPO=test_bundles
if "%option%" == "release" set GH_REPO=fds

:: firebot pass 2/17/2024
:: FDS-6.8.0-1523-g29bcb71/master
:: SMV-6.8.0-2073-g0f8b692/master

set BUNDLE_FDS_REVISION=29bcb71
set BUNDLE_FDS_TAG=FDS-6.9.0tst
set BUNDLE_SMV_REVISION=0f8b692
set BUNDLE_SMV_TAG=SMV-6.9.0tst
