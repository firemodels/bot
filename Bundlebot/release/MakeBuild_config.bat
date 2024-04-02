@echo off
:: This scripts obtains revisions and tags for a bundle.

set base_tag=%1

set CURDIR=%CD%
cd ..\..\..
set gitroot=%CD%
cd %CURDIR%

echo @echo off
echo :: This scripts defines revisions and tags for a bundle.
echo :: It is run by the other BUILD scripts.
echo :: You do not need to run it.
echo.

call RepoConfig %gitroot% CAD %base_tag% 
call RepoConfig %gitroot% EXP %base_tag% 
call RepoConfig %gitroot% FDS %base_tag% 
call RepoConfig %gitroot% FIG %base_tag% 
call RepoConfig %gitroot% OUT %base_tag% 
call RepoConfig %gitroot% SMV %base_tag% 

echo :: the lines below should not need to be changed
echo.
echo set GH_REPO=test_bundles
echo set GH_FDS_TAG=BUNDLE_TEST
echo set GH_SMOKEVIEW_TAG=BUNDLE_TEST
