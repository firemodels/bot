@echo off

set tag=TEST
set "title=test"

call :getopts %*
if %stopscript% == 1 exit /b

gh release create --generate-notes %tag% %file% -t "%title%

goto eof

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-t" (
   set valid=1
   set tag=%1
 )
 if "%1" EQU "-T" (
   set valid=1
   set "title=%1"
 )
 if /I "%1" EQU "-f" (
   set valid=1
   set file=%1
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
if not (%1)==() goto getopts
exit /b 0

::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------
echo Add a Github release.  Assume script is run in repo where release is located.
echo Usage:
echo   add_release -f file -t tag -T "title"
echo.
echo Options:
echo -f file  - file to upload to a Github release
echo -h       - display this message%
echo -t tag   - add release file to tag (default: %tag%)
echo -T title - title of release (default: %title%)
exit /b 0

:eof