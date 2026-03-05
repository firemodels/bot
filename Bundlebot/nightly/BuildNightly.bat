@echo off
:: nightly bundles are uploaded to the firemodels test repo,
:: release bundles are uploaded to the users test repo 

if not exist %userprofile%\.bundle mkdir %userprofile%\.bundle
set BNCURDIR=%CD%

set UPLOAD_BUNDLE=
set FDS_TAG=
set SMV_TAG=
set LOGFILE=%userprofile%\.bundle\logfile.txt
set EMAILTO=
set ONLY_INSTALLER=0
set USE_CURRENT=

::*** parse command line arguments
call :GETOPTS %*

set DOWNLOADOWNER=firemodels
set UPLOADOWNER=firemodels
if "x%IS_RELEASE%" == "x1" set UPLOADOWNER=%username%
if "x%UPLOAD_BUNDLE%" == "x2" set UPLOADOWNER=%username%

if "x%STOPSCRIPT%" == "x" goto endif1
  set STOPSCRIPT=
  exit /b 1
:endif1

set NIGHTLY=yes
if "x%IS_RELEASE%" == "x1" set NIGHTLY=no

set BUNDLESCRIPTDIR=%CD%
cd ..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\bot
set BOTREPO=%CD%
set GAWK=%BOTREPO%\scripts\bin\gawk.exe

if exist %REPOROOT%\webpages goto endif2
  echo ***error: the webpages repo does not exist
  cd %BUNDLESCRIPTDIR%
  exit /b 1
:endif2

set EMAIL=%BOTREPO%\Scripts\email_insert.bat
set EMAILEXE=%userprofile%\bin\mailsend.exe
if "x%EMAILTO%" == "x" goto endif3
  if exist %EMAILEXE% goto endif3
    echo ***warning: email program %EMAILEXE% does not exist
    set EMAILTO=
:endif3

if %ONLY_INSTALLER% == 1 goto skip1
:: bring the webpages and wiki repos up to date
echo.
echo ***updating web and wiki repos
echo.
cd %REPOROOT%\bot\Scripts
call update_repos -w > Nul
:skip1

cd %BUNDLESCRIPTDIR%

:: create the bundle

if "x%IS_RELEASE%" == "x" goto else4
:: this is a release bundle - hash and revisions obtained from config.bat (invoked in BuildRelease.bat)
  set FDS_HASH_BUNDLER=%BUNDLE_FDS_HASH%
  set SMV_HASH_BUNDLER=%BUNDLE_SMV_HASH%
  set FDS_REVISION_BUNDLER=%BUNDLE_FDS_TAG%
  set FDS_TAG=%BUNDLE_FDS_TAG%
  set SMV_REVISION_BUNDLER=%BUNDLE_SMV_TAG%
  set SMV_TAG=%BUNDLE_SMV_TAG%
  goto endif4
:else4
:: this is a nightly bundle - hash and revisions obtained from latest firebot pass
  call get_hash_revisions.bat %USE_CURRENT% || exit /b 1
  set /p FDS_HASH_BUNDLER=<output\FDS_HASH
  set /p SMV_HASH_BUNDLER=<output\SMV_HASH
  set /p FDS_REVISION_BUNDLER=<output\FDS_REVISION
  set /p SMV_REVISION_BUNDLER=<output\SMV_REVISION
  erase output\FDS_HASH
  erase output\SMV_HASH
  erase output\FDS_REVISION
  erase output\SMV_REVISION
:endif4

echo.                                                         > %LOGFILE%
echo ***building bundle using:                               >> %LOGFILE%
echo.                                                        >> %LOGFILE%
if "x%FDS_REVISION_BUNDLER%" == "x" goto skip_fdsrev
  echo             FDS revision: %FDS_REVISION_BUNDLER%      >> %LOGFILE%
:skip_fdsrev

if "x%FDS_HASH_BUNDLER%" == "x" goto skip_fdshash
echo            FDS repo hash: %FDS_HASH_BUNDLER%            >> %LOGFILE%
:skip_fdshash

if "x%FDS_TAG%" == "x" goto skip_fdstag
echo             FDS repo tag: %FDS_TAG%                     >> %LOGFILE%
:skip_fdstag

if "x%SMV_REVISION_BUNDLER%" == "x" goto skip_smvrev
  echo             smv revision: %SMV_REVISION_BUNDLER%      >> %LOGFILE%
:skip_smvrev

if "x%SMV_HASH_BUNDLER%" == "x" goto skip_smvhash
echo            SMV repo hash: %SMV_HASH_BUNDLER%            >> %LOGFILE%
:skip_smvhash

if "x%SMV_TAG%" == "x" goto skip_smvtag
echo             SMV repo tag: %SMV_TAG%                     >> %LOGFILE%
:skip_smvtag

if NOT "%EMAILTO%" == "" (
  echo                    email: %EMAILTO%                   >> %LOGFILE%
)
echo.                                                        >> %LOGFILE%

type %LOGFILE%

if %ONLY_INSTALLER% == 1 goto skip2
:: clone fds and smv repos 
call clone_repos %FDS_HASH_BUNDLER% %SMV_HASH_BUNDLER%  || exit /b 1

echo ***building apps

cd %BUNDLESCRIPTDIR%
call make_apps         || exit /b 1
:skip2

echo ***copying fds apps
cd %BUNDLESCRIPTDIR%
call copy_apps fds || exit /b 1

echo ***copying smv apps

cd %BUNDLESCRIPTDIR%
call copy_apps smv || exit /b 1

echo ***copying fds pubs

cd %BUNDLESCRIPTDIR%
call copy_pubs firebot  %DOWNLOADOWNER% || exit /b 1

echo ***copying smv pubs

cd %BUNDLESCRIPTDIR%
call copy_pubs smokebot %DOWNLOADOWNER% || exit /b 1

echo ***making bundle

cd %BUNDLESCRIPTDIR%
call make_bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %NIGHTLY%
set HAVEVIRUS=%ERRORLEVEL%

cd %BUNDLESCRIPTDIR%

if %HAVEVIRUS% == 2 echo ***warning: a virus scanner was not bound, the bundle was not scanned
if %HAVEVIRUS% == 1 echo ***error: a virus was found in the bundle
if %HAVEVIRUS% == 1 echo bundle was built but not uploaded
if %HAVEVIRUS% == 1 goto skip_upload
if %HAVEVIRUS% == 0 echo ***no viruses were found in the bundle ***
if "x%UPLOAD_BUNDLE%" == "x" goto skip_upload
  echo ***uploading bundle

  set filelist=%TEMP%\fds_smv_files_win.out
  gh release view FDS_TEST -R github.com/%UPLOADOWNER%/test_bundles | grep FDS | grep SMV | grep win | %GAWK% "{print $2}" > %filelist%
  for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset FDS_TEST -R github.com/%UPLOADOWNER%/test_bundles %%A -y
  erase %filelist%

  set /p basename=<%TEMP%\fds_smv_basename.txt

  set fullfilebase=%userprofile%\.bundle\bundles\%basename%

  echo gh release upload FDS_TEST %fullfilebase%.exe -R github.com/%UPLOADOWNER%/test_bundles --clobber
       gh release upload FDS_TEST %fullfilebase%.exe -R github.com/%UPLOADOWNER%/test_bundles --clobber

  echo gh release upload FDS_TEST %BNCURDIR%\output\%basename%_manifest.html -R github.com/%UPLOADOWNER%/test_bundles --clobber
       gh release upload FDS_TEST %BNCURDIR%\output\%basename%_manifest.html -R github.com/%UPLOADOWNER%/test_bundles --clobber
:skip_upload

if "x%EMAILTO%" == "x" goto endif5
  call %EMAIL% %EMAILTO% "PC bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% created on %COMPUTERNAME%" %LOGFILE%
:endif5

goto eof


::-----------------------------------------------------------------------
:USAGE
::-----------------------------------------------------------------------

echo.
echo run_bundlebot usage
echo.
echo This script builds FDS and Smokeview apps and generates a bundle using either the
echo specified fds and smv repo revisions or revisions from the latest firebot pass.
echo.
echo Options:
echo -C - build apps using current revision
echo -h - display this message
echo -I - only build installer, assume repos are already cloned and apps are already built
echo -m mailtto - send email to mailto
echo -R - create a release bundle using settings in ..\release\config.bat
echo -u - upload bundle to %username%
echo -U - upload bundle to %UPLOADOWNER%
exit /b 0

::-----------------------------------------------------------------------
:GETOPTS
::-----------------------------------------------------------------------
 set STOPSCRIPT=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 
 if "%1" EQU "-C" (
   set USE_CURRENT=-C
   set valid=1
   shift
 )
 if "%1" EQU "-h" (
   call :USAGE
   set STOPSCRIPT=1
   exit /b
 )
 if "%1" EQU "-I" (
   set ONLY_INSTALLER=1
   set valid=1
 )
 if "%1" EQU "-m" (
   set EMAILTO=%2
   set valid=1
   shift
 )
 if "%1" EQU "-R" (
   set IS_RELEASE=1
   set valid=1
   shift
 )
 if "%1" EQU "-u" (
   set UPLOAD_BUNDLE=2
   set valid=1
 )
 if "%1" EQU "-U" (
   set UPLOAD_BUNDLE=1
   set valid=1
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :USAGE
   set STOPSCRIPT=1
   exit /b 1
 )
if not (%1)==() goto GETOPTS
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

cd %BNCURDIR%
exit /b 0
