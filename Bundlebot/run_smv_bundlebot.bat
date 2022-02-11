@echo off

set clone=
set bundle_hostname=
set bundle_firebot_home=
set bundle_smokebot_home=
set SMV_HASH=
set SMV_TAG=
set BRANCH_NAME=nightly
set configscript=%userprofile%\.bundle\bundle_config.bat
set upload_bundle=1

:: define defaults

if NOT exist %configscript% goto skip_config
  call %configscript%
:skip_config

:: define default strings for the usage script
set default_hostname=
set default_smokebot_home=

if x"%bundle_hostname%" == "x" goto def1
  set default_hostname=[default: %bundle_hostname%]
:def1

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

set nightly=rls

::--- make sure hostname is defined

if NOT x"%bundle_hostname%" == "x" goto error1
  echo ****error:  hostname where firebot and smokebot was run not defined
  set abort=1
:error1

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


set SMV_REVISION_BUNDLER=%SMV_HASH%
if "x%SMV_TAG%" == "x" goto endif4
  set SMV_REVISION_BUNDLER=%SMV_TAG%
:endif4
set SMV_HASH_BUNDLER=%SMV_HASH%

cd %CURDIR%

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Building bundle using:
echo.
if "x%SMV_REVISION_BUNDLER%" == "x" goto skip_smvrev
  echo             smv revision: %SMV_REVISION_BUNDLER%
:skip_smvrev

if "x%SMV_HASH_BUNDLER%" == "x" goto skip_smvhash
echo            SMV repo hash: %SMV_HASH_BUNDLER%
:skip_smvhash

if "x%SMV_TAG%" == "x" goto skip_smvtag
echo             SMV repo tag: %SMV_TAG%
:skip_smvtag

echo  smokebot home directory: %bundle_smokebot_home%
echo.

if "x%clone%" == "xclone" goto skip_warning
  echo.
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo You are about to erase and then clone the smv repos.
  echo Press any key to continue or CTRL c to abort.
  echo To avoid this warning, use the -c option on the command line
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo.
  pause >Nul
:skip_warning

call clone_smv_repo %SMV_HASH_BUNDLER% %BRANCH_NAME% %SMV_TAG% || exit /b 1

:: define revisions if hashes were specified on the command line

call :cd_repo %basedir%\smv %BRANCH_NAME% || exit /b 1
git describe --dirty --long > temp1
set /p SMV_REVISION_BUNDLER=<temp1
erase temp1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Building apps
echo.

cd %CURDIR%
call make_smv_apps         || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo.
echo Copying smv apps
echo.

cd %CURDIR%
call copy_apps smv bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo making bundle
echo.

cd %CURDIR%
cd ..\Bundle\smv\scripts
call make_bundle 

cd %CURDIR%

if "x%upload_bundle%" == "x" goto skip_upload
  echo.
  echo ------------------------------------------------------
  echo ------------------------------------------------------
  echo uploading bundle
  echo.
  call upload_smv_bundle %SMV_REVISION_BUNDLER% %nightly% %bundle_hostname% || exit /b 1
:skip_upload

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo run_smv_bundlebot usage
echo.
echo This script builds FDS and Smokeview apps and generates a bundle using either the
echo specified fds and smv repo revisions or revisions from the latest firebot pass.
echo.
echo Options:
echo -b - branch name [default: %BRANCH_NAME%]
echo -c - bundle without warning about cloning/erasing fds and smv repos 
echo -h - display this message
echo -H - host where firebot and smokebot were run %default_hostname%
echo -r - same as -b release or -R release
echo -R - branch name [default: %BRANCH_NAME%]
echo -s - smokebot home directory %default_smokebot_home%
echo -S - smv repo hash
echo -U - do not upload bundle
echo -Y smvtag - tag the smv repo using smvtag
exit /b 0
set bundle_hostname=
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
 if "%1" EQU "-C" (
   set CUSTOM_MANUALS=custom
   set valid=1
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
 if "%1" EQU "-R" (
   set BRANCH_NAME=%2
   set valid=1
   shift
 )
 if "%1" EQU "-s" (
   set bundle_smokebot_home=%2
   set valid=1
   shift
 )
 if "%1" EQU "-S" (
   set SMV_HASH=%2
   set valid=1
   shift
 )
 if "%1" EQU "-U" (
   set upload_bundle=
   set valid=1
 )
 if "%1" EQU "-Y" (
   set SMV_TAG=%2
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
