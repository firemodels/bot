@echo off

set SCRIPT_DIR=%~dp0
set CURDIR=%CD%

call %SCRIPT_DIR%\webBUILDsmv %1 %2 nopause

cd %CURDIR%
call %SCRIPT_DIR%\webPACKAGEsmv %1 %3

cd %CURDIR%
call %SCRIPT_DIR%\webINSTALLsmv %1  
