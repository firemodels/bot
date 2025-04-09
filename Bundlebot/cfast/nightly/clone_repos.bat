@echo off
setlocal
set cfast_hash=%1
set smv_hash=%2
set branch_name=%3
set cfast_tag=%4
set smv_tag=%5

set CURDIR=%CD%
cd ..\..\..\..
set ROOTDIR=%CD%
cd %CURDIR%

cd %ROOTDIR%\bot\Scripts
call setup_repos -C -n

cd %CURDIR%

cd %ROOTDIR%\cfast
set cfastrepo=%CD%

cd %ROOTDIR%\smv
set smvrepo=%CD%

cd %cfastrepo%

if %cfast_hash% == latest set hash=
git checkout -b %branch_name% %cfast_hash%
if "x%cfast_tag%" == "x" goto endif1
  git tag -a %cfast_tag% -m "tag for %cfast_tag%
:endif1

git describe --abbrev=7 --dirty --long
git branch -a

cd %smvrepo%

if %smv_hash% == latest set hash=
git checkout -b %branch_name% %smv_hash%
if "x%smv_tag%" == "x" goto endif2
  git tag -a %smv_tag% -m "tag for %smv_tag%
:endif2

git describe --abbrev=7 --dirty --long
git branch -a

cd %CURDIR%
