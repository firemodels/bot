@echo off
set fds_hash=%1
set smv_hash=%2

if "x%use_only_tags%" == "x" goto end_use_only_tag
set fds_hash=
set smv_hash=
:end_use_only_tag

if NOT "x%fds_hash%" == "x" goto skip_fds_hash
  set FDS_HASH=%fds_hash%
:skip_fds_hash

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set CURDIR=%CD%
cd ..\..\..
set REPOROOT=%CD%

::***clone fds and smv repos

cd %REPOROOT%\bot\\Scripts
call setup_repos -T -n

::***setup fds repo

cd %REPOROOT%\fds
git checkout -b nightly %fdshash%
git describe --abbrev=7 --dirty --long
git branch -a

::***setup smv repo

cd %REPOROOT%\smv
git checkout -b nightly %smv_hash%
git describe --abbrev=7 --dirty --long
git branch -a

cd %CURDIR%

