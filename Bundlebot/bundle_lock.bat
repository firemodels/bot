@echo off
if "%~1"=="release" (
  rmdir "%BUNDLE_BUILD_LOCK%" || exit /b 1
  exit /b 0
)
set "BUNDLE_LOCK_OWNED="
set "BUNDLE_LOCK_PATH=%USERPROFILE%\.bundle\bundle_build.lock"
if /i "%BUNDLE_BUILD_LOCK%"=="%BUNDLE_LOCK_PATH%" if exist "%BUNDLE_LOCK_PATH%\" exit /b 0
if not exist "%USERPROFILE%\.bundle\" mkdir "%USERPROFILE%\.bundle" 2>nul
mkdir "%BUNDLE_LOCK_PATH%" 2>nul
if errorlevel 1 (
  if exist "%BUNDLE_LOCK_PATH%\" (
    echo Another bundle build holds "%BUNDLE_LOCK_PATH%". 1>&2
  ) else (
    echo Unable to acquire bundle lock "%BUNDLE_LOCK_PATH%". 1>&2
  )
  exit /b 1
)
set "BUNDLE_BUILD_LOCK=%BUNDLE_LOCK_PATH%"
set "BUNDLE_LOCK_OWNED=1"
exit /b 0
