@echo off
:: platform is windows, linux or osx
set platform=%1

:: build type is test or release
set buildtype=%2

set SCRIPTDIR=%~dp0
cd %SCRIPTDIR%
call webPACKAGEsmv %platform% %buildtype% nopause
cd %SCRIPTDIR%
call webINSTALLsmv %platform% %buildtype% nopause