@echo off
call config.bat
if "X%BUNDLE_BOT_TAG%" == "X" exit /b
git tag -f -a %BUNDLE_BOT_TAG% -m "tag bundle version %BUNDLE_BOT_TAG"
