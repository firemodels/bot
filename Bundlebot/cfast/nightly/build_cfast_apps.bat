@echo off
set build_cedit=%1

set CURDIR=%CD%

:: define cfast_root

cd ..\..\..\..\cfast
set cfast_root=%CD%

set stage2out=%CURDIR%\out\stage2_build_apps

echo. > %stage2out%

@echo.
@echo ***Building CFAST executables
@echo.  >> %stage2out%
@echo ***Building NPlot
@echo.  >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo ***Building NPlot                                                         >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
cd %cfast_root%\..\nplot
set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Community\Msbuild\Current\Bin\MSBuild.exe"
%MSBUILD%  NPlot.sln /target:NPlot /p:Configuration=Release /p:Platform="Any CPU" >> %stage2out% 2>&1
call :copy_file %cfast_root%\..\nplot\src\bin NPlot.dll %cfast_root%\Utilities\for_bundle\Bin NPlot.dll

if %build_cedit% == 0 goto skip_build_cedit
   @echo.  >> %stage2out%
   @echo ***Building CEdit
   @echo.  >> %stage2out%
   @echo ------------------------------------------------------------------------- >> %stage2out%
   @echo ***Building CEdit                                                         >> %stage2out%
   @echo ------------------------------------------------------------------------- >> %stage2out%
   cd %cfast_root%\Build\Cedit
   call make_cedit.bat bot  >> %stage2out% 2>&1
   call :copy_file %cfast_root%\Source\Cedit\obj\Release CEdit.exe %cfast_root%\Utilities\for_bundle\Bin CEdit.exe
:skip_build_cedit

:: skip intel setup if it was already setup
if x%inteldefined% == x1 goto skip_intel
@echo.                                                                          >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo ***Setting up Intel Compilers                                             >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo.                                                                          >> %stage2out%
@echo ***Setting up Intel Compilers
set inteldefined=1
echo setting up intel compilers
call %cfast_root%\Build\scripts\setup_intel_compilers.bat intel64                >> %stage2out% 2>&1
:skip_intel

@echo.                                                                          >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo ***Building CFAST                                                         >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo.                                                                          >> %stage2out%

@echo ***Building CFAST
cd %cfast_root%\Build\CFAST\intel_win_64
call make_cfast.bat bot release                                                  >> %stage2out% 2>&1
call :copy_file . cfast7_win_64.exe %cfast_root%\Utilities\for_bundle\Bin cfast.exe

@echo.                                                                          >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo ***Building CDATA                                                         >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo.                                                                          >> %stage2out%

@echo ***Building CData
cd %cfast_root%\Build\Cdata\intel_win_64
call make_cdata.bat bot release                                                 >> %stage2out% 2>&1
call :copy_file . cdata7_win_64.exe %cfast_root%\Utilities\for_bundle\Bin cdata.exe

@echo.                                                                          >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo ***Building VandVCalcs                                                    >> %stage2out%
@echo ------------------------------------------------------------------------- >> %stage2out%
@echo.                                                                          >> %stage2out%

@echo ***Building VandVCalcs
cd %cfast_root%\Build\VandV_Calcs\intel_win_64
call make_vv.bat bot release                                                    >> %stage2out% 2>&1
call :copy_file . VandV_Calcs_win_64.exe %cfast_root%\Utilities\for_bundle\Bin VandV_Calcs.exe

cd %cfast_root%\Utilities\for_bundle\scripts

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set fromdir=%1
set fromfile=%2
set todir=%3
set tofile=%4

copy %fromdir%\%fromfile% %todir%\%tofile% /Y  > Nul 2>&1
if NOT EXIST %todir%\%tofile% echo ***error: %todir%\%tofile% failed to copy
exit /b

:: -------------------------------------------------
:copy_dir
:: -------------------------------------------------
set fromdir=%1
set todir=%2

copy %fromdir% %todir% /Y  > Nul 2>&1
exit /b

:eof
