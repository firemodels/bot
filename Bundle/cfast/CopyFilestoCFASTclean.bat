@echo off

set CURDIR=%CD%

:: define cfast_root

cd ..\..\..\cfast
set cfast_root=%CD%

@echo ***Creating NPlot
cd %cfast_root%\..\Extras\nplot
set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Community\Msbuild\Current\Bin\MSBuild.exe"
%MSBUILD%  NPlot.sln /target:NPlot /p:Configuration=Release /p:Platform="Any CPU" > Nul 2>&1
call :copy_file %cfast_root%\..\Extras\nplot\src\bin NPlot.dll %cfast_root%\Utilities\for_bundle\Bin NPlot.dll


@echo ***Creating CEdit
cd %cfast_root%\Build\Cedit
call make_cedit.bat bot  > Nul 2>&1
call :copy_file %cfast_root%\Source\Cedit\obj\Release CEdit.exe %cfast_root%\Utilities\for_bundle\Bin CEdit.exe

@echo ***Creating CFAST
call %cfast_root%\Build\scripts\setup_intel_compilers.bat intel64  > Nul 2>&1
cd %cfast_root%\Build\CFAST\intel_win_64
call make_cfast.bat bot release > Nul 2>&1
call :copy_file . cfast7_win_64.exe %cfast_root%\Utilities\for_bundle\Bin cfast.exe

@echo ***Creating CData
cd %cfast_root%\Build\Cdata\intel_win_64
call make_cdata.bat bot release > Nul 2>&1
call :copy_file . cdata7_win_64.exe %cfast_root%\Utilities\for_bundle\Bin cdata.exe

@echo ***Creating VandVCalcs
cd %cfast_root%\Build\VandV_Calcs\intel_win_64
call make_vv.bat bot release > Nul 2>&1
call :copy_file . VandV_Calcs_win_64.exe %cfast_root%\Utilities\for_bundle\Bin VandV_Calcs.exe

cd %cfast_root%\Utilities\for_bundle\scripts

call :copy_dir %cfast_root%\..\Extras\Bin %cfast_root%\Utilities\for_bundle\Bin

@echo ***Copying Smokeview executables

if NOT exist %cfast_root%\Utilities\for_bundle\SMV6 (
   mkdir %cfast_root%\Utilities\for_bundle\SMV6
)
call :copy_dir %cfast_root%\..\Extras\SMV6 %cfast_root%\Utilities\for_bundle\SMV6
if NOT exist %cfast_root%\Utilities\for_bundle\SMV6\textures (
   mkdir %cfast_root%\Utilities\for_bundle\SMV6\textures
)
call :copy_dir %cfast_root%\..\Extras\SMV6\textures %cfast_root%\Utilities\for_bundle\SMV6\textures

@echo ***Copying install utilities
call :copy_file %cfast_root%\..\Extras\SMV6 set_path.exe %cfast_root%\Utilities\for_bundle\bin set_path.exe
call :copy_file %cfast_root%\..\Extras\Bin Shortcut.exe  %cfast_root%\Utilities\for_bundle\bin Shortcut.exe 

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
