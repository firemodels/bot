@echo off
setlocal
set bot_host=%1

set cfastbundledir=%CD%


cd ..\..\..\cfast
set cfastrepo=%CD%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%
erase %PDFS%\*.pdf   > Nul 2>&1


set hosthome=/home2/smokevis2/cfast/FireModels_central/cfast/Manuals

call :copy_file Tech_Ref
call :copy_file Users_Guide
call :copy_file Validation_Guide
call :copy_file Configuration_Guide
call :copy_file CData_Guide

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set file=%1
set fullfile=%PDFS%\%file%.pdf
echo | set /p dummyName=***downloading %file%.pdf: 
pscp -P 22 %bot_host%:%hosthome%/%file%/%file%.pdf %fullfile%  > Nul 2>&1
if NOT exist %fullfile% echo failed
if exist %fullfile% echo succeeded
exit /b 1

cd %cfastbundledir%
:eof