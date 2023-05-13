@echo off
set build_cedit=%1

set bindir=%cfast_root%\Utilities\for_bundle\Bin
set vandvdir=%cfast_root%\Build\VandV_Calcs\intel_win_64
set docdir=%cfast_root%\Manuals
set CURDIR2=%CD%

set configfile=%userprofile%\.bundle\bundle_config.bat
if not exist %configfile% echo ***error: %userprofile%\bundle_config.bat does not exist
if not exist %configfile% exit /b
call %configfile%
call check_config || exit /b 1

cd %cfast_root%\..\bot
set botrepo=%CD%
cd %CURDIR2%

cd %cfast_root%\..\smv
set smvrepo=%CD%
cd %CURDIR2%

echo.
echo ***Copying CFAST files
echo ***Making directories

if exist %FIREMODELSDIR% rmdir /s /q %FIREMODELSDIR%
if exist %CFASTDISTDIR%       rmdir /s /q %CFASTDISTDIR%
mkdir %FIREMODELSDIR%
mkdir %CFASTDISTDIR%
mkdir %CFASTDISTDIR%\Examples
mkdir %CFASTDISTDIR%\Documents
mkdir %FIREMODELSDIR%\Uninstall

set SMVDISTDIR=%CFASTDISTDIR%\..\SMV6
if exist %SMVDISTDIR% rmdir /s /q %SMVDISTDIR%
mkdir %SMVDISTDIR%
mkdir %SMVDISTDIR%\textures

echo ***Copying CFAST executables

call :COPY  %bindir%\CData.exe                %CFASTDISTDIR%\
if %build_cedit% == 0 goto skip_build_cedit
   call :COPY  %bindir%\CEdit.exe             %CFASTDISTDIR%\
:skip_build_cedit
call :COPY  %bindir%\CFAST.exe                %CFASTDISTDIR%\
call :COPY  %vandvdir%\VandV_Calcs_win_64.exe                               %CFASTDISTDIR%\VandV_Calcs.exe
call :COPY  %smvrepo%\Build\background\intel_win_64\background_win_64.exe   %CFASTDISTDIR%\background.exe

if %build_cedit% == 0 goto skip_build_cedit2
   echo ***Copying CEdit DLLs

   call :COPY  %bindir%\C1.C1Pdf.4.8.dll                %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.C1Report.4.8.dll             %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Zip.dll                      %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.4.8.dll                  %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.BarCode.4.8.dll          %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.C1Document.4.8.dll       %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.C1DX.4.8.dll             %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.C1FlexGrid.4.8.dll       %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.C1Report.4.8.dll         %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.C1ReportDesigner.4.8.dll %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.C1Sizer.4.8.dll          %CFASTDISTDIR%\
   call :COPY  %bindir%\C1.Win.ImportServices.4.8.dll   %CFASTDISTDIR%\
   call :COPY  %bindir%\NPlot.dll 				        %CFASTDISTDIR%\
:skip_build_cedit2

echo ***Copying CFAST example files

call :COPY  %bindir%\Data\Users_Guide_Example.in %CFASTDISTDIR%\Examples\
call :COPY  %docdir%\CFAST_CData_Guide\Examples\*.in   %CFASTDISTDIR%\Examples\

echo ***Copying CFAST documentation

set PDFS=%userprofile%\.cfast\PDFS
call :COPYPDF CFAST_Tech_Ref
call :COPYPDF CFAST_Users_Guide
call :COPYPDF CFAST_Validation_Guide
call :COPYPDF CFAST_Configuration_Guide
call :COPYPDF CFAST_CData_Guide

echo ***Copying Smokeview files

call :COPYPROG background
call :COPYPROG get_time
call :COPYPROG get_time
call :COPYPROG sh2bat
call :COPYPROG smokediff
call :COPYPROG smokeview test_
call :COPYPROG smokezip
call :COPYPROG wind2fds
call :COPY %botrepo%\Bundlebot\smv\for_bundle\objects.svo    %SMVDISTDIR%\
call :COPY %botrepo%\Bundlebot\smv\for_bundle\volrender.ssf  %SMVDISTDIR%\
call :COPY_DIR %botrepo%\Bundlebot\smv\for_bundle\textures   %SMVDISTDIR%\textures\

echo.
echo ***Creating installer
echo ***Copying Uninstall files


call :COPY  %botrepo%\Bundlebot\cfast\for_bundle\uninstall.bat           %FIREMODELSDIR%\Uninstall
call :COPY  %botrepo%\Bundlebot\cfast\for_bundle\uninstall_cfast.bat     %FIREMODELSDIR%\Uninstall\uninstall_base.bat 
call :COPY  %smvrepo%\Build\set_path\intel_win_64\set_path_win_64.exe %FIREMODELSDIR%\Uninstall\set_path.exe
call :COPY  %botrepo%\Bundlebot\smv\for_bundle\Shortcut                  %FIREMODELSDIR%\Uninstall\shortcut.exe


cd %CURDIR%

GOTO EOF

:-------------------------------------------------
:COPY
:-------------------------------------------------
set infile=%1
set outfile=%2
IF EXIST %infile%       copy %infile% %outfile% > Nul 2>&1
IF NOT EXIST %infile%   echo ***Warning: %infile% does not exist
exit /b

:-------------------------------------------------
:COPYPROG
:-------------------------------------------------
set inprog=%1
set test=%2
set infile=%smvrepo%\Build\%inprog%\intel_win_64\%inprog%_win_%test%64.exe
IF EXIST %infile%       copy %infile% %SMVDISTDIR%\%inprog%.exe > Nul 2>&1
IF NOT EXIST %SMVDISTDIR%\%inprog%.exe echo ***Error: %infile% copy failed
exit /b

:-------------------------------------------------
:COPYPDF
:-------------------------------------------------
set infile=%1
set fullfile=%PDFS%\%infile%.pdf
IF NOT EXIST %fullfile% call :GETPDF %infile%
IF EXIST %fullfile%       copy %fullfile% %CFASTDISTDIR%\Documents\ > Nul 2>&1
IF NOT EXIST %fullfile%   echo ***Warning: %fullfile% does not exist
exit /b

:: -------------------------------------------------
:GETPDF
:: -------------------------------------------------
set file=%1
set fullfile=%PDFS%\%file%.pdf
echo | set /p dummyName=***downloading %file%: 

gh release download %GH_CFAST_TAG% -p %file%.pdf -R github.com/%GH_OWNER%/%GH_REPO% -D %PDFS%

if NOT exist %fullfile% echo failed
if exist %fullfile% echo succeeded
exit /b 1

:: -------------------------------------------------
:COPY_DIR
:: -------------------------------------------------
set indir=%1
set outdir=%2
copy %indir% %outdir% > Nul 2>&1
exit /b

:EOF
