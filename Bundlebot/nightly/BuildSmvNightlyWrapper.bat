@echo off
setlocal
if "%~1"=="-h" (
  call "%~dp0BuildSmvNightly.bat" -h
  exit /b 0
)
call "%~dp0..\bundle_lock.bat" acquire || exit /b 1
call :run_bundle %*
set "BUNDLE_BUILD_RESULT=%ERRORLEVEL%"
if defined BUNDLE_LOCK_OWNED call "%~dp0..\bundle_lock.bat" release
exit /b %BUNDLE_BUILD_RESULT%

:run_bundle

set outfile=%userprofile%\.bundle\bundle_smv_nightly.out

set CURDIRW=%CD%

echo.                                                        >  %outfile% 2>&1
echo ------------------------------------------------------  >> %outfile% 2>&1
echo ------------------------------------------------------  >> %outfile% 2>&1
echo Updating bot repo                                       >> %outfile% 2>&1
cd ..\..\Scripts
call update_repos -b -m > Nul 2>&1

cd %CURDIRW%
call BuildSmvNightly %*                                      >> %outfile% 2>&1
set "BUNDLE_WRAPPED_RESULT=%ERRORLEVEL%"
cd %CURDIRW%
exit /b %BUNDLE_WRAPPED_RESULT%
