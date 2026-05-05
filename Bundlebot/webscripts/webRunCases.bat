@echo off

if %1 == firebot  call webRunFDSCases 
if %1 == smokebot call webRunSmvCases 
