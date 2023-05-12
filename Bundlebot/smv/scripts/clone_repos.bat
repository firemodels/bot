@echo off
set smv_hash=%1
set branch_name=nightly

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set CURDIR=%CD%
cd ..\..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\bot\\Scripts
call setup_repos -S -n

cd %CURDIR%

cd %REPOROOT%\smv
set smvrepo=%CD%

cd %smvrepo%
set smvtaghash=%smv_tag%
if "x%smv_hash%" == "x" goto end_smv_hash
set smvtaghash=%smv_hash%
:end_smv_hash

git checkout -b %branch_name% %smvtaghash%

git describe --abbrev=7 --dirty --long
git branch -a

cd %CURDIR%

