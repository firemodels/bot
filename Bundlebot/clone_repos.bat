@echo off
set fds_hash=%1
set smv_hash=%2

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
git checkout -b nightly %FDS_HASH%
git describe --dirty --long
git branch -a

cd %smvrepo%
git checkout -b nightly %SMV_HASH%
git describe --dirty --long
git branch -a

cd %CURDIR%

