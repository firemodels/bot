@echo off
setlocal
if "%~1"=="-h" (
  call "%~dp0BuildNightly.bat" -h
  exit /b 0
)
call "%~dp0..\bundle_lock.bat" acquire || exit /b 1
call :run_bundle %*
set "BUNDLE_BUILD_RESULT=%ERRORLEVEL%"
if defined BUNDLE_LOCK_OWNED call "%~dp0..\bundle_lock.bat" release
exit /b %BUNDLE_BUILD_RESULT%

:run_bundle
set outfile=%userprofile%\.bundle\bundle_fdssmv_nightly.out

:: the windows task scheduler which builds bundles every day call this script to make sure 
:: the bot repo (ie the BuildNightly.bat script) is up to date.  A wrapper script is necessary
:: because a script CANNOT be updated while it is running but in this case CAN be updated
:: before it is run

set CURDIRW=%CD%
echo.                                                        >  %outfile% 2>&1
echo ------------------------------------------------------  >> %outfile% 2>&1
echo ------------------------------------------------------  >> %outfile% 2>&1
echo Updating bot repo                                       >> %outfile% 2>&1
cd ..\..\Scripts
call update_repos -b -m > Nul 2>&1

cd %CURDIRW%
call BuildNightly %*                                         >> %outfile% 2>&1
set "BUNDLE_WRAPPED_RESULT=%ERRORLEVEL%"
cd %CURDIRW%
exit /b %BUNDLE_WRAPPED_RESULT%
