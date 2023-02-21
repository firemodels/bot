@echo off

set bindir=%cfast_root%\Utilities\for_bundle\Bin
set vandvdir=%cfast_root%\Build\VandV_Calcs\intel_win_64
set docdir=%cfast_root%\Manuals
set CURDIR2=%CD%

cd %cfast_root%\..\bot
set botrepo=%CD%
cd %CURDIR2%

cd %cfast_root%\..\smv
set smvrepo=%CD%
cd %CURDIR2%

echo.
echo ***Copying CFAST files
echo ***Making directories

if exist %DISTDIR% rmdir /s /q %DISTDIR%
mkdir %DISTDIR%
mkdir %DISTDIR%\Examples
mkdir %DISTDIR%\Documents
mkdir %DISTDIR%\Uninstall

set SMVDISTDIR=%DISTDIR%\..\SMV6
if exist %SMVDISTDIR% rmdir /s /q %SMVDISTDIR%
mkdir %SMVDISTDIR%
mkdir %SMVDISTDIR%\textures

echo ***Copying CFAST executables

call :COPY  %bindir%\CData.exe                %DISTDIR%\
call :COPY  %bindir%\CEdit.exe                %DISTDIR%\
call :COPY  %bindir%\CFAST.exe                %DISTDIR%\
call :COPY  %vandvdir%\VandV_Calcs_win_64.exe                               %DISTDIR%\VandV_Calcs.exe
call :COPY  %smvrepo%\Build\background\intel_win_64\background_win_64.exe   %DISTDIR%\background.exe

echo ***Copying CFAST DLLs

call :COPY  %bindir%\C1.C1Pdf.4.8.dll                %DISTDIR%\
call :COPY  %bindir%\C1.C1Report.4.8.dll             %DISTDIR%\
call :COPY  %bindir%\C1.Zip.dll                      %DISTDIR%\
call :COPY  %bindir%\C1.Win.4.8.dll                  %DISTDIR%\
call :COPY  %bindir%\C1.Win.BarCode.4.8.dll          %DISTDIR%\
call :COPY  %bindir%\C1.Win.C1Document.4.8.dll       %DISTDIR%\
call :COPY  %bindir%\C1.Win.C1DX.4.8.dll             %DISTDIR%\
call :COPY  %bindir%\C1.Win.C1FlexGrid.4.8.dll       %DISTDIR%\
call :COPY  %bindir%\C1.Win.C1Report.4.8.dll         %DISTDIR%\
call :COPY  %bindir%\C1.Win.C1ReportDesigner.4.8.dll %DISTDIR%\
call :COPY  %bindir%\C1.Win.C1Sizer.4.8.dll          %DISTDIR%\
call :COPY  %bindir%\C1.Win.ImportServices.4.8.dll   %DISTDIR%\
call :COPY  %bindir%\NPlot.dll 				        %DISTDIR%\

echo ***Copying CFAST support files

call :COPY  %bindir%\AllFires.in              %DISTDIR%\
call :COPY  %bindir%\thermal.csv              %DISTDIR%
call :COPY  %bindir%\3_panel_workstation.o    %DISTDIR%\
call :COPY  %bindir%\bunkbed.o                %DISTDIR%\
call :COPY  %bindir%\burner.o                 %DISTDIR%\
call :COPY  %bindir%\curtains.o               %DISTDIR%\
call :COPY  %bindir%\kiosk.o                  %DISTDIR%\
call :COPY  %bindir%\mattress_and_boxspring.o %DISTDIR%\
call :COPY  %bindir%\sofa.o                   %DISTDIR%\
call :COPY  %bindir%\tv_set.o                 %DISTDIR%\
call :COPY  %bindir%\upholstered_chair.o      %DISTDIR%\
call :COPY  %bindir%\wardrobe.o               %DISTDIR%\
call :COPY  %bindir%\wood_wall.o              %DISTDIR%\

echo ***Copying CFAST example files

call :COPY  %bindir%\Data\Users_Guide_Example.in %DISTDIR%\Examples\
call :COPY  %docdir%\CData_Guide\Examples\*.in   %DISTDIR%\Examples\

echo ***Copying CFAST documentation

set PDFS=%userprofile%\.cfast\PDFS
call :COPY %PDFS%\Tech_Ref.pdf            %DISTDIR%\Documents\
call :COPY %PDFS%\Users_Guide.pdf         %DISTDIR%\Documents\
call :COPY %PDFS%\Validation_Guide.pdf    %DISTDIR%\Documents\
call :COPY %PDFS%\Configuration_Guide.pdf %DISTDIR%\Documents\
call :COPY %PDFS%\CData_Guide.pdf         %DISTDIR%\Documents\

echo .
echo ***Creating smokeview executables
call build_smv_progs
cd %CURDIR2%

echo ***Copying Smokeview files

call :COPYPROG background
call :COPYPROG get_time
call :COPYPROG get_time
call :COPYPROG sh2bat
call :COPYPROG smokediff
call :COPYPROG smokeview test_
call :COPYPROG smokezip
call :COPYPROG wind2fds
call :COPY %botrepo%\Bundle\smv\for_bundle\objects.svo    %SMVDISTDIR%\
call :COPY %botrepo%\Bundle\smv\for_bundle\volrender.ssf  %SMVDISTDIR%\
call :COPY_DIR %botrepo%\Bundle\smv\for_bundle\textures   %SMVDISTDIR%\textures\

echo.
echo ***Creating installer
echo ***Copying Uninstall files

call :COPY  %bundleinfo%\uninstall.bat        %DISTDIR%\Uninstall
call :COPY  %bundleinfo%\uninstall_cfast.bat  %DISTDIR%\Uninstall\uninstall_base.bat 
call :COPY  %bundleinfo%\uninstall_cfast2.bat %DISTDIR%\Uninstall\uninstall_base2.bat 
call :COPY  %bundleinfo%\uninstall_cfast2.bat %DISTDIR%\Uninstall\uninstall_base2.bat

call :COPY  %smvrepo%\Build\set_path\intel_win_64\set_path_win_64.exe %DISTDIR%\set_path.exe
call :COPY  %botrepo%\Bundle\smv\for_bundle\Shortcut                  %DISTDIR%\Shortcut.exe

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

:COPY_DIR
set indir=%1
set outdir=%2
copy %indir% %outdir% > Nul 2>&1
exit /b

:EOF
