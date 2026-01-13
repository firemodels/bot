@echo off
:: strip leading local path from file names
setlocal EnableDelayedExpansion
set "SEARCH=%userprofile%\.bundle\uploads\"
set INPUT=%1
FOR %%A IN (%INPUT%) DO set "OUTPUT=%%~nA.vlog"

> "%OUTPUT%" (
  for /f "usebackq delims=" %%A in ("%INPUT%") do (
    set "line=%%A"
    echo(!line:%SEARCH%=!
  )
)
