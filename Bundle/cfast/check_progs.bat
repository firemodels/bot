@echo off
setlocal
set error=0
call :check_progs gawk       || set error=1
call :check_progs git        || set error=1
call :check_progs wzzip      || set error=1
call :check_progs wzipse32   || set error=1

goto eof

::-------------------------------
:check_progs
::-------------------------------
set prog=%1
where %prog% > Nul 2>&1
if %errorlevel% == 0 echo %prog% installed
if NOT %errorlevel% == 0 echo ***error: %prog% not installed
if NOT %errorlevel% == 0 exit /b 1
exit /b 0

:eof

if %error% == 1 exit /b 1
exit /b 0
