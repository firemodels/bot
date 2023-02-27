@echo off
set cfastrev=%1
set smvrev=%2
set upload=%3
set build_cedit=%4
Title Bundle cfast for Windows


:: installation settings settings

set installerbase=cfast7
set distname=cfast7

:: VVVVVVVVVVVVVVVVV shouldn't need to change anything below VVVVVVVVVVVVVVV

set CURDIR=%CD%
set stage3out=%THISDIR%\out\stage3_bundle
echo. > %stage3out%

:: define cfast_root

cd ..\..\..\cfast
set cfast_root=%CD%

:: define smv_root

cd ..\smv
set smv_root=%CD%

:: define bot_root

cd ..\bot
set bot_root=%CD%

cd %CURDIR%

set git_drive=c:
%git_drive%

set outbase=%cfastrev%_%smvrev%_tst_win

set BUNDLEBASE=%userprofile%\.bundle\uploads\%outbase%
if exist %BUNDLEBASE% rmdir /s /q %BUNDLEBASE%
mkdir %BUNDLEBASE%

set FIREMODELSDIR=%BUNDLEBASE%\firemodels
mkdir %FIREMODELSDIR%
set CFASTDISTDIR=%FIREMODELSDIR%\%installerbase%
set bundleinfo=%cfast_root%\Utilities\for_bundle\scripts\bundleinfo
set bundlenewinfo=%bot_root%\bundle\cfast\for_bundle\

call build_bundle_dir.bat %build_cedit%

echo Unpacking %cfastrev% and %smvrev% installation files > %bundlenewinfo%\unpack.txt
echo %cfastrev% and %smvrev% > %FIREMODELSDIR%\versions.txt 
echo %cfastrev%              > %FIREMODELSDIR%\cfast_version.txt 
echo %smvrev%                > %FIREMODELSDIR%\smv_version.txt 
CALL :COPY %bundlenewinfo% setup.bat                %FIREMODELSDIR% setup.bat
call :COPY %bundleinfo%    wrapup_cfast_install.bat %CFASTDISTDIR% wrapup_cfast_install.bat

cd %FIREMODELSDIR%\..
echo ***Compressing installation files%
echo. > %stage3out%
echo ***zipping bundle files > %stage3out%
if exist ..\%outbase%.zip erase ..\%outbase%.zip
wzzip -a -r -P ..\%outbase%.zip firemodels   >> %stage3out% 2>&1
:: create an installation file from the zipped bundle directory

echo ***Creating installation file

cd %FIREMODELSDIR%\..\..
echo Setup is about to install CFAST 7  > %FIREMODELSDIR%\message.txt
if exist %outbase%.exe erase %outbase%.exe
wzipse32 %outbase%.zip -runasadmin -setup -auto -i %bundlenewinfo%\icon.ico -t %bundlenewinfo%\unpack.txt -a %bundleinfo%\about.txt -st"CFAST %cfast_version% Setup" -o -c cmd /k firemodels\setup.bat


set uploaddir=%userprofile%\.bundle\uploads
if not exist %userprofile%\.bundle         mkdir %userprofile%\.bundle
if not exist %uploaddir% mkdir %uploaddir%
echo ***Copying %outbase%.exe to %uploaddir%
copy %outbase%.exe %uploaddir%\%outbase%.exe   >> %stage3out% 2>&1
copy %outbase%.zip %uploaddir%\%outbase%.zip   >> %stage3out% 2>&1

echo ***CFAST installer built

if NOT x%upload% == x1 goto endif1
  cd %CURDIR%
  call upload_cfast_bundle %cfastrev% %smvrev%
  echo ***CFAST installer uploaded
:endif1


cd %CURDIR%

goto eof

::------------------------------------------------
:COPY
::------------------------------------------------
set fromdir=%1
set fromfile=%2
set todir=%3
set tofile=%4
IF NOT EXIST %fromdir%\%fromfile% echo ***error: %fromdir%\%fromfile% does not exist
IF EXIST %fromdir%\%fromfile%     copy %fromdir%\%fromfile% %todir%\%tofile% > Nul 2>&1
IF NOT EXIST %todir%\%tofile%     echo ***error: %fromdir%\%fromfile% failed to copy
IF NOT EXIST %todir%\%tofile%     echo           to %todir%\%tofile%
exit /b

:eof