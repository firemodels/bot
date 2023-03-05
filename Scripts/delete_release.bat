@echo off

set tag=TEST

call :getopts %*
if %stopscript% == 1 exit /b
gh release delete %tag% -y

goto eof

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-t" (
   set valid=1
   set tag=%2
   shift
 )
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b 1
 )
 shift
if not (%1)==() goto getopts
exit /b 0

::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------
echo Delete a Github release.  Assume script is run in repo where release is located.
echo Usage:
echo   delete_release -t tag
echo.
echo Options:
echo -h - display this message%
echo -t tag - delete release with tag tag (default: %tag%)
exit /b 0

:eof