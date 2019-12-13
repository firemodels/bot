@echo off
set clone=%1
set hostname=%2
set firebot_home=%3
set smokebot_home=%4

if EXIST .bundler goto endif1
  echo ***error: run_bundler.bat must be run in bot/Bundler/fds/scripts directory
  exit /b 1
:endif1

if "x%clone%" == "xclone" goto endif2
  echo ***error:  this script clones (ie erases) the fds and smv repos.  
  echo            clone must be specified as the first argument to use this script
  exit /b 1
:endif2


:: make sure we are running in the master branch
set CURDIR=%CD%
cd ..\..\..
set botrepo=%CD%
call :cd_repo %botrepo% master || exit /b 1

:: bring the repo up to date
git fetch origin master
git merge origin/master

cd %CURDIR%

:: create the bundle
call bundler clone %hostname% %firebot_home% %smokebot_home% || exit /b 1

goto eof


:: -------------------------------------------------------------
:chk_repo
:: -------------------------------------------------------------

set repodir=%1

if NOT exist %repodir% (
  echo ***error: repo directory %repodir% does not exist
  echo  aborted
  exit /b 1
)
exit /b 0


:: -------------------------------------------------------------
:cd_repo
:: -------------------------------------------------------------

set repodir=%1
set repobranch=%2

call :chk_repo %repodir% || exit /b 1

cd %repodir%
if "%repobranch%" == "" (
  exit /b 0
)
git rev-parse --abbrev-ref HEAD>current_branch.txt
set /p current_branch=<current_branch.txt
erase current_branch.txt
if "%repobranch%" NEQ "%current_branch%" (
  echo ***error: in repo %repodir% found branch %current_branch%
  echo            was expecting branch %repobranch%
  echo  aborted
  exit /b 1
)
exit /b 0

:eof

exit /b 0
