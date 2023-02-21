@echo off
set FROMDIR=%1
set NPLOTDIR=%2
set outfile=%3
echo. > %outfile%
call :copy_file %FROMDIR% CFAST.sln             %FROMDIR%\..\..
call :copy_file %FROMDIR% CFAST.vfproj          %FROMDIR%\..\..\Source\CFAST
call :copy_file %FROMDIR% CEdit.vbproj          %FROMDIR%\..\..\Source\CEdit
call :copy_file %FROMDIR% CData.vfproj          %FROMDIR%\..\..\Source\CData
call :copy_file %FROMDIR% Create_scripts.vfproj %FROMDIR%\..\..\Source\Create_scripts
call :copy_file %FROMDIR% VandV_Calcs.vfproj    %FROMDIR%\..\..\Source\VandV_Calcs
call :copy_file %NPLOTDIR%\for_bundle NPlot.sln %NPLOTDIR%\..\..\..\nplot

goto eof
:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set fromdir=%1
set fromfile=%2
set todir=%3
set tofile=%fromfile%

copy %fromdir%\%fromfile% %todir%\%tofile% /Y  > Nul 2>&1
if EXIST %todir%\%tofile%     echo ***%fromfile% copy successful    >> %outfile%
if NOT EXIST %todir%\%tofile% echo ***error: %fromfile% copy failed >> %outfile%
exit /b

:eof
