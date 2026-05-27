@echo off

set CURDIR=%CD%
set certfile=%userprofile%\certificates\FDS_TEMP.pfx
cd bundles

dir *.exe
for %%f in (*.exe) do (
  echo.
  echo signing %%f
  signtool sign /f %certfile% /p %CERT_PASSWORD% /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 %%f 
  echo.
  echo verifying signature
  signtool verify /pa /v %%f
)

cd %CURDIR%
