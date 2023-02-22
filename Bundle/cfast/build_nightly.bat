@echo off
setlocal

set clone=

call :getopts

if "x%clone%" == "xclone" goto skip_warning
  echo.
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo You are about to erase and then clone the cfast and smv repos.
  echo Press any key to continue or CTRL c to abort.
  echo To avoid this warning, use the -c option on the command line
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo.
  pause >Nul
:skip_warning

set error=0
set smvhash_file=%userprofile%\.cfast\PDFS\SMV_HASH
set cfasthash_file=%userprofile%\.cfast\PDFS\CFAST_HASH

echo ***Get cfast and smv repo hashes from last cfastbot pass
call get_hash > Nul 2>&1

if not exist %smvhash_file% echo ***error: %smvhash_file% does not exist
if not exist %smvhash_file% set error=1
if not exist %cfasthash_file% echo ***error: %cfasthash_file% does not exist
if not exist %cfasthash_file% set error=1
if %error% == 1 exit /b

set /p smvhash=<%smvhash_file%
set /p cfasthash=<%cfasthash_file%

set curdir=%CD%
cd ..\..\..
set gitroot=%CD%
set smvrepo=%gitroot%\smv
set cfastrepo=%gitroot%\cfast
set botrepo=%gitroot%\bot

cd %curdir%

echo ***Cloning cfast, nplot and smv repos
echo cfast hash: %cfasthash%
echo   smv hash: %smvhash%
call clone_repos %cfasthash% %smvhash% nightly  > Nul 2>&1

cd %curdir%
echo.
call make_cfast_bundle

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo run_bundlebot usage
echo.
echo This script using the cfast and smv repo revisions from the latest cfastbot pass.
echo.
echo Options:
echo -c - bundle without warning about cloning/erasing cfast and smv repos 
echo -h - display this message
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-c" (
   set clone=clone
   set valid=1
 )
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
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

:eof

