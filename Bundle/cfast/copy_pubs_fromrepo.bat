@echo off
setlocal

set manuals_dir=%userprofile%\FireModels_fork\cfast\Manuals
set THISDIR=%CD%
cd ..\..\..\cfast\Manuals
set local_dir=%CD%
cd %THISDIR%

set PDFS=%userprofile%\.cfast\PDFS

call :getopts %*
if x%stopscript% == x1 exit /b

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

call :copy_file CFAST_Tech_Ref
call :copy_file CFAST_Users_Guide
call :copy_file CFAST_Validation_Guide
call :copy_file CFAST_Configuration_Guide
call :copy_file CFAST_CData_Guide

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set file=%1
set fromfile=%manuals_dir%\%file%\%file%.pdf
set tofile=%PDFS%\%file%.pdf
if exist %tofile% erase %tofile%
if exist %fromfile% copy %fromfile% %tofile%  > Nul 2>&1
if not exist %fromfile% echo ***error: %fromfile% does not exist
if not exist %fromfile% exit /b 
if NOT exist %tofile% echo error***: %file%.pdf failed to copy
if exist %tofile% echo %file%.pdf copied
exit /b 1

cd %THISDIR%

goto eof

::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo copy_pubs_fromrepo usage
echo.
echo This script copies manuals from a cfast repo to %userprofile%\.bundle\PDFS
echo.
echo Options:
echo -f  root - copy manuals from %userprofile%\root\cfast\Manuals (default: root=FireModels_fork)
echo -h  display this message
echo -l - copy manuals from %local_dir%
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-f" (
   set manuals_dir=%userprofile%\%2\cfast\Manuals
   shift
   set valid=1
 )
 if "%1" EQU "-l" (
 
   set valid=1
   cd ..\..\..\cfast\Manuals
   set manuals_dir=%CD%
   cd %THISDIR%
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
