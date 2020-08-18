@echo off

set clone=
set bundle_hostname=
set bundle_firebot_home=
set bundle_smokebot_home=
set fds_hash=
set smv_hash=
set BRANCH_NAME=nightly
set configscript=%userprofile%\.bundle\bundle_config.bat

:: define defaults

if NOT exist %configscript% goto skip_config
  call %configscript%
:skip_config

:: define default strings for the usage script
set default_hostname=
set default_firebot_home=
set default_smokebot_home=

if x"%bundle_hostname%" == "x" goto def1
  set default_hostname=[default: %bundle_hostname%]
:def1

if x"%bundle_firebot_home%" == "x" goto def2
  set default_firebot_home=[default: %bundle_firebot_home%]
:def2

if x"%bundle_smokebot_home%" == "x" goto def3
  set default_smokebot_home=[default: %bundle_smokebot_home%]
:def3

if EXIST .bundlebot goto endif1
  echo ***error: run_bundlebot.bat must be run in bot/Bundlebot directory
  exit /b 1
:endif1

::*** parse command line arguments
call :getopts %*

if "x%stopscript%" == "x" goto endif2
  exit /b 1
:endif2

set nightly=tst
set pub_dir=
if NOT "x%BRANCH_NAME%" == "xrelease" goto skip_branch
  set nightly=null
  set pub_dir=release
:skip_branch

:: set pubs directories
set FDS_PUBS_DIR=%bundle_firebot_home%/.firebot/%pub_dir%/pubs
set SMV_PUBS_DIR=%bundle_smokebot_home%/.smokebot/%pub_dir%/pubs

::*** error checking

set abort=

::--- both or neither fds and smv hashes need to be defined
set bad_hash=
if NOT "x%fds_hash%" == "x" goto hash1a
if "x%smv_hash%" == "x" goto hash1b
set bad_hash=1
:hash1b
:hash1a

if "x%fds_hash%" == "x" goto hash2a
if NOT "x%smv_hash%" == "x" goto hash2b
set bad_hash=1
:hash2b
:hash2a

if "x%bad_hash%" == "x" goto badhash
  echo ***error: both or neither fds and smv hashes must be specified.  Only one was found
  set abort=1
:badhash

if "x%clone%" == "xclone" goto endif3
  echo ***error:  this script clones (ie erases) the fds and smv repos.  
  echo            -c must be specified on othe command line to use this script
  set abort=1
:endif3

::--- make sure hostname is defined

if NOT x"%bundle_hostname%" == "x" goto error1
  echo ****error:  hostname where firebot and smokebot was run not defined
  set abort=1
:error1

if NOT x"%firebot_home%" == "x" goto error2
  echo ****error:  firebot home directory not defined
  set abort=1
:error2

if NOT x"%smokebot_home%" == "x" goto error3
  echo ****error:  smokebot home directory not defined
  set abort=1
:error3

if "x%abort%" == "x" goto error4
  call :usage
  exit /b 1
:error4

:: make sure we are running in the master branch
set CURDIR=%CD%
cd ..
set botrepo=%CD%

if exist ..\webpages goto endif4
  echo ***error: the webpages repo does not exist
  cd %CURDIR%
  exit /b 1
:endif4

cd ..\webpages
set webpagesrepo=%CD%

cd ..
set basedir=%CD%

:: bring the bot repo up to date
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo updating bot repo
echo.

call :cd_repo %botrepo% master || exit /b 1
git fetch origin master > Nul
git merge origin/master > Nul

:: bring the webpages repo up to date
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo updating web repo
echo.

call :cd_repo %webpagesrepo% nist-pages || exit /b 1
git fetch origin nist-pages  > Nul
git merge origin/nist-pages  > Nul

cd %CURDIR%

:: create the bundle

set CURDIR=%CD%


if NOT "x%fds_hash%" == "x" goto skip_elsehash

  call get_hash_revisions.bat || exit /b 1

  set /p FDS_HASH_BUNDLER=<output\FDS_HASH
  set /p SMV_HASH_BUNDLER=<output\SMV_HASH
  set /p FDS_REVISION_BUNDLER=<output\FDS_REVISION
  set /p SMV_REVISION_BUNDLER=<output\SMV_REVISION

  erase output\FDS_HASH
  erase output\SMV_HASH
  erase output\FDS_REVISION
  erase output\SMV_REVISION
  goto endif_gethash

:skip_elsehash
  set FDS_HASH_BUNDLER=%fds_hash%
  set SMV_HASH_BUNDLER=%smv_hash%
  set FDS_REVISION_BUNDLER=%fds_hash%
  set SMV_REVISION_BUNDLER=%smv_hash%
:endif_gethash

cd %CURDIR%

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Building bundle using:
echo.
if "x%FDS_REVISION_BUNDLER%" == "x" goto skip_fdsrev
  echo             FDS revision: %FDS_REVISION_BUNDLER%
:skip_fdsrev
if "x%SMV_REVISION_BUNDLER%" == "x" goto skip_smvrev
  echo             smv revision: %SMV_REVISION_BUNDLER%
:skip_smvrev
echo   FDS repo revision/hash: %FDS_HASH_BUNDLER%
echo   smv repo revision/hash: %SMV_HASH_BUNDLER%
echo    firebot/smokebot host: %bundle_hostname%
echo   firebot home directory: %bundle_firebot_home%
echo        FDS pub directory: %FDS_PUBS_DIR%
echo  smokebot home directory: %bundle_smokebot_home%
echo Smokeview pubs directory: %SMV_PUBS_DIR%
echo.

call clone_repos %FDS_HASH_BUNDLER% %SMV_HASH_BUNDLER% %BRANCH_NAME% || exit /b 1

:: define revisions if hashes were specified on the command line
if NOT "x%fds_hash%" == "x" goto skip_getrevision

  call :cd_repo %basedir%\fds %BRANCH_NAME% || exit /b 1
  git describe --dirty --long > temp1
  set /p FDS_REVISION_BUNDLER=<temp1
  erase temp1

  call :cd_repo %basedir%\smv %BRANCH_NAME% || exit /b 1
  git describe --dirty --long > temp1
  set /p SMV_REVISION_BUNDLER=<temp1
  erase temp1
:skip_getrevision

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Building apps
echo.

cd %CURDIR%
call make_apps         || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying fds apps
echo.
cd %CURDIR%
call copy_apps fds bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying smv apps
echo.

cd %CURDIR%
call copy_apps smv bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying fds pubs
echo.

cd %CURDIR%
call copy_pubs firebot  %FDS_PUBS_DIR%   %bundle_hostname% || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying smv pubs
echo.

cd %CURDIR%
call copy_pubs smokebot %SMV_PUBS_DIR% %bundle_hostname% || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo making bundle
echo.

cd %CURDIR%
call make_bundle bot %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %nightly%

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo uploading bundle
echo.

cd %CURDIR%
call upload_bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %nightly% %bundle_hostname% || exit /b 1

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo run_firebot usage
echo.
echo This script builds a windows bundle using the specified fds and smv repo revisions
echo or the revisions from the last firebot pass
echo.
echo Options:
echo -b - branch name [default: %BRANCH_NAME%]
echo -c - clone repos - required argument 
echo -h - display this message
echo -H - hostname where firebot and smokebot were run %default_hostname%
echo -f - firebot home directory %default_firebot_home%
echo -F - fds repo hash
echo -r - same as -b release
echo -s - smokebot home directory %default_smokebot_home%
echo -S - smv repo hash
exit /b 0
set bundle_hostname=
set bundle_firebot_home=
set bundle_smokebot_home=

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-b" (
   set BRANCH_NAME=%2
   set valid=1
   shift
 )
 if "%1" EQU "-c" (
   set clone=clone
   set valid=1
 )
 if "%1" EQU "-f" (
   set bundle_firebot_home=%2
   set valid=1
   shift
 )
 if "%1" EQU "-F" (
   set fds_hash=%2
   set valid=1
   shift
 )
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-H" (
   set bundle_hostname=%2
   set valid=1
   shift
 )
 if "%1" EQU "-r" (
   set BRANCH_NAME=release
   set valid=1
 )
 if "%1" EQU "-s" (
   set bundle_smokebot_home=%2
   set valid=1
   shift
 )
 if "%1" EQU "-S" (
   set smv_hash=%2
   set valid=1
   shift
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b 1
 )
if not (%1)==() goto getopts
exit /b 0

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
