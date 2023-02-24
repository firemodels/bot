@echo off

:: builds a cfast bundle using either specified cfast and smv repo revisions or the revisions used in the latest
:: cfastbot pass 
setlocal

set cfasthash=latest
set smvhash=latest
set upload=0
set clone=
set build_cedit=1
set use_cfastbot_hash=0

call :getopts %*

if x%stopscript% == x1 exit /b

if "x%clone%" == "xclone" goto skip_warning
  echo.
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo You are about to erase and then clone the cfast and smv repos.
  echo Press any key to continue or CTRL c to abort.
  echo To avoid this warning, use the -f option on the command line
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo.
  pause >Nul
:skip_warning


if %use_cfastbot_hash% == 0 goto skip_gethash
  set error=0
  set smvhash_file=%userprofile%\.cfast\PDFS\SMV_HASH
  set cfasthash_file=%userprofile%\.cfast\PDFS\CFAST_HASH
  echo ***Get cfast and smv repo hashes from the last cfastbot pass
  call get_hash > Nul 2>&1
  if not exist %smvhash_file% echo ***error: %smvhash_file% does not exist
  if not exist %smvhash_file% set error=1
  if not exist %cfasthash_file% echo ***error: %cfasthash_file% does not exist
  if not exist %cfasthash_file% set error=1
  if %error% == 1 exit /b

  set /p smvhash=<%smvhash_file%
  set /p cfasthash=<%cfasthash_file%
:skip_gethash


set curdir=%CD%
cd ..\..\..
set gitroot=%CD%
set smvrepo=%gitroot%\smv
set cfastrepo=%gitroot%\cfast
set botrepo=%gitroot%\bot

cd %curdir%

echo ***Cloning cfast(%cfasthash%), nplot and smv repos(%smvhash%)
call clone_repos %cfasthash% %smvhash% nightly  > Nul 2>&1

set cfastrevision_file=%userprofile%\.cfast\PDFS\CFAST_REVISION
cd %cfastrepo%
git describe   --long | gawk -F"-" "{printf $1\"-\"$2}" > %cfastrevision_file%
set /p cfastrevision=<%cfastrevision_file%

set smvrevision_file=%userprofile%\.cfast\PDFS\SMV_REVISION
cd %smvrepo%
git describe   --long | gawk -F"-" "{printf $1\"-\"$2}" > %smvrevision_file%
set /p smvrevision=<%smvrevision_file%

echo       cfast hash: %cfasthash%
echo   cfast revision: %cfastrevision%
echo         smv hash: %smvhash%
echo     smv revision: %smvrevision%
if x%upload% == x1 echo upload installer: yes
if NOT x%upload% == x1 echo upload installer: no

cd %curdir%
echo.

set upload_arg=
if %upload% == 1 set upload_arg=-U
set build_cedit_arg=
if %build_cedit% == 0 set build_cedit_arg=-E
call make_cfast_bundle -C %cfastrevision% -S %smvrevision% %upload_arg% %build_cedit_arg%

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo build_bundle usage
echo.
echo This script builds a cfast bundle.
echo.
echo Options:
echo -B      - use cfast and smv commits from the latest cfastbot pass
echo -C hash - build bundle using cfast repo commit with hash 'hash' .
echo           If hash=latest then use most the recent commit (default: latest)
echo -E        skip Cedit build
echo -f      - force erasing and cloning of cfast and smv repos without warning first
echo -h      - display this message
echo -S hash - build bundle using smv repo commit with hash 'hash' .
echo           If hash=latest then use most the recent commit (default: latest)
echo -u      - upload bundle to a google drive directory
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-B" (
   set use_cfastbot_hash=1
   set valid=1
 )
 if "%1" EQU "-C" (
   set cfasthash=%2
   shift
   set valid=1
 )
 if "%1" EQU "-E" (
   set build_cedit=0
   set valid=1
 )
 if "%1" EQU "-f" (
   set clone=clone
   set valid=1
 )
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-S" (
   set smvhash=%2
   shift
   set valid=1
 )
 if "%1" EQU "-u" (
   set upload=1
   shift
   set valid=1
 )
 shift
  if x%cfasthash% == xlatest set smvhash=latest
  if x%smvhash% ==   xlatest set cfasthash=latest
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

