@echo off
set error=0
set bot_type=%1
set ghowner=%2

if "x%ghowner%" == "x" set ghowner=firemodels

set pdf_to_dir=%userprofile%\.bundle\pubs

if NOT exist %userprofile%\.bundle mkdir %userprofile%\.bundle
if NOT exist %pdf_to_dir% mkdir %pdf_to_dir%

echo.
echo   To directory: %pdf_to_dir%

if "%bot_type%" == "firebot" (
  call :copy_file FDS_TEST FDS_Config_Management_Plan.pdf
  call :copy_file FDS_TEST FDS_Technical_Reference_Guide.pdf
  call :copy_file FDS_TEST FDS_User_Guide.pdf
  call :copy_file FDS_TEST FDS_Validation_Guide.pdf
  call :copy_file FDS_TEST FDS_Verification_Guide.pdf
)

if "%bot_type%" == "smokebot" (
  call :copy_file SMOKEVIEW_TEST SMV_Technical_Reference_Guide.pdf
  call :copy_file SMOKEVIEW_TEST SMV_User_Guide.pdf
  call :copy_file SMOKEVIEW_TEST SMV_Verification_Guide.pdf
)

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set TAG=%1
set file=%2

echo downloading %file% from github.com/%ghowner%/test_bundles tag: %TAG%
if EXIST %pdf_to_dir%\%file% erase %pdf_to_dir%\%file%
echo gh release download %TAG% -p %file% -R github.com/%ghowner%/test_bundles -D %pdf_to_dir% --clobber
gh release download %TAG% -p %file% -R github.com/%ghowner%/test_bundles -D %pdf_to_dir% --clobber
if EXIST %pdf_to_dir%\%file% exit /b
echo ***Error: %file% download failed
set error=1
exit /b

:eof

if "%error%" == "0" exit /b 0
exit /b 1