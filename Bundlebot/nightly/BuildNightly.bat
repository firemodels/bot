@echo off
:: nightly bundles are uploaded to the firemodels test repo,
:: release bundles are uploaded to the users test repo 
set OWNER=%username%
if "x%is_release%" == "x" set OWNER=firemodels

if not exist %userprofile%\.bundle mkdir %userprofile%\.bundle
set CURDIR=%CD%

set upload_bundle=
set FDS_TAG=
set SMV_TAG=
set logfile=%userprofile%\.bundle\logfile.txt
set emailto=

::*** parse command line arguments
call :getopts %*

if "x%stopscript%" == "x" goto endif2
  set stopscript=
  exit /b 1
:endif2

set nightly=nightly
set pub_dir=

set BUNDLESCRIPTDIR=%CD%
cd ..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\bot
set botrepo=%CD%
set gawk=%botrepo%\scripts\bin\gawk.exe

if exist %REPOROOT%\webpages goto endif4
  echo ***error: the webpages repo does not exist
  cd %BUNDLESCRIPTDIR%
  exit /b 1
:endif4

set email=%botrepo%\Scripts\email_insert.bat
set emailexe=%userprofile%\bin\mailsend.exe
if "x%emailto%" == "x" goto endif5
  if exist %emailexe% goto endif5
    echo ***warning: email program %emailexe% does not exist
    set emailto=
:endif5

cd %REPOROOT%\webpages
set webpagesrepo=%CD%

cd ..
set basedir=%CD%

:: bring the webpages and wiki repos up to date
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo updating web and wiki repos
echo.
cd %REPOROOT%\bot\Scripts
call update_repos -w > Nul

cd %BUNDLESCRIPTDIR%

:: create the bundle

if x%is_release% == x goto else1
:: this is a release bundle - hash and revisions obtained from config.bat (invoked in BuildRelease.bat)
  set FDS_HASH_BUNDLER=%BUNDLE_FDS_HASH%
  set SMV_HASH_BUNDLER=%BUNDLE_SMV_HASH%
  set FDS_REVISION_BUNDLER=%BUNDLE_FDS_TAG%
  set FDS_TAG=%BUNDLE_FDS_TAG%
  set SMV_REVISION_BUNDLER=%BUNDLE_SMV_TAG%
  set SMV_TAG=%BUNDLE_SMV_TAG%
  goto endif1
:else1
:: this is a nightly bundle - hash and revisions obtained from latest firebot pass
  call get_hash_revisions.bat || exit /b 1
  set /p FDS_HASH_BUNDLER=<output\FDS_HASH
  set /p SMV_HASH_BUNDLER=<output\SMV_HASH
  set /p FDS_REVISION_BUNDLER=<output\FDS_REVISION
  set /p SMV_REVISION_BUNDLER=<output\SMV_REVISION
  erase output\FDS_HASH
  erase output\SMV_HASH
  erase output\FDS_REVISION
  erase output\SMV_REVISION
:endif1

echo.                                                         > %logfile%
echo ------------------------------------------------------  >> %logfile%
echo ------------------------------------------------------  >> %logfile%
echo Building bundle using:                                  >> %logfile%
echo.                                                        >> %logfile%
if "x%FDS_REVISION_BUNDLER%" == "x" goto skip_fdsrev
  echo             FDS revision: %FDS_REVISION_BUNDLER%      >> %logfile%
:skip_fdsrev

if "x%FDS_HASH_BUNDLER%" == "x" goto skip_fdshash
echo            FDS repo hash: %FDS_HASH_BUNDLER%            >> %logfile%
:skip_fdshash

if "x%FDS_TAG%" == "x" goto skip_fdstag
echo             FDS repo tag: %FDS_TAG%                     >> %logfile%
:skip_fdstag

if "x%SMV_REVISION_BUNDLER%" == "x" goto skip_smvrev
  echo             smv revision: %SMV_REVISION_BUNDLER%      >> %logfile%
:skip_smvrev

if "x%SMV_HASH_BUNDLER%" == "x" goto skip_smvhash
echo            SMV repo hash: %SMV_HASH_BUNDLER%            >> %logfile%
:skip_smvhash

if "x%SMV_TAG%" == "x" goto skip_smvtag
echo             SMV repo tag: %SMV_TAG%                     >> %logfile%
:skip_smvtag

if NOT "%emailto%" == "" (
  echo                    email: %emailto%                   >> %logfile%
)
echo.                                                        >> %logfile%

type %logfile%

:: clone fds and smv repos 
call clone_repos %FDS_HASH_BUNDLER% %SMV_HASH_BUNDLER%  || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Building apps
echo.

cd %BUNDLESCRIPTDIR%
call make_apps         || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying fds apps
echo.
cd %BUNDLESCRIPTDIR%
call copy_apps fds bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying smv apps
echo.

cd %BUNDLESCRIPTDIR%
call copy_apps smv bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying fds pubs
echo.

cd %BUNDLESCRIPTDIR%
call copy_pubs firebot  %OWNER% || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying smv pubs
echo.

cd %BUNDLESCRIPTDIR%
call copy_pubs smokebot %OWNER% || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo making bundle
echo.

cd %BUNDLESCRIPTDIR%
call make_bundle bot %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %nightly%
set HAVEVIRUS=%ERRORLEVEL%

cd %BUNDLESCRIPTDIR%

if %HAVEVIRUS% == 2 echo ***warning: a virus scanner was not bound, the bundle was not scanned
if %HAVEVIRUS% == 1 echo ***error: a virus was found in the bundle
if %HAVEVIRUS% == 1 echo bundle was built but not uploaded
if %HAVEVIRUS% == 1 goto skip_upload
if %HAVEVIRUS% == 0 echo ***a virus was not found in the bundle ***
if "x%upload_bundle%" == "x" goto skip_upload
  echo.
  echo ------------------------------------------------------
  echo ------------------------------------------------------
  echo uploading bundle
  echo.

  set filelist=%TEMP%\fds_smv_files_win.out
  gh release view FDS_TEST -R github.com/%OWNER%/test_bundles | grep FDS | grep SMV | grep win | %gawk% "{print $2}" > %filelist%
  for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset FDS_TEST -R github.com/%OWNER%/test_bundles %%A -y
  erase %filelist%

  set /p basename=<%TEMP%\fds_smv_basename.txt

  set fullfilebase=%userprofile%\.bundle\bundles\%basename%

  echo gh release upload FDS_TEST %fullfilebase%.exe -R github.com/%OWNER%/test_bundles --clobber
       gh release upload FDS_TEST %fullfilebase%.exe -R github.com/%OWNER%/test_bundles --clobber

  echo gh release upload FDS_TEST %CURDIR%\output\%basename%_manifest.html -R github.com/%OWNER%/test_bundles --clobber
       gh release upload FDS_TEST %CURDIR%\output\%basename%_manifest.html -R github.com/%OWNER%/test_bundles --clobber
:skip_upload

if "x%emailto%" == "x" goto endif6
  call %email% %emailto% "PC bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% created on %COMPUTERNAME%" %logfile%
:endif6

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo run_bundlebot usage
echo.
echo This script builds FDS and Smokeview apps and generates a bundle using either the
echo specified fds and smv repo revisions or revisions from the latest firebot pass.
echo.
echo Options:
echo -h - display this message
echo -m mailtto - send email to mailto
echo -U - upload bundle
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-m" (
   set emailto=%2
   set valid=1
   shift
 )
 if "%1" EQU "-U" (
   set upload_bundle=1
   set valid=1
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

cd %CURDIR%
exit /b 0
