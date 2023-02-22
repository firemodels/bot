@echo off
set cfastrev=%1
set smvrev=%2
Title Bundle cfast for Windows


:: installation settings settings

set installerbase=cfast7_installer
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
cd %CURDIR%

set git_drive=c:
%git_drive%

set DISTDIR=%cfast_root%\Utilities\for_bundle\scripts\BUNDLEDIR\%installerbase%
set bundleinfo=%cfast_root%\Utilities\for_bundle\scripts\bundleinfo

call Create_Install_Files.bat

copy "%bundleinfo%\wrapup_cfast_install.bat"           "%DISTDIR%\wrapup_cfast_install.bat"   > Nul 2>&1

cd %DISTDIR%
echo ***Compressing installation files%
echo. > %stage3out%
echo ***zipping bundle files > %stage3out%
wzzip -a -r -P ..\%installerbase%.zip * ..\SMV6   >> %stage3out% 2>&1

:: create an installation file from the zipped bundle directory

echo ***Creating installation file

cd %DISTDIR%\..
echo Setup is about to install CFAST 7  > %bundleinfo%\message.txt
echo Press Setup to begin installation. > %bundleinfo%\main.txt
if exist %installerbase%.exe erase %installerbase%.exe
wzipse32 %installerbase%.zip -runasadmin -a %bundleinfo%\about.txt -st"cfast 7 Setup" -d "c:\Program Files\firemodels\%distname%" -c wrapup_cfast_install.bat

set uploaddir=%userprofile%\.bundle\uploads
if not exist %userprofile%\.bundle         mkdir %userprofile%\.bundle
if not exist %uploaddir% mkdir %uploaddir%
set outexe=%cfastrev%_%smvrev%_tst_win.exe
echo ***Copying %installerbase%.exe to %uploaddir%\%outexe%
copy %installerbase%.exe %uploaddir%\%outexe%   >> %stage3out% 2>&1

echo ***CFAST installer built

cd %CURDIR%


