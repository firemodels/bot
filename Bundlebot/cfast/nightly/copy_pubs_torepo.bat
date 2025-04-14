@echo off
setlocal

set cfastbundledir=%CD%

cd ..\..\..\cfast
set cfastrepo=%CD%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

call :copy_file CFAST_Tech_Ref
call :copy_file CFAST_Users_Guide
call :copy_file CFAST_Validation_Guide
call :copy_file CFAST_Configuration_Guide
call :copy_file CFAST_CData_Guide

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set file=%1
set fromfile=%PDFS%\%file%.pdf
set tofile=%manuals%\%file%\%file%.pdf
if exist %tofile% erase %tofile%
if exist %fromfile% copy %fromfile% %tofile%  > Nul 2>&1
if not exist %fromfile% echo ***error: %fromfile% does not exist
if not exist %fromfile% exit /b 
if NOT exist %tofile% echo error***: %file%.pdf failed to copy
if exist %tofile% echo %file%.pdf copied
exit /b 1

cd %cfastbundledir%
:eof