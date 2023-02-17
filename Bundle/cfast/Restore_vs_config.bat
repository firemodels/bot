@echo off
set FROMDIR=%1
copy %FROMDIR%\CFAST.sln             %FROMDIR%\..\..\CFAST.sln /Y
copy %FROMDIR%\CFAST.vfproj          %FROMDIR%\..\..\Source\CFAST\CFAST.vfproj /Y
copy %FROMDIR%\CEdit.vbproj          %FROMDIR%\..\..\Source\CEdit\CEdit.vbproj /Y
copy %FROMDIR%\CData.vfproj          %FROMDIR%\..\..\Source\CData\CData.vfproj /Y
copy %FROMDIR%\Create_scripts.vfproj %FROMDIR%\..\..\Source\Create_scripts\Create_scripts.vfproj /Y
copy %FROMDIR%\VandV_Calcs.vfproj    %FROMDIR%\..\..\Source\VandV_Calcs\VandV_Calcs.vfproj /Y
