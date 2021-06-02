@echo off
set smv_hash=%1
set branch_name=%2
set smv_tag=%3

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set CURDIR=%CD%

cd ..\Scripts
call setup_repos -T -n

cd %CURDIR%

cd ..\smv
set smvrepo=%CD%

cd %smvrepo%
git checkout -b %branch_name% %smv_hash%
if "x%smv_tag%" == "x" goto skip_smv_tag
git tag -a %smv_tag% -m "add %smv_tag% for smv repo"
:skip_smv_tag
git describe --dirty --long
git branch -a

cd %CURDIR%

