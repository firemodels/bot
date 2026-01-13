@echo off
:: strip leading local path from file names
setlocal EnableDelayedExpansion
set "SEARCH=%userprofile%\.bundle\uploads\"
set INPUT=%1
set OUTPUT=%2

> "%OUTPUT%" (
  for /f "usebackq delims=" %%A in ("%INPUT%") do (
    set "line=%%A"
    echo(!line:%SEARCH%=!
  )
)
