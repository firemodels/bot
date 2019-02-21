@echo off
set bot_type=%1
set pdf_from=%2
set bot_host=%3

set pdf_to=%userprofile%\.bundle\pubs

if NOT exist %userprofile%\.bundle mkdir %userprofile%\.bundle
if NOT exist %pdf_to% mkdir %pdf_to%

if "%bot_type%" == "firebot" (
  call :copy_file FDS_Config_Management_Plan.pdf
  call :copy_file FDS_Technical_Reference_Guide.pdf
  call :copy_file FDS_User_Guide.pdf
  call :copy_file FDS_Validation_Guide.pdf
  call :copy_file FDS_Verification_Guide.pdf
)

if "%bot_type%" == "smokebot" (
  call :copy_file SMV_Technical_Reference_Guide.pdf
  call :copy_file SMV_User_Guide.pdf
  call :copy_file SMV_Verification_Guide.pdf
)

goto eof

:: -------------------------------------------------
:copy_file
:: -------------------------------------------------
set file=%1

if "x%bot_host%" == "x" goto else1
  echo copying %file% from %pdf_from% on %bot_host% to %pdf_to%
  pscp %bot_host%:%pdf_from%/%file% %pdf_to%\.
  goto endif1
:else1
  echo copying %file% from %pdf_from% to %pdf_to%
  copy %pdf_from%\%file% %pdf_to%
:endif1

exit /b

:eof
