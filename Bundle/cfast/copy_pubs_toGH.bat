@echo off
setlocal

set cfastbundledir=%CD%

cd ..\..\..\cfast
set cfastrepo=%CD%
cd ..\test_bundles
set testbundlerepo=%CD%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

cd %testbundlerepo%
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
set cfastfile=%file%.pdf
if exist %fromfile% copy %fromfile% %TEMP%\%cfastfile% 
if exist %fromfile% echo Uploading %cfastfile% 
if exist %fromfile% gh release upload TEST %TEMP%\%cfastfile% --clobber 
if not exist %fromfile% echo ***error: %fromfile% does not exist
if not exist %fromfile% exit /b 
exit /b 1

cd %cfastbundledir%
:eof