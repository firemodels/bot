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

echo Downloading cfast repo hash
if exist %PDFS%\CFASTHASH erase %PDFS%\CFASTHASH
pscp -P 22 %bundle_hostname%:%bundle_cfastbot_home%/.cfastbot/Manuals/HASH %PDFS%\CFASTHASH  > Nul 2>&1
if NOT exist %PDFS%\CFASTHASH echo failed
if exist %PDFS%\CFASTHASH echo succeeded

echo Downloading smv repo hash
if exist %PDFS%\SMVHASH erase %PDFS%\SMVHASH
pscp -P 22 %bundle_hostname%:%bundle_smokebot_home%/.smokebot/apps/SMV_HASH %PDFS%\SMV_HASH  > Nul 2>&1
if NOT exist %PDFS%\SMV_HASH echo failed
if exist %PDFS%\SMV_HASH echo succeeded
exit /b 1

cd %cfastbundledir%
