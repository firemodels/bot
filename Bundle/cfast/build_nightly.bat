@echo off
setlocal

set cfastrevision=latest
set smvrevision=latest
set upload=0
set clone=

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

if NOT %cfastrevision% == latest goto endif1
  set error=0
  set smvhash_file=%userprofile%\.cfast\PDFS\SMV_HASH
  set cfasthash_file=%userprofile%\.cfast\PDFS\CFAST_HASH

  echo ***Get cfast and smv repo hashes from the last cfastbot pass
  call get_hashrev > Nul 2>&1

  if not exist %smvhash_file% echo ***error: %smvhash_file% does not exist
  if not exist %smvhash_file% set error=1
  if not exist %cfasthash_file% echo ***error: %cfasthash_file% does not exist
  if not exist %cfasthash_file% set error=1
  if %error% == 1 exit /b

  set /p smvhash=<%smvhash_file%
  set /p cfasthash=<%cfasthash_file%
:endif1

set curdir=%CD%
cd ..\..\..
set gitroot=%CD%
set smvrepo=%gitroot%\smv
set cfastrepo=%gitroot%\cfast
set botrepo=%gitroot%\bot

cd %curdir%

echo ***Cloning cfast, nplot and smv repos
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
call make_cfast_bundle %cfastrevision% %smvrevision% %upload%

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
echo -C hash - cfast repo hash - if hash=latest then cfast and smv repos will be
echo           cloned using the revision from the latest cfastbot pass (default: latest)
echo -f - force erasing and cloning of cfast and smv repos without warning first
echo -h - display this message
echo -S hash - smv repo hash - if hash=latest then cfast and smv repos will be
echo           cloned using the revision from the latest cfastbot pass (default: latest)
echo -u -  upload bundle to a google drive directory
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-C" (
   set cfasthash=%2
   shift
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

