@echo off

cd webscripts
if %1 == firebot  call webBuildFDS 
if %1 == smokebot call webBuildSmvApps
