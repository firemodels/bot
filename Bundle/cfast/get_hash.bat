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

set PDFS=%userprofile%\.cfast\PDFS

if NOT exist %userprofile%\.cfast mkdir %userprofile%\.cfast
if NOT exist %PDFS% mkdir %PDFS%

set hosthome=%bundle_cfastbot_home%/.cfastbot/Manuals
set hashfile=%userprofile%\.cfast\HASH
echo Downloading cfast repo hash from %hosthome% on %bundle_hostname%

if exist %PDFS%\HASH erase %PDFS%\HASH
pscp -P 22 %bundle_hostname%:%hosthome%/HASH %PDFS%\HASH  > Nul 2>&1
if NOT exist %PDFS%\HASH echo failed
if exist %PDFS%\HASH echo succeeded
exit /b 1

cd %cfastbundledir%
:eof