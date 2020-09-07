@echo off
set fds_hash=%1
set smv_hash=%2
set branch_name=%3
set fds_tag=%4
set smv_tag=%5

if NOT "x%fds_hash%" == "x" goto skip_fds_hash
  set FDS_HASH=%fds_hash%
:skip_fds_hash

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set CURDIR=%CD%

cd ..\Scripts
call setup_repos -T -n

cd %CURDIR%

cd ..\..\fds
set fdsrepo=%CD%

cd ..\smv
set smvrepo=%CD%

cd %fdsrepo%
git checkout -b %branch_name% %fds_hash%
if "x%fds_tag%" == "x" goto skip_fds_tag
git tag -a %fds_tag% -m "add %fds_tag% for fds repo"
:skip_fds_tag
git describe --dirty --long
git branch -a

cd %smvrepo%
git checkout -b %branch_name% %smv_hash%
if "x%smv_tag%" == "x" goto skip_smv_tag
git tag -a %smv_tag% -m "add %smv_tag% for smv repo"
:skip_smv_tag
git describe --dirty --long
git branch -a

cd %CURDIR%

