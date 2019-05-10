@echo off
:: usage: 
::  smv_web -host hostname -scriptdir scriptdir -casedir casedir casename

set stopscript=0
call %userprofile%\web_setup
call :getopts %*
if %stopscript% == 1 (
  exit /b
)

set command=plink %hostname%:%scriptdir%/runsmv.sh %casedir% %casename%
echo command=%command%


goto eof

:getopts
 if (%1)==() exit /b
 set valid=0
 set firstchar=%arg:~0,1%
 set casename=%1
 if /I "%1" EQU "-host" (
   set valid=1
   set hostname=%2
   shift
 )
 if /I "%1" EQU "-casedir" (
   set casedir=%2
   set valid=1
   shift
 )
 if /I "%1" EQU "-scriptdir" (
   set scriptdir=%2
   set valid=1
   shift
 )
 if /I "%1" EQU "-help" (
   call :usage
   set stopscript=1
   exit /b
 )
 shift
 if %valid% == 0 (
   if %firstchar% == "-" (
     echo.
     echo ***Error: the input argument %arg% is invalid
     echo.
     echo Usage:
     call :usage
     set stopscript=1
     exit /b
   )
 )
if not (%1)==() goto getopts
exit /b

:usage  
echo run_smokebot [options]
echo. 
echo -help                - display this message
echo -host hostname       - computer where smokeview will be run
echo                        (default: %hostname%)
echo -casedir directory   - directory where case is located
echo                        (default: %casedir%)
echo -scriptdir directory - directory where scripts located
echo                        (default: %scriptdir%)
exit /b

:normalise
set temparg=%~f1
exit /b

:eof

