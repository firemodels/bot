@echo off
setlocal

set cfastbundledir=%CD%

cd ..\..\..\cfast
set cfastrepo=%CD%
set manuals=%cfastrepo%\Manuals
set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

call :copy_file CFAST_Tech_Ref.pdf
call :copy_file CFAST_Users_Guide.pdf
call :copy_file CFAST_Validation_Guide.pdf
call :copy_file CFAST_Configuration_Guide.pdf
call :copy_file CFAST_CData_Guide.pdf
set /p CFAST_HASH=<%PDFS%\CFAST_HASH
set /p CFAST_REVISION=<%PDFS%\CFAST_REVISION
set /p SMV_HASH=<%PDFS%\SMV_HASH
set /p SMV_REVISION=<%PDFS%\SMV_REVISION
echo CFAST_HASH %CFAST_HASH%          > %PDFS%\CFAST_INFO.txt
echo CFAST_REVISION %CFAST_REVISION% >> %PDFS%\CFAST_INFO.txt
echo SMV_HASH %SMV_HASH%             >> %PDFS%\CFAST_INFO.txt
echo SMV_REVISION %SMV_REVISION%     >> %PDFS%\CFAST_INFO.txt

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
