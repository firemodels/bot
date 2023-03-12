@echo off
setlocal

set cfastbundledir=%CD%

set configfile=%userprofile%\.bundle\bundle_config.bat
if not exist %configfile% echo ***error: %userprofile%\bundle_config.bat does not exist
if not exist %configfile% exit /b
call %configfile%
call check_config || exit /b 1

set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

echo | set /p dummyName=Downloading CFAST repo hash: 
call :getfile CFAST_HASH

echo | set /p dummyName=Downloading CFAST repo revision: 
call :getfile CFAST_REVISION

echo | set /p dummyName=Downloading smv repo hash: 
call :getfile SMV_HASH

echo | set /p dummyName=Downloading smv repo revision: 
call :getfile SMV_REVISION

goto eof

::------------------------------------------
:getfile
set type=%1
if exist %PDFS%\%type% erase %PDFS%\%type%

echo gh release download %GH_CFAST_TAG% -p %type% -R github.com/%GH_OWNER%/%GH_REPO% -D %PDFS%
gh release download %GH_CFAST_TAG% -p %type% -R github.com/%GH_OWNER%/%GH_REPO% -D %PDFS%

if NOT exist %PDFS%\%type% echo failed
if exist %PDFS%\%type% echo succeeded
exit /b

:eof

cd %cfastbundledir%
