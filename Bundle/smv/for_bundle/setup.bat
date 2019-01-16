@echo off
set script_dir=%~dp0

title Smokeview Installer

:: before we do anything make sure this is a 64 bit PC

if defined PROGRAMFILES(X86) (
  echo.
) else (
  echo.
  echo *** Fatal error: 32 bit Windows detected.
  echo     Smokeview can only run on 64 bit systems.
  echo     Installation aborted.
  echo *** Press any key to continue.    ***
  pause>NUL
  goto abort
)

set auto_install=y
echo Automatically stop smokeview and install Smokeview in
set /p  auto_install="%SystemDrive%\Program Files\firemodels ?:   echo. (yes, no (default: yes))"
set auto_install=%auto_install:~0,1%

::*** check if smokeview is running

:begin
set progs_running=0
call :count_programs

if "%progs_running%" == "0" goto start
  echo smokeview needs to be stopped before proceeding with the installation
  echo Options:
  echo   Press 1 to stop smokeview (default: 1) 
  echo   Press any other key to quit installation

  set option=1
  if "%auto_install%" == "n" set /p  option="Option:"
  if "%option%" == "1" (
    call :stop_smokeview
    goto start
  )
  goto abort

::*** determine install directory

:start

echo.
type message.txt
echo.
echo Options:
echo    Press 1 to install for all users (default: 1)
echo    Press 2 to install for user %USERNAME%
echo    Press any other key to cancel the installation

set option=1
if "%auto_install%" == "n" set /p option="Option:"

set option_install=0
if "%option%" == "1" set option_install=1
if "%option%" == "2" set option_install=2
if "%option_install%" == "0" goto abort

set "BASEDIR=%SystemDrive%\Program Files"
if "%option_install%" == "2" set "BASEDIR=%userprofile%"

set subdir=firemodels
echo.
if "%auto_install%" == "n" set /p subdir="Enter directory to contain Smokeview (default: %subdir%):"

::*** start Smokeview installation

:install
set "INSTALLDIR=%BASEDIR%\%subdir%"

echo.
echo Installation directory: %INSTALLDIR%
echo.

set "SMV6=%INSTALLDIR%\SMV6"

set need_overwrite=0
if EXIST "%SMV6%" set need_overwrite=1

if "%need_overwrite%" == "0" goto else1 
  echo The directory %subdir%\SMV6 exists. 
  set option=n
  if "%auto_install%" == "y" set option=y  
  if "%auto_install%" == "n" set /p option="Do you wish to overwrite it? (yes, no (default: no)):"
  goto endif1
:else1
  set option=y
  if "%auto_install%" == "n" set /p option="Do you wish to proceed? (yes, no, (default: yes)):"
:endif1

set option=%option:~0,1%
if "x%option%" == "xy" goto proceed
if "x%option%" == "xY" goto proceed
goto begin

:proceed

echo.

if NOT exist "%SMV6%" goto skip_remove_smv6
echo *** Removing %SMV6%
rmdir /S /Q "%SMV6%"
:skip_remove_smv6

:: copy files to new installation

echo.
echo *** Copying installation files to %INSTALLDIR%
if NOT EXIST "%INSTALLDIR%" mkdir "%INSTALLDIR%" > Nul
xcopy /E /I /H /Q SMV6 "%SMV6%"     > Nul
echo        copy complete

echo *** Removing previous Smokeview entries from the system and user path.
call "%SMV6%\set_path.exe" -u -m -b -r "firemodels\SMV6" >Nul
call "%SMV6%\set_path.exe" -s -m -b -r "firemodels\SMV6" >Nul

echo *** Setting up PATH variable.

if NOT "%option_install%" == "1" goto skip_systempath
  call "%SMV6%\set_path.exe" -s -m -f "%SMV6%"     > Nul
  goto after_setpath
:skip_systempath

call "%SMV6%\set_path.exe" -u -m -f "%SMV6%"     > Nul
:after_setpath

:: ------------- file association -------------
echo *** Associating the .smv file extension with smokeview.exe

ftype smvDoc="%SMV6%\smokeview.exe" "%%1" >Nul
assoc .smv=smvDoc>Nul


echo.
echo *** Press any key, then reboot to complete the installation.  ***
pause>NUL
goto eof

:-------------------------------------------------------------------------
:----------------------subroutines----------------------------------------
:-------------------------------------------------------------------------

:-------------------------------------------------------------------------
:count_programs  
:-------------------------------------------------------------------------
call :count smokeview
exit /b

:-------------------------------------------------------------------------
:stop_smokeview  
:-------------------------------------------------------------------------
:: remove old installation

if NOT "%smokeview_count%" == "0" (
  echo *** Stopping smokeview
  taskkill /F /IM smokeview.exe >Nul 2>Nul
)
exit /b

:-------------------------------------------------------------------------
:count
:-------------------------------------------------------------------------
set progbase=%1
set prog=%progbase%.exe
set countvar=%progbase%_count
set stringvar=%progbase%_string

tasklist | find /c "%prog%" > count.txt
set /p count%=<count.txt
erase count.txt

set string=
if NOT "%count%" == "0" set string=%progbase%
if NOT "%count%" == "0" set progs_running=1

set %countvar%=%count%
set %stringvar%=%string%

exit /b

:abort
echo Smokeview installation aborted.
echo Press any key to finish
pause > Nul

:eof
exit