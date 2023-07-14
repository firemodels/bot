@echo off
:: platform is windows, linux or osx
set platform=%1

:: build type is test or release
set buildtype=%2

set SSCRIPTDIR=%~dp0
cd %SSCRIPTDIR%
call webPACKAGEsmv %platform% %buildtype% nopause
cd %SSCRIPTDIR%
call webINSTALLsmv %platform% %buildtype% nopause