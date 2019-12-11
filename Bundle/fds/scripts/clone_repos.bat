@echo off

call get_hash_revisions.bat || exit /b 1

set /p FDS_HASH=<output\FDS_HASH
set /p SMV_HASH=<output\SMV_HASH

set CURDIR=%CD%

cd ..\..\..\Scripts
call setup_repos -T -n

cd %CURDIR%

cd ..\..\..\..\fds
set fdsrepo=%CD%

cd ..\smv
set smvrepo=%CD%

cd %fdsrepo%
git checkout -b test %FDS_HASH%
git describe --dirty --long
git branch -a

cd %smvrepo%
git checkout -b test %SMV_HASH%
git describe --dirty --long
git branch -a

cd %CURDIR%

