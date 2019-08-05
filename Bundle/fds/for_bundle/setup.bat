@echo off
set script_dir=%~dp0

title FDS and Smokeview Installer

:: before we do anything make sure this is a 64 bit PC

if defined PROGRAMFILES(X86) (
  echo.
) else (
  echo.
  echo *** Fatal error: 32 bit Windows detected.
  echo     FDS and Smokeview can only run on 64 bit systems.
  echo     Installation aborted.
  echo *** Press any key to continue.    ***
  pause>NUL
  goto abort
)

:: form extraction directory

set /p basename=<firemodels\basename.txt
set EXTRACTDIR=%userprofile%\%basename%
for /f "tokens=* delims= " %%A in ('echo %EXTRACTDIR% ') do set EXTRACTDIR=%%A
set EXTRACTDIR=%EXTRACTDIR:~0,-1%

:quest1
set auto_install=y
type firemodels\message.txt
echo.
echo Install in %SystemDrive%\Program Files\firemodels and stop any 
echo instances of fds, smokeview, mpiexec, and/or hydra_service?
echo.
echo  yes - standard installation (use default answer for all questions)
echo   no - customize installation (install to a different location)
::echo extract - extract to: %EXTRACTDIR%
::echo           and quit 
echo quit - stop installation
echo.
set /p  auto_install="yes, no or quit?:"
call :get_yesnoextract %auto_install% auto_install quest1_repeat
if "%quest1_repeat%" == "1" goto quest1
if "%quest1_repeat%" == "2" goto abort
if "%quest1_repeat%" == "3" goto extract

::*** check if fds and smokeview are running

:begin
set progs_running=0
call :count_programs

if "%progs_running%" == "0" goto start
  if "%auto_install%" == "y" goto skip_remove
  echo The following program(s) need to be stopped before proceeding with the installation:
  echo %fds_string% %smokeview_string% %mpiexec_string% %hydra_service_string%
  echo.
  echo Options:
  echo   Press 1 to stop these programs (default: 1) 
  echo   Press any other key to quit installation
  :skip_remove

  set option=1
  if "%auto_install%" == "n" set /p  option="Option:"
  if "%option%" == "1" (
    call :stop_programs
    goto start
  )
  goto abort

::*** determine install directory

:start

if "%auto_install%" == "y" goto skip_loc
echo.
type firemodels\message.txt
echo.
echo Options:
echo    Press 1 to install for all users (default: 1)
echo    Press 2 to install for user %USERNAME%
echo    Press any other key to cancel the installation
:skip_loc

set option=1
if "%auto_install%" == "n" set /p option="Option:"

set option_install=0
if "%option%" == "1" set option_install=1
if "%option%" == "2" set option_install=2
if "%option_install%" == "0" goto abort

set "BASEDIR=%SystemDrive%\Program Files"
if "%option_install%" == "2" set "BASEDIR=%userprofile%"

set subdir=firemodels
set "INSTALLDIR=%BASEDIR%\%subdir%"
echo.
if "%auto_install%" == "n" set /p INSTALLDIR="Enter FDS/Smokeview root directory (default: %INSTALLDIR%):"

::*** start installation of FDS and Smokeview

:install

echo.
echo Installation directory: %INSTALLDIR%
echo.

set "SMV6=%INSTALLDIR%\SMV6"
set "FDS6=%INSTALLDIR%\FDS6"
set "CFAST=%INSTALLDIR%\cfast"

set need_overwrite=0
if EXIST "%FDS6%" set need_overwrite=1 
if EXIST "%SMV6%" set need_overwrite=1

:quest2
if "%need_overwrite%" == "0" goto else1 
  if "%auto_install%" == "n" echo The directories %subdir%\FDS6 and/or %subdir%\SMV6 exist. 
  set option=n
  if "%auto_install%" == "y" set option=y 
  if "%auto_install%" == "n" set /p option="Do you wish to overwrite them? (yes, no (default: no)):"
  goto endif1
:else1
  set option=y
  if "%auto_install%" == "n" set /p option="Do you wish to proceed? (yes, no, (default: yes)):"
:endif1

set option=%option:~0,1%
call :get_yesno %option% option quest2_repeat
if "%quest2_repeat%" == "1" goto quest2

if "x%option%" == "xy" goto proceed
goto begin

:proceed

set "DOCDIR=%INSTALLDIR%\FDS6\Documentation"
set "UNINSTALLDIR=%INSTALLDIR%\FDS6\Uninstall"
 
if NOT exist "%FDS6%" goto skip_remove_fds6
echo *** Removing %FDS6%
rmdir /S /Q "%FDS6%"
:skip_remove_fds6

if NOT exist "%SMV6%" goto skip_remove_smv6
echo *** Removing %SMV6%
rmdir /S /Q "%SMV6%"
:skip_remove_smv6

:: copy files to new installation

echo.
echo *** Copying installation files to %INSTALLDIR%
if NOT EXIST "%INSTALLDIR%" mkdir "%INSTALLDIR%" > Nul
xcopy /E /I /H /Q firemodels\FDS6 "%FDS6%"     > Nul
xcopy /E /I /H /Q firemodels\SMV6 "%SMV6%"     > Nul

set "filepath=%FDS6%\bin\fds.exe%"
call :is_file_copied fds.exe

set "filepath=%SMV6%\smokeview.exe"
call :is_file_copied smokeview.exe

set "filepath=%FDS6%\bin\mpi\mpiexec.exe"
call :is_file_copied mpiexec.exe

echo        copy complete

echo *** Removing previous FDS/Smokeview entries from the system and user path.
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "nist\fds" >Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -b -r "FDS\FDS5" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "FDS\FDS5" >Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -b -r "FDS\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "FDS\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "firemodels\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "firemodels\SMV6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -b -r "firemodels\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -b -r "firemodels\SMV6" >Nul

:: ------------ create aliases ----------------

set numcoresfile="%TEMP%\numcoresfile"

:: ------------ setting up path ------------

echo *** Setting up PATH variable.

if NOT "%option_install%" == "1" goto skip_systempath
  call "%UNINSTALLDIR%\set_path.exe" -s -m -f "%FDS6%\bin" > Nul
  call "%UNINSTALLDIR%\set_path.exe" -s -m -f "%SMV6%"     > Nul
  goto after_setpath
:skip_systempath

call "%UNINSTALLDIR%\set_path.exe" -u -m -f "%FDS6%\bin" > Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -f "%SMV6%"     > Nul

:after_setpath

:: ------------- file association -------------
echo *** Associating the .smv file extension with smokeview.exe

ftype smvDoc="%SMV6%\smokeview.exe" "%%1" >Nul
assoc .smv=smvDoc>Nul

set FDSSTART=%ALLUSERSPROFILE%\Start Menu\Programs\FDS6

:: ------------- start menu shortcuts ---------------
echo *** Adding document shortcuts to the Start menu.
if exist "%FDSSTART%" rmdir /q /s "%FDSSTART%"

mkdir "%FDSSTART%"

copy "%DOCDIR%\FDS_on_the_Web\Official_Web_Site.url"     "%FDSSTART%\FDS Home Page.url"         > Nul

mkdir "%FDSSTART%\Guides and Release Notes"
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\FDS Config Management Plan.lnk"          /T:"%DOCDIR%\Guides_and_Release_Notes\FDS_Config_Management_Plan.pdf"    /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\FDS User Guide.lnk"                      /T:"%DOCDIR%\Guides_and_Release_Notes\FDS_User_Guide.pdf"                /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\FDS Technical Reference Guide.lnk"       /T:"%DOCDIR%\Guides_and_Release_Notes\FDS_Technical_Reference_Guide.pdf" /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\FDS Validation Guide.lnk"                /T:"%DOCDIR%\Guides_and_Release_Notes\FDS_Validation_Guide.pdf"          /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\FDS Verification Guide.lnk"              /T:"%DOCDIR%\Guides_and_Release_Notes\FDS_Verification_Guide.pdf"        /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\FDS Release Notes.lnk"                   /T:"%DOCDIR%\Guides_and_Release_Notes\FDS_Release_Notes.htm"             /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\Smokeview User Guide.lnk"                /T:"%DOCDIR%\Guides_and_Release_Notes\SMV_User_Guide.pdf"                /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\Smokeview Technical Reference Guide.lnk" /T:"%DOCDIR%\Guides_and_Release_Notes\SMV_Technical_Reference_Guide.pdf" /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\Smokeview Verification Guide.lnk"        /T:"%DOCDIR%\Guides_and_Release_Notes\SMV_Verification_Guide.pdf"        /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Guides and Release Notes\Smokeview release notes.lnk"             /T:"%DOCDIR%\Guides_and_Release_Notes\Smokeview_release_notes.html"      /A:C >NUL

"%FDS6%\shortcut.exe" /F:"%FDSSTART%\Uninstall.lnk"  /T:"%UNINSTALLDIR%\uninstall.bat" /A:C >NUL

"%FDS6%\shortcut.exe" /F:"%FDSSTART%\CMDfds.lnk"             /T:"%COMSPEC%" /P:"/k fdsinit" /W:"%userprofile%" /A:C >NUL
"%FDS6%\shortcut.exe" /F:"%userprofile%\Desktop\CMDfds.lnk"  /T:"%COMSPEC%" /P:"/k fdsinit" /W:"%userprofile%" /A:C >NUL

:: ----------- setting up openmp threads environment variable

WMIC CPU Get NumberofLogicalProcessors | more /E +1 > %numcoresfile%
set /p ncores=<%numcoresfile%

if %ncores% GEQ 8 (
  set nthreads=4
) else (
  if %ncores% GEQ 4 (
    set nthreads=2
  ) else (
    set nthreads=1 
  )
)
setx -m OMP_NUM_THREADS %nthreads% > Nul

:: ----------- setting up firewall for mpi version of FDS

:: remove smpd and hydra

smpd -remove 1>> Nul 2>&1
hydra_service -remove 1>> Nul 2>&1

set "firewall_setup=%FDS6%\setup_fds_firewall.bat"
echo *** Setting up firewall exceptions.
call "%firewall_setup%" "%FDS6%\bin\mpi"

:: ----------- setting up uninstall file

echo *** Setting up the Uninstall script.

:: remove smokeview path and directory

echo if "%%cfastinstalled%%" == "1" goto skip2                >> "%UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%SMV6%" from the System Path              >> "%UNINSTALLDIR%\uninstall_base.bat"
echo call "%UNINSTALLDIR%\set_path.exe" -s -b -r %SMV6%       >> "%UNINSTALLDIR%\uninstall_base.bat"
echo rmdir /s /q "%SMV6%"                                     >> "%UNINSTALLDIR%\uninstall_base.bat"
echo :skip2                                                   >> "%UNINSTALLDIR%\uninstall_base.bat"

echo echo Removing CMDfds desktop shortcut                    >> "%UNINSTALLDIR%\uninstall_base.bat"
echo if exist %userprofile%\Desktop\CMDfds.lnk erase %userprofile%\Desktop\CMDfds.lnk  >> "%UNINSTALLDIR%\uninstall_base.bat"

:: remove FDS path and directory

echo echo Removing "%FDS6%\bin" from the System Path          >> "%UNINSTALLDIR%\uninstall_base.bat"
echo call "%UNINSTALLDIR%\set_path.exe" -s -b -r "%FDS6%\bin" >> "%UNINSTALLDIR%\uninstall_base.bat"
echo echo.                                                    >> "%UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%FDS6%"                                   >> "%UNINSTALLDIR%\uninstall_base.bat"
echo rmdir /s /q  "%FDS6%"                                    >> "%UNINSTALLDIR%\uninstall_base.bat"

:: if cfast exists then only remove fds
:: if cfast does not exist then remove everything

echo if exist "%CFAST%" goto skip_remove                      >> "%UNINSTALLDIR%\uninstall_base.bat"
echo   echo Removing "%SMV6%"                                 >> "%UNINSTALLDIR%\uninstall_base.bat"
echo   rmdir /s /q  "%SMV6%"                                  >> "%UNINSTALLDIR%\uninstall_base.bat"
echo   echo Removing "%INSTALLDIR%"                           >> "%UNINSTALLDIR%\uninstall_base.bat"
echo   rmdir "%INSTALLDIR%"                                   >> "%UNINSTALLDIR%\uninstall_base.bat"
echo :skip_remove                                             >> "%UNINSTALLDIR%\uninstall_base.bat"

echo echo *** Uninstall complete                              >> "%UNINSTALLDIR%\uninstall_base.bat"
echo pause>Nul                                                >> "%UNINSTALLDIR%\uninstall_base.bat"

type  "%UNINSTALLDIR%\uninstall_base2.bat"                    >> "%UNINSTALLDIR%\uninstall_base.bat"
erase "%UNINSTALLDIR%\uninstall_base2.bat"

echo "%UNINSTALLDIR%\uninstall.vbs"                           >> "%UNINSTALLDIR%\uninstall.bat"
echo echo Uninstall complete                                  >> "%UNINSTALLDIR%\uninstall.bat"
echo pause                                                    >> "%UNINSTALLDIR%\uninstall.bat"

set "ELEVATE_APP=%UNINSTALLDIR%\uninstall_base.bat"
set ELEVATE_PARMS=
echo Set objShell = CreateObject("Shell.Application")                       > "%UNINSTALLDIR%\uninstall.vbs"
echo Set objWshShell = WScript.CreateObject("WScript.Shell")               >> "%UNINSTALLDIR%\uninstall.vbs"
echo Set objWshProcessEnv = objWshShell.Environment("PROCESS")             >> "%UNINSTALLDIR%\uninstall.vbs"
echo objShell.ShellExecute "%ELEVATE_APP%", "%ELEVATE_PARMS%", "", "runas" >> "%UNINSTALLDIR%\uninstall.vbs"
echo WScript.Sleep 10000                                                   >> "%UNINSTALLDIR%\uninstall.vbs"

erase "%firewall_setup%"               > Nul
erase "%FDS6%\shortcut.exe"            > Nul

call :is_file_in_path fds
call :is_file_in_path smokeview
call :is_file_in_path mpiexec
echo.
echo To run fds for cases using this computer only, open the
echo command shell CMDfds (located on the desktop) and type:
echo.
echo fds_local casename.fds
echo.
echo where casename is the name of your case. For more information type: helpfds.
echo. 
echo *** Press any key, then reboot to complete the installation.  ***
pause>NUL
goto eof

:-------------------------------------------------------------------------
:----------------------subroutines----------------------------------------
:-------------------------------------------------------------------------

:: -------------------------------------------------------------
:is_file_copied
:: -------------------------------------------------------------

  set file=%1
  if not exist "%filepath%" echo.
  if not exist "%filepath%" echo ***error: %file% failed to copy to %filepath%
  exit /b 0

:: -------------------------------------------------------------
:is_file_in_path
:: -------------------------------------------------------------

  set program=%1
  where %program% 1> %TEMP%\in_path.txt 2>&1
  type %TEMP%\in_path.txt | find /i /c "INFO" > %TEMP%\in_path_count.txt
  set /p nothave=<%TEMP%\in_path_count.txt
  if %nothave% == 1 (
    echo "***Warning: %program% was not found in the PATH."
    echo "   You will need to reboot your computer so that new path entries are defined"
    exit /b 1
  )
  if exist %TEMP%\in_path.txt erase %TEMP%\in_path.txt
  if exist %TEMP%\in_path_count.txt erase %TEMP%\in_path_count.txt
  exit /b 0

:-------------------------------------------------------------------------
:get_yesnoextract
:-------------------------------------------------------------------------
set answer=%1
set answervar=%2
set repeatvar=%3

set answer=%answer:~0,1%
if "%answer%" == "Y" set answer=y
if "%answer%" == "N" set answer=n
if "%answer%" == "Q" set answer=q
if "%answer%" == "E" set answer=e
set %answervar%=%answer%
set repeat=1
if "%answer%" == "y" set repeat=0
if "%answer%" == "n" set repeat=0
if "%answer%" == "q" set repeat=2
if "%answer%" == "e" set repeat=3
set %repeatvar%=%repeat%
exit /b

:-------------------------------------------------------------------------
:get_yesno
:-------------------------------------------------------------------------
set answer=%1
set answervar=%2
set repeatvar=%3

set answer=%answer:~0,1%
if "%answer%" == "Y" set answer=y
if "%answer%" == "N" set answer=n
set %answervar%=%answer%
set repeat=1
if "%answer%" == "y" set repeat=0
if "%answer%" == "n" set repeat=0
set %repeatvar%=%repeat%
exit /b

:-------------------------------------------------------------------------
:count_programs  
:-------------------------------------------------------------------------
call :count fds
call :count smokeview
call :count mpiexec
call :count hydra_service
exit /b

:-------------------------------------------------------------------------
:stop_programs  
:-------------------------------------------------------------------------
:: remove old installation

if NOT "%hydra_service_count%" == "0" (
  echo *** Stopping hydra_service
  taskkill /F /IM hydra_service.exe >Nul 2>Nul
)

if NOT "%smokeview_count%" == "0" (
  echo *** Stopping smokeview
  taskkill /F /IM smokeview.exe >Nul 2>Nul
)

if NOT "%fds_count%" == "0" (
  echo *** Stopping fds
  taskkill /F /IM fds.exe       >Nul 2>Nul
)

if NOT "%mpiexec_count%" == "0" (
  echo *** Stopping mpiexec
  taskkill /F /IM mpiexec.exe   >Nul 2>Nul
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

:-------------------------------------------------------------------------
:extract
:-------------------------------------------------------------------------
echo.
set "INSTALLDIR=%EXTRACTDIR%"
set "SMV6=%INSTALLDIR%\SMV6"
set "FDS6=%INSTALLDIR%\FDS6"
echo *** Copying installation files to %INSTALLDIR%
if NOT EXIST "%INSTALLDIR%" mkdir "%INSTALLDIR%" > Nul
xcopy /E /I /H /Q firemodels\FDS6 "%FDS6%"     > Nul
xcopy /E /I /H /Q firemodels\SMV6 "%SMV6%"     > Nul

echo Copy complete
echo Press any key to finish
pause > Nul
goto eof

:abort
echo FDS and Smokeview installation aborted.
echo Press any key to finish
pause > Nul

:eof
exit