@echo off
set smv_hash=%1
set branch_name=%2
set smv_tag=%3

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set CURDIR=%CD%
cd ..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\bot\Scripts
call setup_repos -S -n

cd %CURDIR%

cd %REPOROOT%\smv
set smvrepo=%CD%

cd %smvrepo%
git checkout -b %branch_name% %smv_hash%
if "x%smv_tag%" == "x" goto skip_smv_tag
git tag -a %smv_tag% -m "add %smv_tag% for smv repo"
:skip_smv_tag
git describe --abbrev=7 --dirty --long
git branch -a

cd %CURDIR%

