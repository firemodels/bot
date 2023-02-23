@echo off
setlocal
set cfast_hash=%1
set smv_hash=%2
set branch_name=%3

set CURDIR=%CD%

cd ..\..\Scripts
call setup_repos -C -n

cd %CURDIR%

cd ..\..\..\cfast
set cfastrepo=%CD%

cd ..\smv
set smvrepo=%CD%

cd %cfastrepo%

set hash=%cfast_hash%
if %hash% == latest set hash=
git checkout -b %branch_name% %hash%

git describe --dirty --long
git branch -a

cd %smvrepo%

set hash=%smv_hash%
if %hash% == latest set hash=
git checkout -b %branch_name% %hash%

git describe --dirty --long
git branch -a

cd %CURDIR%

