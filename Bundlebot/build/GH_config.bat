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

