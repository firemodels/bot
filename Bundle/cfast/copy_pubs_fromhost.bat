@echo off
setlocal

set cfastbundledir=%CD%

set configfile=%userprofile%\.bundle\bundle_config.bat

if not exist %configfile% echo ***error: %userprofile%\bundle_config.bat does not exist
if not exist %configfile% exit /b

call %configfile%
set error=0
if x%bundle_hostname% == x echo ***error: bundle_hostname variable is not defined
if x%bundle_hostname% == x set error=1
if x%bundle_cfastbot_home% == x echo ***error: bundle_cfastbot_home variable is not defined
if x%bundle_cfastbot_home% == x set error=1
if %error% == 1 exit /b

cd ..\..\..\cfast
set cfastrepo=%CD%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%
erase %PDFS%\*.pdf > Nul 2>&1

set hosthome=%bundle_cfastbot_home%/.cfastbot/Manuals
echo Downloading CFAST PDFs from %hosthome% on %bundle_hostname%

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
set tofile=%PDFS%\%file%.pdf
if exist %tofile% erase %tofile%
echo | set /p dummyName=***downloading %file%.pdf: 
pscp -P 22 %bundle_hostname%:%hosthome%/%file%/%file%.pdf %tofile%  > Nul 2>&1
if NOT exist %tofile% echo failed
if exist %tofile% echo succeeded
exit /b 1

cd %cfastbundledir%
:eof