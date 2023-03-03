@echo off

:: builds a cfast bundle using exising cfast and smv repos

set cfastrev=cfasttest
set smvrev=smvtest
set upload=0
set build_cedit=1
set only_installer=0
SETLOCAL

call :getopts %*

set THISDIR=%CD%

echo ***Building CFAST bundle
echo ***Setting up repos
cd ..\..\..
set GITROOT=%CD%
cd %THISDIR%

set CFASTREPO=%GITROOT%\cfast
set SCRIPTDIR=%CFASTREPO%\Utilities\for_bundle\scripts
set VSSTUDIO=%CFASTREPO%\Utilities\Visual_Studio

if %only_installer% == 1 goto only_installer
   cd %THISDIR%
   echo ***Cleaning CFAST bundle build directory
   git clean -dxf  > Nul 2>&1

   cd %CFASTREPO%
   echo ***Cleaning CFAST repo
   git clean -dxf  > Nul 2>&1
 
   cd %THISDIR%
   echo ***Restoring project configuration files 
   call Restore_vs_config %VSSTUDIO%  %THISDIR% %THISDIR%\out\stage1_config

   cd %THISDIR%
   call build_cfast_apps %build_cedit%

   echo .
   echo ***Building smokeview executables
   cd %THISDIR%\..\..\..\smv
   set smvrepo=%CD%

   cd %THISDIR%
   call build_smv_apps %smvrepo%

:only_installer
cd %THISDIR%
call build_cfast_installer %cfastrev% %smvrev% %upload% %build_cedit%

cd %THISDIR%
goto eof

::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo make_cfast_bundle usage
echo.
echo This script using the cfast and smv repo revisions from the latest cfastbot pass.
echo.
echo Options:
echo -C version - cfast version (default: cfasttest)
echo -E - skip Cedit build
echo -h - display this message
echo -S version - smv smokeview version (default: smvtest)
echo -u -  upload bundle to a google drive directory and to a Linux host
echo -U -  upload bundle to a Linux host
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-C" (
   set cfastrev=%2
   shift
   set valid=1
 )
 if "%1" EQU "-E" (
   set build_cedit=0
   set valid=1
 )
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-I" (
   set only_installer=1
   set valid=1
 )
 if "%1" EQU "-S" (
   set smvrev=%2
   shift
   set valid=1
 )
 if "%1" EQU "-u" (
   set upload=1
   shift
   set valid=1
 )
 if "%1" EQU "-U" (
   set upload=2
   shift
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


:eof