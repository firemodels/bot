@echo off
set script_dir=%~dp0

:: check if fds and smokeview are running

:begin
set progs_running=0
call :count fds.exe            fds_count
call :count smokeview.exe      smv_count
call :count mpiexec.exe        mpiexec_count
call :count hydra_service.exe  hydra_count
if NOT "%fds_count%"     == "0"   set progs_running=1
if NOT "%smv_count%"     == "0"   set progs_running=1
if NOT "%mpiexec_count%" == "0"   set progs_running=1

if "%progs_running%" == "0" goto start
  if NOT "%fds_count%" == "0"     echo number of fds instances running: %fds_count%
  if NOT "%smv_count%" == "0"     echo number of smokeview instances running: %smv_count%
  if NOT "%mpiexec_count%" == "0" echo number of mpiexec instances running: %mpiexec_count%
  echo Options:
  echo    Press 1 to let the installer stop fds, smokeview and/or mpiexec
  echo    Press 2 after stopping fds, smokeview and/or mpiexec yourself
  echo    Press any other key to quit installation
  set /p  option="option:"
  if "%option%" == "1" goto start
  if "%option%" == "2" goto begin
  goto abort

:start
call :menu
set /p install_option="FDS install option:"

if "%install_option%" == "1" (
  set "INSTALLDIR=%ProgramFiles%\firemodels"
  goto proceed
)
if "%install_option%" == "2" (
  set "INSTALLDIR=%USERPROFILE%\firemodels"
  goto proceed
)
goto abort

:-------------------------------------------------------------------------
:menu  
:-------------------------------------------------------------------------
echo Install options
echo    Press 1 to install FDS in %ProgramFiles%\firemodels\FDS6
echo    Press 2 to install FDS in %USERPROFILE%\firemodels\FDS6
echo    Press any other key to quit
exit /b

:-------------------------------------------------------------------------
:count
:-------------------------------------------------------------------------
set arg1=%1
set var=%2
tasklist | find /c "%arg1%" > count.txt
set /p %var%=<count.txt
erase count.txt
exit /b
:eof

:proceed

echo Installation location: %INSTALLDIR%\FDS6
set /p proceed="Proceed? (y, n)"

if "%proceed%" == "y" goto install
if "%proceed%" == "Y" goto install
if "%proceed%" == "n" goto begin
if "%proceed%" == "N" goto begin
goto proceed

:install

set DOCDIR=%INSTALLDIR%\FDS6\Documentation
set UNINSTALLDIR=%INSTALLDIR%\FDS6\Uninstall
 
:: make sure this is a 64 bit PC

if defined PROGRAMFILES(X86) (
  echo.
) else (
  echo *** Fatal error: 32 bit Windows detected.
  echo     FDS and Smokeview can only run on 64 bit systems.
  echo     Installation aborted.
  echo *** Press any key to continue.    ***
  pause>NUL
  goto abort
)

:: input install directory from user for now use %userprofile%\firemodels

:: ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:: remove old installation

if NOT "%hydra_count%" == "0" (
  echo *** Removing hydra_service
  hydra_service -remove         >Nul 2>Nul
)

if NOT "%smv_count%" == "0" (
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

if NOT exist %INSTALLDIR% goto skip_remove_firemodels
echo *** Removing %INSTALLDIR%
rmdir /S /Q %INSTALLDIR%
:skip_remove_firemodels

:: copy files to new installation

echo *** Copying installation files to %INSTALLDIR%
xcopy /E /I /H /Q firemodels %INSTALLDIR% > Nul
echo        copy complete

echo *** Removing previous FDS/Smokeview entries from the system and user path.
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "nist\fds" >Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -b -r "FDS\FDS5" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "FDS\FDS5" >Nul
call "%UNINSTALLDIR%\set_path.exe" -u -m -b -r "FDS\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "FDS\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "firemodels\FDS6" >Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -b -r "firemodels\SMV6" >Nul

set SMV6=%INSTALLDIR%\SMV6
set FDS6=%INSTALLDIR%\FDS6
set CFAST=%INSTALLDIR%\cfast

:: ------------ create aliases ----------------

set numcoresfile="%TEMP%\numcoresfile"

:: ------------ setting up path ------------

echo *** Setting up the PATH variable.

call "%UNINSTALLDIR%\set_path.exe" -s -m -f "%FDS6%\bin" > Nul
call "%UNINSTALLDIR%\set_path.exe" -s -m -f "%SMV6%"     > Nul

:: ------------- file association -------------
echo *** Associate the .smv file extension with smokeview.exe

ftype smvDoc="%SMV6%\smokeview.exe" "%%1" >Nul
assoc .smv=smvDoc>Nul

set FDSSTART=%ALLUSERSPROFILE%\Start Menu\Programs\FDS6

:: ------------- start menu shortcuts ---------------
echo *** Add document shortcuts to the Start menu.
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

WMIC CPU Get NumberofLogicalProcessors | more +1 > %numcoresfile%
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

set firewall_setup="%FDS6%\setup_fds_firewall.bat"
echo *** Setting up firewall exceptions.
call %firewall_setup% "%FDS6%\bin\mpi"

:: ----------- setting up uninstall file

echo *** Setting up the Uninstall script.

:: remove smokeview path and directory
echo if %%cfastinstalled%% == 1 goto skip2                    >> %UNINSTALLDIR%\uninstall_base.bat
echo echo Removing directory, %SMV6%, from the System Path    >> %UNINSTALLDIR%\uninstall_base.bat
echo call "%UNINSTALLDIR%\set_path.exe" -s -b -r "%SMV6%"     >> %UNINSTALLDIR%\uninstall_base.bat
echo rmdir /s /q "%SMV6%"                                     >> %UNINSTALLDIR%\uninstall_base.bat
echo :skip2                                                   >> %UNINSTALLDIR%\uninstall_base.bat

echo echo Removing CMDfds desktop shortcut                    >> %UNINSTALLDIR%\uninstall_base.bat
echo if exist %userprofile%\Desktop\CMDfds.lnk erase %userprofile%\Desktop\CMDfds.lnk  >> %UNINSTALLDIR%\uninstall_base.bat

:: remove FDS path and directory
echo echo Removing directory, %CD%\bin , from the System Path >> %UNINSTALLDIR%\uninstall_base.bat
echo call "%UNINSTALLDIR%\set_path.exe" -s -b -r "%CD%\bin"   >> %UNINSTALLDIR%\uninstall_base.bat
echo echo.                                                    >> %UNINSTALLDIR%\uninstall_base.bat
echo if exist "%CFAST%" echo Removing %CFAST%                 >> %UNINSTALLDIR%\uninstall_base.bat
echo if exist "%CFAST%" rmdir /s /q "%CFAST%"                 >> %UNINSTALLDIR%\uninstall_base.bat
echo if NOT exist "%CFAST%" echo Removing %INSTALLDIR%        >> %UNINSTALLDIR%\uninstall_base.bat
echo if NOT exist "%CFAST%" rmdir /s /q "%INSTALLDIR%"        >> %UNINSTALLDIR%\uninstall_base.bat
echo pause                                                    >> %UNINSTALLDIR%\uninstall_base.bat

echo echo *** Uninstall complete                              >> %UNINSTALLDIR%\uninstall_base.bat
echo pause>Nul                                                >> %UNINSTALLDIR%\uninstall_base.bat

type %UNINSTALLDIR%\uninstall_base2.bat                       >> %UNINSTALLDIR%\uninstall_base.bat
erase %UNINSTALLDIR%\uninstall_base2.bat

echo "%UNINSTALLDIR%\uninstall.vbs"                           >> %UNINSTALLDIR%\uninstall.bat
echo echo Uninstall complete                                  >> %UNINSTALLDIR%\uninstall.bat
echo pause                                                    >> %UNINSTALLDIR%\uninstall.bat

set ELEVATE_APP=%UNINSTALLDIR%\uninstall_base.bat
set ELEVATE_PARMS=
echo Set objShell = CreateObject("Shell.Application")                       > %UNINSTALLDIR%\uninstall.vbs
echo Set objWshShell = WScript.CreateObject("WScript.Shell")               >> %UNINSTALLDIR%\uninstall.vbs
echo Set objWshProcessEnv = objWshShell.Environment("PROCESS")             >> %UNINSTALLDIR%\uninstall.vbs
echo objShell.ShellExecute "%ELEVATE_APP%", "%ELEVATE_PARMS%", "", "runas" >> %UNINSTALLDIR%\uninstall.vbs

erase %firewall_setup%
erase "%FDS6%\wrapup_fds_install.bat"
erase "%FDS6%\shortcut.exe"

echo.
echo *** Press any key, then reboot to complete the installation.  ***
pause>NUL
goto eof

:abort
echo FDS and Smokeview installation aborted

:eof
exit