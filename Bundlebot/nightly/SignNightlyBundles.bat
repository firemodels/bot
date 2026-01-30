@echo off
set PROGRAM=%1

if NOT exist %PROGRAM% (
  echo ***error: %PROGRAM% does not exist
  exit /b
)
if /I "%~x1" NEQ ".exe" (
    echo *** error: %PROGRAM% is not an .exe file
    exit /b
)

echo signing %PROGRAM%
signtool sign /a /n "Test Code Signing" /fd SHA256 %PROGRAM%
echo verifying signature
signtool verify /pa /v %PROGRAM%

