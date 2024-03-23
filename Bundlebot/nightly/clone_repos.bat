@echo off
set fds_hash=%1
set smv_hash=%2
set branch_name=%3
set fds_tag=%4
set smv_tag=%5

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

cd %REPOROOT%\bot\\Scripts
call setup_repos -T -n

cd %CURDIR%

cd %REPOROOT%\fds
set fdsrepo=%CD%

cd %REPOROOT%\smv
set smvrepo=%CD%

cd %fdsrepo%
set fdstaghash=%fds_tag%
if "x%fds_hash%" == "x" goto end_fds_hash
set fdstaghash=%fds_hash%
:end_fds_hash

git checkout -b %branch_name% %fdstaghash%

if "x%fds_tag%" == "x" goto end_fds_tag
if "x%fds_hash%" == "x" goto end_fds_hash2
git tag -a %fds_tag% -m "add %fds_tag% for fds repo"
:end_fds_hash2
:end_fds_tag
git describe --abbrev=7 --dirty --long
git branch -a

cd %smvrepo%
set smvtaghash=%smv_tag%
if "x%smv_hash%" == "x" goto end_smv_hash
set smvtaghash=%smv_hash%
:end_smv_hash

git checkout -b %branch_name% %smvtaghash%

if "x%smv_tag%" == "x" goto end_smv_tag
if "x%smv_hash%" == "x" goto end_smv_hash2
git tag -a %smv_tag% -m "add %smv_tag% for smv repo"
:end_smv_tag
:end_smv_hash2
git describe --abbrev=7 --dirty --long
git branch -a

cd %CURDIR%

