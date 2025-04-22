@echo off
setlocal

set cfastbundledir=%CD%

cd ..\..\..\..\cfast
set cfastrepo=%CD%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%
erase %PDFS%\*.pdf > Nul 2>&1

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
set tofile=%PDFS%\%file%.pdf
if exist %tofile% erase %tofile%
::echo | set /p dummyName=***downloading %file%.pdf: 

echo ***Downloading %file%.pdf from github.com/%GH_OWNER%/%GH_REPO%
gh release download %GH_CFAST_TAG% -p %file%.pdf -R github.com/%GH_OWNER%/%GH_REPO% -D %PDFS%

if NOT exist %tofile% echo    failed
if exist %tofile% echo    succeeded
exit /b 1

cd %cfastbundledir%
:eof