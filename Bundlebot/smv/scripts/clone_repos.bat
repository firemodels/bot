@echo off
setlocal
set smv_hash=%1
set branch_name=nightly

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set scriptdir=%~dp0
cd %scriptdir%
cd ..\..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\bot\\Scripts
call setup_repos -S -n

cd %scriptdir%

cd %REPOROOT%\smv
set smvrepo=%CD%

set smvtaghash=%smv_tag%
if "x%smv_hash%" == "x" goto end_smv_hash
set smvtaghash=%smv_hash%
:end_smv_hash

git checkout -b %branch_name% %smvtaghash%

git describe --abbrev=7 --dirty --long
git branch -a

cd %scriptdir%

