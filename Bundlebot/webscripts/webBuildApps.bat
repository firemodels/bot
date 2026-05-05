@echo off

echo %CD%
pause
if %1 == firebot  call webBuildFDS 
if %1 == smokebot call webBuildSmvApps 
