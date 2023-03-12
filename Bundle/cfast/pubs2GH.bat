@echo off
setlocal

set cfastbundledir=%CD%

cd ..\..\..\cfast
set cfastrepo=%CD%
cd ..\%GH_REPO%
set testbundlerepo=%CD%
gh repo set-default %GH_OWNER%/%GH_REPO%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

cd %testbundlerepo%
call :copy_file CFAST_Tech_Ref.pdf
call :copy_file CFAST_Users_Guide.pdf
call :copy_file CFAST_Validation_Guide.pdf
call :copy_file CFAST_Configuration_Guide.pdf
call :copy_file CFAST_CData_Guide.pdf
call :copy_file CFAST_HASH
call :copy_file CFAST_REVISION
call :copy_file SMV_HASH
call :copy_file SMV_REVISION

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set file=%1
set fromfile=%PDFS%\%file%
if exist %fromfile% echo Uploading %fromfile% 
if exist %fromfile% gh release upload %GH_CFAST_TAG% %fromfile% -R github.com/%GH_OWNER%/%GH_REPO% --clobber 
if not exist %fromfile% echo ***error: %fromfile% does not exist
if not exist %fromfile% exit /b 
exit /b 1

cd %cfastbundledir%
:eof
