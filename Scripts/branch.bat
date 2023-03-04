@echo off
set CUR=%CD%
set showrepos=bot cad cfast cor exp fds fig out radcal smv
set setrepos=bot fds smv
set BRANCH=master
set SHOW=1

set FMROOT=
cd ..\..
set FMROOT=%CD%
cd %CUR%

call :getopts %*
if %stopscript% == 1 exit /b

if %SHOW% == 1 set repos=%showrepos%
if %SHOW% == 0 set repos=%setrepos%

for %%x in ( %repos% ) do ( 
   cd %FMROOT%\%%x
   echo %%x
   if %SHOW% == 1 git branch 
   if %SHOW% == 0 git checkout %BRANCH% 
)

cd %CUR%
goto eof

::---------------------------------------
:usage
::---------------------------------------
echo Show or Set branches
echo.
echo Options:"
echo -h - display this message
echo -b branch - set branch to branch (default: %BRANCH%)
echo -d - display branch on %showrepos% repos
echo -s - set branch on %setrepos% repos"
exit /b

::---------------------------------------
:getopts
::---------------------------------------
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-b" (
   set valid=1
   set BRANCH=%1
 )
 if /I "%1" EQU "-d" (
   set SHOW=1
   set valid=1
 )
 if /I "%1" EQU "-s" (
   set SHOW=0
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
   exit /b
 )
if not (%1)==() goto getopts
exit /b


:eof
