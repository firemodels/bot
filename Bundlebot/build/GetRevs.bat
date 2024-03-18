@echo off
:: This scripts obtains revisions and tags for a bundle.
set base_tag=6.9.0

set repos=fds smv cad exp fig out
set CURDIR=%CD%
set gitroot=%CURDIR%\..\..\..
cd %gitroot%
set gitroot=%CD%
cd %CURDIR%

for %%r in ( %repos%) do ( call :outrev %%r )
goto eof

:outrev
set rev=%1
if NOT EXIST %gitroot%\%rev% goto else1
   cd %gitroot%\%rev%
   git rev-parse --short HEAD > file.out
   set /p REVISION=<file.out

   echo %rev% | gawk "{print toupper($0)}" > file.out
   set /p REPO=<file.out
   call :TRIM %REPO% REPO

   set TAG=%REPO%-%base_tag%
   echo set BUNDLE_%REPO%_REVISION=%REVISION%
   echo set BUNDLE_%REPO%_TAG=%TAG%
   echo.
   goto endif1
:else1
   echo "***error: repo %gitroot%/%repo% does not exist"
:endif1
exit /b

:TRIM
SET %2=%1
exit /b

:eof
erase file.out
cd %CURDIR%
