@echo off

set bindir=%cfast_root%\Utilities\for_bundle\Bin
set vandvdir=%cfast_root%\Build\VandV_Calcs\intel_win_64
set docdir=%cfast_root%\Manuals
set CURDIR2=%CD%

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

echo ***Copying executables

call :COPY  %bindir%\CData.exe %DISTDIR%\
call :COPY  %bindir%\CEdit.exe %DISTDIR%\
call :COPY  %bindir%\CFAST.exe %DISTDIR%\
call :COPY  %vandvdir%\VandV_Calcs_win_64.exe %DISTDIR%\VandV_Calcs.exe
call :COPY  %bindir%\background.exe %DISTDIR%\

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

call :COPY %docdir%\Tech_Ref\Tech_Ref.pdf                       %DISTDIR%\Documents\
call :COPY %docdir%\Users_Guide\Users_Guide.pdf                 %DISTDIR%\Documents\
call :COPY %docdir%\Validation_Guide\Validation_Guide.pdf       %DISTDIR%\Documents\
call :COPY %docdir%\Configuration_Guide\Configuration_Guide.pdf %DISTDIR%\Documents\
call :COPY %docdir%\CData_Guide\CData_Guide.pdf                 %DISTDIR%\Documents\

echo ***Copying Smokeview files

call :COPY %bindir%\..\SMV6\background.exe			%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\get_time.exe			%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\sh2bat.exe				%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\smokediff.exe			%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\smokeview.exe			%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\smokezip.exe			%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\wind2fds.exe			%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\objects.svo				%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\textures				%SMVDISTDIR%\
call :COPY %bindir%\..\SMV6\volrender.ssf			%SMVDISTDIR%\
call :COPY_DIR %bindir%\..\SMV6\textures            %SMVDISTDIR%\textures\

echo ***Copying Uninstall files

call :COPY  %bundleinfo%\uninstall.bat        %DISTDIR%\Uninstall
call :COPY  %bundleinfo%\uninstall_cfast.bat  %DISTDIR%\Uninstall\uninstall_base.bat 
call :COPY  %bundleinfo%\uninstall_cfast2.bat %DISTDIR%\Uninstall\uninstall_base2.bat 
call :COPY  %bundleinfo%\uninstall_cfast2.bat %DISTDIR%\Uninstall\uninstall_base2.bat

call :COPY  %bindir%\set_path.exe %DISTDIR%\set_path.exe
call :COPY  %bindir%\Shortcut.exe %DISTDIR%\Shortcut.exe

cd %CURDIR%

GOTO EOF

:COPY
set infile=%1
set outfile=%2
IF EXIST %infile%       copy %infile% %outfile% > Nul 2>&1
IF NOT EXIST %infile%   echo ***Warning: %infile% does not exist
)
exit /b

:COPY_DIR
set indir=%1
set outdir=%2
copy %indir% %outdir% > Nul 2>&1
exit /b

:EOF
