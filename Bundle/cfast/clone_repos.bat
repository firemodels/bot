@echo off
setlocal
set cfast_hash=%1
set smv_hash=%2
set branch_name=%3
set cfast_tag=%4
set smv_tag=%5

if "x%use_only_tags%" == "x" goto end_use_only_tag
set cfast_hash=
set smv_hash=
:end_use_only_tag

if NOT "x%cfast_hash%" == "x" goto skip_cfast_hash
  set FDS_HASH=%cfast_hash%
:skip_cfast_hash

if NOT "x%smv_hash%" == "x" goto skip_smv_hash
  set SMV_HASH=%smv_hash%
:skip_smv_hash

set CURDIR=%CD%

cd ..\..\Scripts
call setup_repos -C -n

cd %CURDIR%

cd ..\..\..\cfast
set cfastrepo=%CD%

cd ..\smv
set smvrepo=%CD%

cd %cfastrepo%
set cfasttaghash=%cfast_tag%
if "x%cfast_hash%" == "x" goto end_cfast_hash
set cfasttaghash=%cfast_hash%
:end_cfast_hash

git checkout -b %branch_name% %cfasttaghash%

if "x%cfast_tag%" == "x" goto end_cfast_tag
if "x%cfast_hash%" == "x" goto end_cfast_hash2
git tag -a %cfast_tag% -m "add %cfast_tag% for cfast repo"
:end_cfast_hash2
:end_cfast_tag
git describe --dirty --long
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
git describe --dirty --long
git branch -a

cd %CURDIR%

