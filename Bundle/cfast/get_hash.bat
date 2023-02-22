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
if x%bundle_smokebot_home% == x echo ***error: bundle_smokebot_home variable is not defined
if x%bundle_smokebot_home% == x set error=1
if %error% == 1 exit /b

set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

echo | set /p dummyName=Downloading CFAST repo hash: 
call :gethash CFAST_HASH

echo | set /p dummyName=Downloading smv repo hash: 
call :gethash SMV_HASH
goto eof

::------------------------------------------
:gethash
::------------------------------------------
set type=%1
if exist %PDFS%\%type% erase %PDFS%\%type%
pscp -P 22 %bundle_hostname%:%bundle_cfastbot_home%/.cfastbot/Manuals/%type% %PDFS%\%type%  > Nul 2>&1
if NOT exist %PDFS%\%type% echo failed
if exist %PDFS%\%type% echo succeeded
exit /b

:eof

cd %cfastbundledir%
