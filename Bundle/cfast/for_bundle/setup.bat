@echo off
set script_dir=%~dp0

title Cfast Installer

:: before we do anything make sure this is a 64 bit PC

if defined PROGRAMFILES(X86) (
  echo.
) else (
  echo.
  echo *** Fatal error: 32 bit Windows detected.
  echo     Cfast can only run on 64 bit systems.
  echo     Installation aborted.
  echo *** Press any key to exit installer.    ***
  pause>NUL
  goto abort
)

:: get install option from user

set /p versions=<firemodels\versions.txt
set /p cfast_version=<firemodels\cfast_version.txt
set /p smv_version=<firemodels\smv_version.txt

:quest1
set auto_install=y
echo.
echo Install %versions%
echo.
echo Options:
echo    1 - install in %SystemDrive%\Program Files\firemodels
echo    2 - install in %userprofile%\firemodels
echo    3 - install in a different location
echo quit - stop installation
echo.
set /p  answer1="1, 2, 3 or quit?:"
call :get_answer1 %answer1% repeat
if "%repeat%" == "1" goto quest1
if "%repeat%" == "2" goto abort

::*** check if cfast and smokeview are running

:begin
set progs_running=0
call :count_programs

if "%progs_running%" == "0" goto start
  if "%auto_install%" == "y" goto skip_remove
  echo The following program(s) need to be stopped before proceeding with the installation:
  echo %cfast_string% %smokeview_string% 
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

::*** start Cfast installation

:install

echo.
echo Installation directory: %INSTALLDIR%
echo.

set "SMV6=%INSTALLDIR%\SMV6"
set "CFAST7=%INSTALLDIR%\cfast7"

set need_overwrite=0
if EXIST "%CFAST7%" set need_overwrite=1 
if EXIST "%SMV6%"   set need_overwrite=1

:quest2
if "%need_overwrite%" == "0" goto else1 
  if "%auto_install%" == "n" echo The directories firemodels\cfast7 and/or firemodels\SMV6 exist. 
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

if NOT exist "%CFAST7%" goto skip_remove_cfast
   echo *** Removing %CFAST7%
   rmdir /S /Q "%CFAST7%"
:skip_remove_cfast

if NOT exist "%SMV6%" goto skip_remove_smv6
echo *** Removing %SMV6%
rmdir /S /Q "%SMV6%"
:skip_remove_smv6

:: copy files to new installation

echo *** Copying cfast installation files to %CFAST7%
echo *** Copying smokeview installation files to %SMV6%
if NOT EXIST "%INSTALLDIR%" mkdir "%INSTALLDIR%" > Nul
xcopy /E /I /H /Q firemodels\cfast7 "%CFAST7%"    > Nul
xcopy /E /I /H /Q firemodels\SMV6     "%SMV6%"                               > Nul

set INST_UNINSTALLDIR=%userprofile%\.cfast\uninstall
if exist %INST_UNINSTALLDIR% rmdir /s /q %INST_UNINSTALLDIR%
if not exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if not exist %INST_UNINSTALLDIR% mkdir %INST_UNINSTALLDIR%
xcopy /E /I /H /Q firemodels\Uninstall %userprofile%\.cfast\uninstall      > Nul

set "filepath=%CFAST7%\cfast.exe"
call :is_file_copied cfast.exe

set "filepath=%SMV6%\smokeview.exe"
call :is_file_copied smokeview.exe

:: ------------ setting up path ------------

echo *** Setting up PATH variable.

if NOT "%option_install%" == "1" goto skip_systempath
  call "%INST_UNINSTALLDIR%\set_path.exe" -s -m -f "%CFAST7%" > Nul
  call "%INST_UNINSTALLDIR%\set_path.exe" -s -m -f "%SMV6%"   > Nul
  goto after_setpath
:skip_systempath

call "%INST_UNINSTALLDIR%\set_path.exe" -u -m -f "%CFAST7%" > Nul
call "%INST_UNINSTALLDIR%\set_path.exe" -u -m -f "%SMV6%"   > Nul

:after_setpath

:: ------------- file association -------------
echo *** Associating the .smv file extension with smokeview.exe

ftype smvDoc="%SMV6%\smokeview.exe" "%%1" >Nul
assoc .smv=smvDoc>Nul

::set CFASTSTART=%ALLUSERSPROFILE%\Start Menu\Programs\CFAST7
set cfaststartmenu=%ProgramData%\Microsoft\Windows\Start Menu\Programs\CFAST7

:: ------------- start menu shortcuts ---------------
echo *** Adding document shortcuts to the Start menu.
if exist "%cfaststartmenu%" rmdir /q /s "%cfaststartmenu%"

mkdir "%cfaststartmenu%"
mkdir "%cfaststartmenu%\Guides"
call :setup_shortcut "%cfaststartmenu%\Guides\CFAST Users Guide.lnk"                                     "%CFAST7%\Documents\Users_Guide.pdf"
call :setup_shortcut "%cfaststartmenu%\Guides\CFAST Technical Reference Guide.lnk"                       "%CFAST7%\Documents\Tech_Ref.pdf"
call :setup_shortcut "%cfaststartmenu%\Guides\CFAST Software Development and Model Evaluation Guide.lnk" "%CFAST7%\Documents\Validation_Guide.pdf"
call :setup_shortcut "%cfaststartmenu%\Guides\CFAST Configuration Management.lnk"                        "%CFAST7%\Documents\Configuration_Guide.pdf"
call :setup_shortcut "%cfaststartmenu%\CFAST.lnk"                                                        "%CFAST7%\CEdit.exe" 
call :setup_shortcut "%cfaststartmenu%\Smokeview.lnk"                                                    "%SMV6%\smokeview.exe"   
call :setup_shortcut "%cfaststartmenu%\Uninstall.lnk"                                                    "%INST_UNINSTALLDIR%\uninstall.bat"

:: ----------- setting up uninstall file

echo *** Setting up the Uninstall script.

:: if fds exists then only remove cfast
:: if fds does not exist then remove both cfast and smv

echo @echo off                                                    > "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo.                                                       >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo set have_fds=1                                              >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo where fds ^> Nul 2^>^&1                                     >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo if %%errorlevel%% == 1 set have_fds=0                       >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo if     %%have_fds%% == 1 echo *** Uninstalling %cfast_version% >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo if NOT %%have_fds%% == 1 echo *** Uninstalling %versions%   >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo.                                                       >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo Press any key to proceed or CTRL C to abort            >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo pause^>NUL                                                  >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo if %%have_fds%% == 1 goto skip2                             >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%SMV6%" from the System Path                 >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo call "%INST_UNINSTALLDIR%\set_path.exe" -s -b -r "%SMV6%"   >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%SMV6%" directory                            >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo rmdir /s /q "%SMV6%"                                        >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo :skip2                                                      >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo.                                                            >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%CFAST7%" from system path                   >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo call "%INST_UNINSTALLDIR%\set_path.exe" -s -b -r "%CFAST7%" >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%CFAST7%" directory                          >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo rmdir /s /q  "%CFAST7%"                                     >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo.                                                            >> "%INST_UNINSTALLDIR%\uninstall_base.bat"

echo if %%have_fds%% == 1 goto skip3                             >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo echo Removing "%INSTALLDIR%"                                >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo rmdir /s /q "%INSTALLDIR%"                                  >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo :skip3                                                      >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo.                                                            >> "%INST_UNINSTALLDIR%\uninstall_base.bat"

echo echo *** Uninstall complete                                 >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo pause^>Nul                                                  >> "%INST_UNINSTALLDIR%\uninstall_base.bat"
echo.                                                            >> "%INST_UNINSTALLDIR%\uninstall_base.bat"

echo "%INST_UNINSTALLDIR%\uninstall.vbs"                         >> "%INST_UNINSTALLDIR%\uninstall.bat"
echo echo Uninstall complete                                     >> "%INST_UNINSTALLDIR%\uninstall.bat"
echo pause                                                       >> "%INST_UNINSTALLDIR%\uninstall.bat"

set "ELEVATE_APP=%INST_UNINSTALLDIR%\uninstall_base.bat"
set ELEVATE_PARMS=
echo Set objShell = CreateObject("Shell.Application")                       > "%INST_UNINSTALLDIR%\uninstall.vbs"
echo Set objWshShell = WScript.CreateObject("WScript.Shell")               >> "%INST_UNINSTALLDIR%\uninstall.vbs"
echo Set objWshProcessEnv = objWshShell.Environment("PROCESS")             >> "%INST_UNINSTALLDIR%\uninstall.vbs"
echo objShell.ShellExecute "%ELEVATE_APP%", "%ELEVATE_PARMS%", "", "runas" >> "%INST_UNINSTALLDIR%\uninstall.vbs"
echo WScript.Sleep 10000                                                   >> "%INST_UNINSTALLDIR%\uninstall.vbs"


call :is_file_in_path smokeview
echo.
echo *** Press any key, then reboot to complete the installation.  ***
pause>NUL
goto eof


:-------------------------------------------------------------------------
:setup_shortcut
:-------------------------------------------------------------------------
set outfile=%1
set infile=%2

"%INST_UNINSTALLDIR%\shortcut.exe" /F:%outfile% /T:%infile%    /A:C  > Nul
if NOT exist %outfile% echo ***error: The shortcut %outfile% failed to be created
exit /b

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
:get_answer1
:-------------------------------------------------------------------------
set answer=%1
set repeatvar=%2

set answer=%answer:~0,1%
set %repeatvar%=0
set INSTALLDIR=
set %repeatvar%=1
if %answer% == 1 set "INSTALLDIR=%SystemDrive%\Program Files\firemodels"
if %answer% == 1 set %repeatvar%=0
if %answer% == 2 set "INSTALLDIR=%userprofile%\firemodels"
if %answer% == 2 set %repeatvar%=0
if %answer% == 3 call :get_custom_path %repeatvar%
if %answer% == 3 set %repeatvar%=0
if %answer% == q set %repeatvar%=2

exit /b

:-------------------------------------------------------------------------
:get_custom_path
:-------------------------------------------------------------------------
set repeatvar=%1
set %repeatvar%=0
set /p  "INSTALLDIR=enter cfast root:"
if NOT exist "%INSTALLDIR%" mkdir "%INSTALLDIR%
if NOT exist "%INSTALLDIR%" echo ***error: failed to create %INSTALLDIR%
if NOT exist "%INSTALLDIR%" set %repeatvar%=1

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
call :count cfast
call :count smokeview
exit /b

:-------------------------------------------------------------------------
:stop_programs  
:-------------------------------------------------------------------------
:: remove old installation

if NOT "%smokeview_count%" == "0" (
  echo *** Stopping smokeview
  taskkill /F /IM smokeview.exe >Nul 2>Nul
)

if NOT "%cfast_count%" == "0" (
  echo *** Stopping cfast
  taskkill /F /IM cfast.exe       >Nul 2>Nul
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
echo Cfast installation aborted.
echo Press any key to finish
pause > Nul

:eof
exit