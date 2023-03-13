@echo off
set error=0
set bot_type=%1

set pdf_to_dir=%userprofile%\.bundle\pubs

if NOT exist %userprofile%\.bundle mkdir %userprofile%\.bundle
if NOT exist %pdf_to_dir% mkdir %pdf_to_dir%

echo.
echo   To directory: %pdf_to_dir%

if "%bot_type%" == "firebot" (
  set GH_TAG=%GH_FDS_TAG%
  call :copy_file FDS_Config_Management_Plan.pdf
  call :copy_file FDS_Technical_Reference_Guide.pdf
  call :copy_file FDS_User_Guide.pdf
  call :copy_file FDS_Validation_Guide.pdf
  call :copy_file FDS_Verification_Guide.pdf
)

if "%bot_type%" == "smokebot" (
  set GH_TAG=%GH_SMOKEVIEW_TAG%
  call :copy_file SMV_Technical_Reference_Guide.pdf
  call :copy_file SMV_User_Guide.pdf
  call :copy_file SMV_Verification_Guide.pdf
)

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set file=%1

echo downloading %file% from github.com/%GH_OWNER%/%GH_REPO% tag: %GH_TAG%
if EXIST %pdf_to_dir%\%file% erase %pdf_to_dir%\%file%
gh release download %GH_TAG% -p %file% -R github.com/%GH_OWNER%/%GH_REPO% -D %pdf_to_dir% --clobber
if EXIST %pdf_to_dir%\%file% exit /b
echo ***Error: %file% download failed
set error=1
exit /b

:eof

if "%error%" == "0" exit /b 0
exit /b 1