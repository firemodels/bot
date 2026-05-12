@echo off 

cd ..\..\smv\Verification\scripts
if %1 == firebot  call CheckFDSCases 
if %1 == smokebot call CheckSmvCases 
