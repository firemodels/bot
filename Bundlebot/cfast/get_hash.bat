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

echo | set /p dummyName=Downloading CFAST_INFO.txt: 
call :getfile CFAST_INFO.txt

grep CFAST_HASH     %PDFS%\CFAST_INFO.txt | gawk "{print $2}" > %PDFS%\CFAST_HASH
grep CFAST_REVISION %PDFS%\CFAST_INFO.txt | gawk "{print $2}" > %PDFS%\CFAST_REVISION
grep SMV_HASH       %PDFS%\CFAST_INFO.txt | gawk "{print $2}" > %PDFS%\SMV_HASH
grep SMV_REVISION   %PDFS%\CFAST_INFO.txt | gawk "{print $2}" > %PDFS%\SMV_REVISION

goto eof

::------------------------------------------
:getfile
set file=%1
if exist %PDFS%\%file% erase %PDFS%\%file%

gh release download %GH_CFAST_TAG% -p %file% -R github.com/%GH_OWNER%/%GH_REPO% -D %PDFS%

if NOT exist %PDFS%\%file% echo failed
if exist %PDFS%\%file% echo succeeded
exit /b

:eof

cd %cfastbundledir%
